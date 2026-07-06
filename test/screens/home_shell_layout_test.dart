import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/screens/home_shell.dart';
import 'package:kioskdiag/widgets/section_card.dart';

void main() {
  // initialQuarterTurns: 0 rend les tests insensibles à KIOSKDIAG_ROTATION
  // posée sur la machine de dev/CI (B2).
  testWidgets('dalle portrait + rotation par défaut → NavigationBar (portrait)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: HomeShell(initialQuarterTurns: 0)),
    );
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('après une rotation (quart impair) → NavigationRail (paysage)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: HomeShell(initialQuarterTurns: 0)),
    );
    // Le bouton rotation du header : onTap => _quarterTurns passe de 0 à 1
    // (impair, 90°, dimensions échangées) → le shell voit 1024x600 → paysage.
    await tester.tap(find.byIcon(Icons.swap_vert), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    // Le pied partagé n'apparaît qu'une fois en paysage.
    expect(find.bySemanticsLabel('FLUXIA'), findsOneWidget);
  });

  testWidgets(
      'Dashboard en 2 colonnes dans le shell paysage réel (dalle 1024)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: HomeShell(initialQuarterTurns: 0)),
    );
    await tester.tap(find.byIcon(Icons.swap_vert), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);

    // quarterTurns=1 = rotation de 90° : les axes sont transposés en
    // coordonnées globales. Deux cartes côte à côte en local se retrouvent
    // avec le même x global et des y différents une fois pivotées.
    final uptime = tester.getTopLeft(find.byType(SectionCard).at(0));
    final perf = tester.getTopLeft(find.byType(SectionCard).at(2));
    expect((perf.dx - uptime.dx).abs(), lessThan(50));
    expect((perf.dy - uptime.dy).abs(), greaterThan(100));
  });

  testWidgets('B1: bouton Quitter appelle onQuit (spy), jamais exit(0) en test',
      (tester) async {
    var quitCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          onQuit: () => quitCalls++,
          initialQuarterTurns: 0,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Quitter'));
    await tester.pump();
    expect(quitCalls, 1);
  });

  testWidgets(
      "A1: uptime ne se réinitialise pas en changeant d'onglet",
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: HomeShell(initialQuarterTurns: 0)),
    );

    // Mock : 22 secondes au départ. +3 s (pas de retenue de minute) → 25.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('25'), findsOneWidget);

    await tester.tap(find.text('Lecteurs'));
    await tester.pump();
    await tester.tap(find.text('Dashboard'));
    await tester.pump();

    expect(find.text('22'), findsNothing);
    expect(find.text('25'), findsOneWidget);
  });
}
