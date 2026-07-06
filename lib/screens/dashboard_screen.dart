import 'package:flutter/material.dart';

import '../models/diagnostic_data.dart';
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
  });

  final DiagnosticData data;

  /// Uptime courant. Calculé et incrémenté par un timer unique dans
  /// HomeShell (voir A1) : le reconstruire ici le ferait repartir de zéro à
  /// chaque changement d'onglet.
  final Duration uptime;

  /// En portrait le footer est dans le corps ; en paysage le shell l'affiche
  /// en barre commune et passe `false` pour éviter le doublon.
  final bool embedFooter;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _cpuSelected = false;

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
              usedFraction: d.disk.usedFraction,
              freeLabel: '${_fr(d.disk.freeGb)} GB',
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _emphasis('${_fr(d.disk.usedGb)} GB', ' sur'),
                  const SizedBox(height: 4),
                  _emphasis('${_fr(d.disk.totalGb)} GB', ' utilisés'),
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
            _cpuSelected ? _cpuContent(d.cpu) : _memoryContent(d.memory),
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
              _stat('Utilisable (compressée)', m.usable),
              _stat('Disponible', m.available),
              _stat('Validée', m.committed),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stat('Mise en cache', m.cached),
              _stat('Réserve Paginée', m.pagedPool),
              _stat('Pool non paginé', m.nonPagedPool),
            ],
          ),
          const SizedBox(height: 20),
          _kv('Vitesse', m.speed),
          _kv('Emplacements utilisés', m.slots),
          _kv('Facteur de forme', m.formFactor),
          _kv('Matériel réservé', m.reserved),
        ],
      );

  Widget _cpuContent(CpuInfo c) => Column(
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
              _stat('Vitesse', c.speed),
              _stat('Processus', c.processes),
              _stat('Threads', c.threads),
              _stat('Handles', c.handles),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Durée de fonctionnement',
            style: TextStyle(fontSize: 13, color: DiagColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            c.upTime,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222428),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kvCompact('Vitesse de base', c.baseSpeed),
                    _kvCompact('Sockets', c.sockets),
                    _kvCompact('Coeurs', c.cores),
                    _kvCompact('Processeurs logiques', c.logicalProcessors),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kvCompact('Virtualisation', c.virtualization),
                    _kvCompact('Cache de niveau 1', c.l1),
                    _kvCompact('Cache de niveau 2', c.l2),
                    _kvCompact('Cache de niveau 3', c.l3),
                  ],
                ),
              ),
            ],
          ),
        ],
      );

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

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              '$label :',
              style: const TextStyle(fontSize: 15, color: Color(0xFF222428)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, color: Color(0xFF222428)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kvCompact(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Flexible(
            child: Text(
              '$label :',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Color(0xFF222428)),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222428),
            ),
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
