import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/screens/connectivite_screen.dart';

void main() {
  testWidgets(
    'A3: IP invalide au enregistrement → erreur affichée, pas de succès',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ConnectiviteScreen())),
      );

      // Champ "Adresse IP" du tourniquet : premier TextField de l'écran.
      await tester.tap(find.byType(TextField).at(0));
      await tester.pump();
      for (var i = 0; i < 14; i++) {
        await tester.tap(find.byIcon(Icons.backspace_outlined));
        await tester.pump();
      }
      for (final k in ['1', '.', '2', '.', '3']) {
        await tester.tap(find.text(k));
        await tester.pump();
      }

      // Fermer le clavier avant de tapper sur le bouton save
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down), warnIfMissed: false);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.save));
      await tester.pump();

      expect(find.text('Adresse IPv4 invalide'), findsOneWidget);
      expect(find.text('Configuration réseau enregistrée.'), findsNothing);
    },
  );

  testWidgets(
    'A3: sauvegarde réussie quand tous les champs actifs sont valides',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ConnectiviteScreen())),
      );

      await tester.tap(find.byIcon(Icons.save));
      await tester.pump();

      expect(find.text('Adresse IPv4 invalide'), findsNothing);
      expect(find.text('Configuration réseau enregistrée.'), findsOneWidget);
    },
  );
}
