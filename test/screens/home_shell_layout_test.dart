import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/screens/home_shell.dart';

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
}
