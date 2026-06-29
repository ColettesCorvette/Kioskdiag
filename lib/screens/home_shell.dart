import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/diagnostic_data.dart';
import '../theme.dart';
import '../util/quit.dart';
import '../widgets/diag_header.dart';
import 'connectivite_screen.dart';
import 'dashboard_screen.dart';
import 'lecteurs_screen.dart';
import 'tests_screen.dart';

/// Écran principal en-tête, contenu de l'onglet courant, barre de navigation.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final DiagnosticData _data = DiagnosticData.mock();
  int _index = 0;
  // Portrait par défaut : la dalle 1024x600 est montée en portrait sur la borne.
  // La rotation se fait dans l'appli (RotatedBox) car le transform output de
  // weston fait crasher l'embedder eLinux. Bouton double-flèche = ajustement.
  int _quarterTurns = 1; // rotation de l'écran, par quart de tour

  @override
  Widget build(BuildContext context) {
    Widget shell = Scaffold(
      backgroundColor: DiagColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                DiagHeader(
                  title: _data.title,
                  subtitle: _data.subtitle,
                  onToggleOrientation: () => setState(
                    () => _quarterTurns = (_quarterTurns + 1) % 4,
                  ),
                  onResetOrientation: () => setState(() => _quarterTurns = 1),
                  onQuit: quitApp,
                ),
                Expanded(child: _body()),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
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
          NavigationDestination(
            icon: Icon(Icons.wifi),
            label: 'Connectivité',
          ),
        ],
      ),
    );

    // Sur la carte plein écran, juste pivoté.
    if (!kIsWeb) {
      return RotatedBox(quarterTurns: _quarterTurns, child: shell);
    }

    // En preview web on simule la dalle portrait 600×1024 pivotée et mise à
    // l'échelle pour tenir dans la fenêtre.
    return ColoredBox(
      color: const Color(0xFFDADCE0),
      child: Center(
        child: FittedBox(
          child: RotatedBox(
            quarterTurns: _quarterTurns,
            child: SizedBox(width: 600, height: 1024, child: shell),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_index) {
      case 0:
        return DashboardScreen(data: _data);
      case 1:
        return LecteursScreen();
      case 2:
        return const TestsScreen();
      default:
        return const ConnectiviteScreen();
    }
  }
}
