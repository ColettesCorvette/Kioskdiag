import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/screens/connectivite_screen.dart';
import 'package:kioskdiag/widgets/onscreen_keypad.dart';

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

  testWidgets(
    'A3: DHCP + DNS invalide → erreur affichée, pas de succès',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ConnectiviteScreen())),
      );

      // Invalider le DNS en mode Statique (DNS est le 4e TextField, index 3)
      await tester.tap(find.byType(TextField).at(3));
      await tester.pump();

      // Vider le champ DNS (14 backspace pour "192.168.10.1")
      for (var i = 0; i < 14; i++) {
        await tester.tap(find.byIcon(Icons.backspace_outlined));
        await tester.pump();
      }

      // Saisir une valeur invalide "1.2.3"
      for (final k in ['1', '.', '2', '.', '3']) {
        await tester.tap(find.text(k));
        await tester.pump();
      }

      // Fermer le clavier
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down), warnIfMissed: false);
      // pumpAndSettle (et non un simple pump) : la fermeture du clavier
      // déclenche unfocus(), qui lance l'animation de disparition du
      // curseur clignotant. Avec le bandeau Ethernet (F2) qui décale
      // désormais "Mode DHCP" plus bas dans la mise en page, un seul pump()
      // laisse cette transition en cours et le tap suivant peut rater son
      // hit-test.
      await tester.pumpAndSettle();

      // Basculer en mode DHCP
      await tester.tap(find.text('Mode DHCP'));
      await tester.pump();

      // Tapper sur save
      await tester.tap(find.byIcon(Icons.save));
      await tester.pump();

      // Vérifier que l'erreur est affichée et le succès absent
      // (car le DNS est invalide, et en DHCP le DNS est toujours validé)
      expect(find.text('Adresse IPv4 invalide'), findsOneWidget);
      expect(find.text('Configuration réseau enregistrée.'), findsNothing);
    },
  );

  testWidgets(
    'A3: insertion refusée au-delà de 15 caractères',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ConnectiviteScreen())),
      );

      // Focaliser le champ IP tourniquet (index 0)
      // Valeur initiale : '192.168.10.41' = 14 caractères
      await tester.tap(find.byType(TextField).at(0));
      await tester.pump();

      // Vérifier que la valeur initiale a 14 caractères
      TextField ipField = tester.widget<TextField>(find.byType(TextField).at(0));
      expect(ipField.controller!.text.length, 14);

      // Tapper un chiffre pour atteindre 15 (accepté)
      await tester.tap(find.text('5'));
      await tester.pump();
      ipField = tester.widget<TextField>(find.byType(TextField).at(0));
      expect(ipField.controller!.text.length, 15);

      // Tapper un autre chiffre pour dépasser 15 (refusé)
      await tester.tap(find.text('5'));
      await tester.pump();
      ipField = tester.widget<TextField>(find.byType(TextField).at(0));
      // Doit rester à 15 caractères
      expect(ipField.controller!.text.length, 15);
    },
  );

  testWidgets('G: insertion au milieu du texte (curseur positionné, pas en fin)',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen())),
    );
    await tester.tap(find.byType(TextField).at(0));
    await tester.pump();

    final controller =
        tester.widget<TextField>(find.byType(TextField).at(0)).controller!;
    // Curseur collé juste après "192" dans "192.168.10.41".
    controller.selection = const TextSelection.collapsed(offset: 3);

    await tester.tap(find.text('9'));
    await tester.pump();

    expect(controller.text, '1929.168.43.241');
    expect(controller.selection, const TextSelection.collapsed(offset: 4));
  });

  testWidgets('G: taper un chiffre remplace une sélection étendue',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen())),
    );
    await tester.tap(find.byType(TextField).at(0));
    await tester.pump();

    final controller =
        tester.widget<TextField>(find.byType(TextField).at(0)).controller!;
    // Sélectionne "192" (offsets 0-3) dans "192.168.10.41".
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 3);

    await tester.tap(find.text('7'));
    await tester.pump();

    expect(controller.text, '7.168.43.241');
    expect(controller.selection, const TextSelection.collapsed(offset: 1));
  });

  testWidgets('G: backspace efface une sélection étendue', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen())),
    );
    await tester.tap(find.byType(TextField).at(0));
    await tester.pump();

    final controller =
        tester.widget<TextField>(find.byType(TextField).at(0)).controller!;
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 3);

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();

    expect(controller.text, '.168.43.241');
    expect(controller.selection, const TextSelection.collapsed(offset: 0));
  });

  testWidgets(
      'G: backspace avec le curseur en tout début de champ ne supprime rien',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen())),
    );
    await tester.tap(find.byType(TextField).at(0));
    await tester.pump();

    final controller =
        tester.widget<TextField>(find.byType(TextField).at(0)).controller!;
    controller.selection = const TextSelection.collapsed(offset: 0);

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();

    expect(controller.text, '192.168.10.41'); // inchangé
  });

  testWidgets('G: backspace sur un champ déjà vide ne fait rien (pas de crash)',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen())),
    );
    await tester.tap(find.byType(TextField).at(0));
    await tester.pump();
    for (var i = 0; i < 14; i++) {
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
    }
    final controller =
        tester.widget<TextField>(find.byType(TextField).at(0)).controller!;
    expect(controller.text, '');

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(controller.text, '');
    expect(tester.takeException(), isNull);
  });

  testWidgets('F3: bascule Statique→DHCP : DNS reste éditable, IP grisée',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen())),
    );

    await tester.tap(find.text('Mode DHCP'));
    await tester.pump();

    final ipField = tester.widget<TextField>(find.byType(TextField).at(0));
    final dnsField = tester.widget<TextField>(find.byType(TextField).at(3));
    expect(ipField.enabled, isFalse);
    expect(dnsField.enabled, isTrue);
  });

  testWidgets(
      'F3: le pavé reste ouvert si le DNS était actif au moment du basculement',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen())),
    );

    await tester.tap(find.byType(TextField).at(3)); // focaliser le DNS
    // pumpAndSettle : laisse l'animation d'apparition du curseur clignotant
    // du champ focalisé se terminer. Avec le bandeau Ethernet (F2), qui
    // décale désormais "Mode DHCP" plus bas dans la mise en page, un simple
    // pump() laissait cette transition en cours et le tap suivant ratait
    // parfois son hit-test — le test passait alors sans avoir réellement
    // basculé le mode DHCP (faux positif silencieux).
    await tester.pumpAndSettle();
    expect(find.byType(OnScreenKeypad), findsOneWidget);

    await tester.tap(find.text('Mode DHCP'));
    await tester.pump();

    expect(find.byType(OnScreenKeypad), findsOneWidget); // toujours ouvert
  });

  testWidgets(
      'F3: le pavé se ferme si le champ actif devient grisé au basculement',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen())),
    );

    await tester.tap(find.byType(TextField).at(0)); // focaliser l'IP
    await tester.pump();
    expect(find.byType(OnScreenKeypad), findsOneWidget);

    await tester.tap(find.text('Mode DHCP'));
    await tester.pump();

    expect(find.byType(OnScreenKeypad), findsNothing); // fermé
  });

  testWidgets('F2: câble détecté → bandeau vert "Câble Ethernet détecté"',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConnectiviteScreen(ethernetStream: Stream.value(true)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Câble Ethernet détecté'), findsOneWidget);
    expect(find.text('Câble Ethernet non détecté'), findsNothing);
  });

  testWidgets(
      'F2: câble débranché → bandeau rouge "Câble Ethernet non détecté"',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConnectiviteScreen(ethernetStream: Stream.value(false)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Câble Ethernet non détecté'), findsOneWidget);
    expect(find.text('Câble Ethernet détecté'), findsNothing);
  });

  testWidgets('F2: transition branché → débranché met le bandeau à jour',
      (tester) async {
    final controller = StreamController<bool>();
    addTearDown(controller.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConnectiviteScreen(ethernetStream: controller.stream),
        ),
      ),
    );

    controller.add(true);
    await tester.pump();
    expect(find.text('Câble Ethernet détecté'), findsOneWidget);

    controller.add(false);
    await tester.pump();
    // StreamController.add() planifie l'émission en microtask : un second
    // pump() est nécessaire pour que le StreamBuilder la reçoive avant
    // l'assertion.
    await tester.pump();
    expect(find.text('Câble Ethernet non détecté'), findsOneWidget);
  });
}
