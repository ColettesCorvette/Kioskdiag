import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/screens/home_shell.dart';
import 'package:kioskdiag/widgets/section_card.dart';

void main() {
  // _quarterTurns démarre à 0 (pair) : RotatedBox n'échange pas les dimensions,
  // donc une dalle portrait 600x1024 (raw, réelle sur la borne) est vue telle
  // quelle par le shell → NavigationBar.
  testWidgets('dalle portrait + rotation par défaut → NavigationBar (portrait)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('après une rotation (quart impair) → NavigationRail (paysage)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    // Le bouton rotation du header : onTap => _quarterTurns passe de 0 à 1
    // (impair, 90°, dimensions échangées) → le shell voit 1024x600 → paysage.
    // (Ne PAS taper "Quitter" : en test quitApp = exit(0) et tuerait le process.)
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
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    // _quarterTurns démarre à 0 (pair, portrait) : taper la rotation pour
    // passer à 1 (impair) → le shell voit la dalle en 1024x600 paysage, et le
    // Dashboard ne reçoit alors que ~857px (1024 - NavigationRail - divider -
    // marges SafeArea), pas les 1024px complets.
    await tester.tap(find.byIcon(Icons.swap_vert), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);

    // quarterTurns=1 = rotation de 90° : les axes sont transposés en
    // coordonnées globales (contrairement à 180°, un simple flip). Deux
    // cartes côte à côte en local (même y, x différents) se retrouvent donc
    // avec le même x global et des y différents une fois pivotées.
    final uptime = tester.getTopLeft(find.byType(SectionCard).at(0));
    final perf = tester.getTopLeft(find.byType(SectionCard).at(2));
    expect((perf.dx - uptime.dx).abs(), lessThan(50));
    expect((perf.dy - uptime.dy).abs(), greaterThan(100));
  });
}
