import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/screens/home_shell.dart';
import 'package:kioskdiag/widgets/section_card.dart';

void main() {
  // _quarterTurns démarre à 1 (impair) : RotatedBox échange les dimensions, donc
  // une surface paysage 1024x600 est vue en portrait par le shell → NavigationBar.
  testWidgets('surface paysage + rotation par défaut → NavigationBar (portrait)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('après une rotation (quart pair) → NavigationRail (paysage)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    // Le bouton rotation du header : onTap => _quarterTurns passe de 1 à 2 (pair,
    // 180°, dimensions non échangées) → le shell voit 1024x600 → paysage.
    // (Ne PAS taper "Quitter" : en test quitApp = exit(0) et tuerait le process.)
    await tester.tap(find.byIcon(Icons.swap_vert), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    // Le pied partagé n'apparaît qu'une fois en paysage.
    expect(find.textContaining('STREAML'), findsOneWidget);
  });

  testWidgets(
      'Dashboard en 2 colonnes dans le shell paysage réel (dalle 1024)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    // _quarterTurns démarre à 1 (impair, portrait) : taper la rotation pour
    // passer à 2 (pair) → le shell voit la dalle 1024x600 en paysage, et le
    // Dashboard ne reçoit alors que ~857px (1024 - NavigationRail - divider -
    // marges SafeArea), pas les 1024px complets.
    await tester.tap(find.byIcon(Icons.swap_vert), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);

    // quarterTurns=2 = rotation de 180° : RotatedBox pivote la peinture/le hit-test
    // sans changer l'ordre de layout logique, donc en coordonnées globales la
    // colonne "gauche" du code (uptime) apparaît à droite, et la colonne "droite"
    // (perf) apparaît à gauche. Ce qui compte pour prouver les 2 colonnes : même
    // ligne (dy égal) et dx différents (côte à côte, pas empilés).
    final uptime = tester.getTopLeft(find.byType(SectionCard).at(0));
    final perf = tester.getTopLeft(find.byType(SectionCard).at(2));
    expect(perf.dx, lessThan(uptime.dx)); // perf à gauche (flip 180°) → 2 colonnes DANS le shell réel
    expect(perf.dy, closeTo(uptime.dy, 1));
  });
}
