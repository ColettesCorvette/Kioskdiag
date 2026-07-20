import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/diagnostic_data.dart';
import '../services/system_metrics.dart';
import '../services/turnstile_control.dart';
import '../theme.dart';
import '../util/quit.dart';
import '../widgets/app_footer.dart';
import '../widgets/diag_header.dart';
import '../widgets/inactivity_timeout.dart';
import '../widgets/wave_background.dart';
import '../util/rotation_env.dart';
import 'connectivite_screen.dart';
import 'dashboard_screen.dart';
import 'lecteurs_screen.dart';
import 'tests_screen.dart';

const _panelEnvRaw =
    String.fromEnvironment('KIOSKDIAG_PANEL', defaultValue: '600x1024');

/// Parse "LARGEURxHAUTEUR" (ex. "1280x800"). Retombe sur 600×1024 si le
/// format est invalide — jamais d'exception pour une valeur de dev mal
/// formée.
Size _parsePanelEnv(String raw) {
  final parts = raw.split('x');
  if (parts.length != 2) return const Size(600, 1024);
  final w = double.tryParse(parts[0]);
  final h = double.tryParse(parts[1]);
  if (w == null || h == null || w <= 0 || h <= 0) return const Size(600, 1024);
  return Size(w, h);
}

/// Écran principal en-tête, contenu de l'onglet courant, barre de navigation.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.onQuit = quitApp, this.initialQuarterTurns});

  /// Ferme l'appli. Par défaut `quitApp` (exit(0) sur la borne, no-op web) ;
  /// les tests injectent un spy pour ne jamais risquer un exit(0) réel.
  final VoidCallback onQuit;

  /// Rotation initiale, par défaut `quarterTurnsFromEnv() ?? 0`. Les tests
  /// passent `0` explicitement pour rester insensibles à KIOSKDIAG_ROTATION
  /// posée sur la machine de dev/CI.
  final int? initialQuarterTurns;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final DiagnosticData _data = DiagnosticData.mock();
  int _index = 0;
  // Rotation par quart de tour, appliquée dans l'appli (RotatedBox) car le
  // transform output de weston fait crasher l'embedder eLinux. Défaut
  // portrait (0), ajustable par borne via KIOSKDIAG_ROTATION (Puppet) pour
  // les tourniquets montés dans l'autre sens — voir util/rotation_env.dart.
  // Bouton double-flèche = ajustement manuel, appui long = retour au défaut.
  late final int _defaultQuarterTurns =
      widget.initialQuarterTurns ?? (quarterTurnsFromEnv() ?? 0);
  late int _quarterTurns = _defaultQuarterTurns;
  late Duration _uptime = readUptime();
  final TextEditingController _serverIp =
      TextEditingController(text: gatectlDefaultIp());
  late final Timer _uptimeTimer;
  late final Timer _uptimeResyncTimer;

  @override
  void initState() {
    super.initState();
    _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _uptime += const Duration(seconds: 1));
    });
    // Resynchronise sur la vraie valeur système toutes les 60 s : corrige
    // toute dérive de l'incrémentation locale (throttling, setState différé).
    _uptimeResyncTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      setState(() => _uptime = readUptime());
    });
  }

  @override
  void dispose() {
    _uptimeTimer.cancel();
    _uptimeResyncTimer.cancel();
    _serverIp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget shell = LayoutBuilder(
      builder: (context, c) {
        final landscape = c.maxWidth > c.maxHeight;
        return landscape ? _landscapeScaffold() : _portraitScaffold();
      },
    );

    shell = InactivityTimeout(
      timeout: kDiagInactivityTimeout,
      onTimeout: widget.onQuit,
      child: shell,
    );

    // Sur la carte plein écran, juste pivoté.
    if (!kIsWeb) {
      return RotatedBox(quarterTurns: _quarterTurns, child: shell);
    }

    // En preview web, on simule la dalle : portrait aux quarts pairs (défaut),
    // paysage aux quarts impairs (bouton rotation). Taille de base
    // configurable via KIOSKDIAG_PANEL (dart-define, dev uniquement) pour
    // prévisualiser d'autres tailles de dalle sans recompiler le code —
    // ex. `flutter run -d chrome --dart-define=KIOSKDIAG_PANEL=1280x800`.
    // Défaut inchangé : 600×1024.
    final portrait = _quarterTurns.isEven;
    final basePanel = _parsePanelEnv(_panelEnvRaw);
    final panel = portrait ? basePanel : Size(basePanel.height, basePanel.width);
    return ColoredBox(
      color: const Color(0xFFDADCE0),
      child: Center(
        child: FittedBox(
          child: RotatedBox(
            quarterTurns: _quarterTurns,
            child: SizedBox(width: panel.width, height: panel.height, child: shell),
          ),
        ),
      ),
    );
  }

  DiagHeader _header() => DiagHeader(
        title: _data.title,
        subtitle: _data.subtitle,
        onToggleOrientation: () =>
            setState(() => _quarterTurns = (_quarterTurns + 1) % 4),
        onResetOrientation: () =>
            setState(() => _quarterTurns = _defaultQuarterTurns),
        onQuit: widget.onQuit,
      );

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.sd_storage_outlined),
      selectedIcon: Icon(Icons.sd_storage),
      label: 'Lecteurs',
    ),
    NavigationDestination(
      icon: Icon(Icons.check_box_outlined),
      selectedIcon: Icon(Icons.check_box),
      label: 'Tests',
    ),
    NavigationDestination(icon: Icon(Icons.wifi), label: 'Connectivité'),
  ];

  Widget _portraitScaffold() {
    return Scaffold(
      backgroundColor: DiagColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                _header(),
                Expanded(child: _body(embedFooter: true)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }

  Widget _landscapeScaffold() {
    return Scaffold(
      backgroundColor: DiagColors.background,
      body: SafeArea(
        bottom: false,
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              groupAlignment: 0.0,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon ?? d.icon,
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(child: WaveBackground()),
                  Column(
                    children: [
                      _header(),
                      Expanded(child: _body(embedFooter: false)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: AppFooter(data: _data),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body({required bool embedFooter}) {
    return IndexedStack(
      index: _index,
      children: [
        DashboardScreen(
          data: _data,
          uptime: _uptime,
          embedFooter: embedFooter,
        ),
        LecteursScreen(serverIp: _serverIp),
        TestsScreen(serverIp: _serverIp),
        ConnectiviteScreen(serverIp: _serverIp),
      ],
    );
  }
}
