import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/diagnostic_data.dart';
import '../services/system_metrics.dart';
import '../theme.dart';
import '../widgets/app_footer.dart';
import '../widgets/disk_ring.dart';
import '../widgets/perf_graph.dart';
import '../widgets/perf_toggle.dart';
import '../widgets/section_card.dart';
import '../widgets/uptime_pills.dart';

/// Onglet Dashboard uptime, espace disque, carte perf mémoire/processeur,
/// pied de page.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.data,
    required this.uptime,
    this.embedFooter = true,
    this.diskReader,
  });

  final DiagnosticData data;

  /// Uptime courant. Calculé et incrémenté par un timer unique dans
  /// HomeShell (voir A1) : le reconstruire ici le ferait repartir de zéro à
  /// chaque changement d'onglet.
  final Duration uptime;

  /// En portrait le footer est dans le corps ; en paysage le shell l'affiche
  /// en barre commune et passe `false` pour éviter le doublon.
  final bool embedFooter;

  /// Lecture de l'espace disque. Par défaut `readDisk` (service système) ;
  /// les tests injectent un faux lecteur pour vérifier le rafraîchissement
  /// périodique sans dépendre de `df`/`/data` réels.
  final DiskInfo Function()? diskReader;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _cpuSelected = false;
  late final DiskInfo Function() _diskReader = widget.diskReader ?? readDisk;
  late DiskInfo _disk = widget.data.disk;
  Timer? _diskTimer;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _disk = _diskReader();
      _diskTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => setState(() => _disk = _diskReader()),
      );
    }
  }

  @override
  void dispose() {
    _diskTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 800;
        if (wide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _uptimeCard(d),
                        const SizedBox(height: 16),
                        _diskCard(d),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _perfCard(d)),
                ],
              ),
            ),
          );
        }
        return _narrowBody(d);
      },
    );
  }

  Widget _narrowBody(DiagnosticData d) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final uptime = _uptimeCard(d);
              final disk = _diskCard(d);
              if (c.maxWidth >= 520) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: uptime),
                      const SizedBox(width: 16),
                      Expanded(child: disk),
                    ],
                  ),
                );
              }
              return Column(
                children: [uptime, const SizedBox(height: 16), disk],
              );
            },
          ),
          const SizedBox(height: 16),
          _perfCard(d),
          if (widget.embedFooter) ...[
            const SizedBox(height: 24),
            AppFooter(data: d),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _uptimeCard(DiagnosticData d) => SectionCard(
        accent: DiagColors.accentUptime,
        title: 'Tourniquet en route depuis...',
        child: UptimePills(uptime: widget.uptime),
      );

  Widget _diskCard(DiagnosticData d) => SectionCard(
        accent: DiagColors.accentDisk,
        title: 'Espace disque libre',
        child: Row(
          children: [
            DiskRing(
              usedFraction: _disk.usedFraction,
              freeLabel: '${_fr(_disk.freeGb)} GB',
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _emphasis('${_fr(_disk.usedGb)} GB', ' sur'),
                  const SizedBox(height: 4),
                  _emphasis('${_fr(_disk.totalGb)} GB', ' utilisés'),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _perfCard(DiagnosticData d) => SectionCard(
        accent: _cpuSelected ? DiagColors.accentCpu : DiagColors.accentMemory,
        title: _cpuSelected
            ? 'Utilisation du Processeur'
            : 'Utilisation de la Mémoire',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cpuSelected
                ? _cpuContent(d.cpu, widget.uptime)
                : _memoryContent(d.memory),
            const SizedBox(height: 16),
            Center(
              child: PerfToggle(
                cpuSelected: _cpuSelected,
                onChanged: (cpu) => setState(() => _cpuSelected = cpu),
              ),
            ),
          ],
        ),
      );

  Widget _memoryContent(MemoryInfo m) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PerfGraph(
            series: m.series,
            maxValue: m.maxGo,
            lineColor: DiagColors.memoryLine,
            topRightLabel: '${_fr(m.maxGo)} Go',
            bottomRightLabel: '0,0',
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stat('Disponible', m.available),
              _stat('Mise en cache', m.cached),
            ],
          ),
        ],
      );

  Widget _cpuContent(CpuInfo c, Duration uptime) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c.name,
            style: const TextStyle(fontSize: 14, color: Color(0xFF222428)),
          ),
          const SizedBox(height: 8),
          PerfGraph(
            series: c.series,
            maxValue: 100,
            lineColor: DiagColors.cpuLine,
            topRightLabel: '100 %',
            bottomRightLabel: '0',
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stat('Utilisation', c.usage),
              if (c.speed != null) _stat('Vitesse', c.speed!),
              _stat('Processus', c.processes),
              _stat('Cœurs', c.cores),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Durée de fonctionnement',
            style: TextStyle(fontSize: 13, color: DiagColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            _formatUptime(uptime),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222428),
            ),
          ),
        ],
      );

  String _formatUptime(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.inDays}:${two(d.inHours % 24)}:${two(d.inMinutes % 60)}:'
        '${two(d.inSeconds % 60)}';
  }

  // Helpers d'affichage.

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: DiagColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 17, color: Color(0xFF222428)),
          ),
        ],
      ),
    );
  }

  Widget _emphasis(String strong, String rest) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 18, color: Color(0xFF222428)),
        children: [
          TextSpan(
            text: strong,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: rest),
        ],
      ),
    );
  }

  String _fr(double v) {
    final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
    return s.replaceAll('.', ',');
  }
}
