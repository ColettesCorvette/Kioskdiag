import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/screens/connectivite_screen.dart';
import 'package:kioskdiag/services/connectivity_check.dart';
import 'package:kioskdiag/services/network_config.dart';
import 'package:kioskdiag/widgets/onscreen_keypad.dart';

// Sur la borne les champs sont pré-remplis avec la vraie stack réseau ; les
// tests injectent ces valeurs cannées (la lecture réelle rendrait les champs
// vides ou dépendants de la machine).
const _demoCfg = NetworkConfig(
  ip: '192.168.10.41',
  mask: '255.255.255.0',
  gateway: '192.168.10.1',
  dns: '192.168.10.1',
);

void main() {
  testWidgets('Test de connectivité : bouton → 3 résultats affichés',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConnectiviteScreen(networkConfig: _demoCfg, 
            testeur: (ip) async => const [
              ResultatTest(CibleTest.gatectl, true, '1.2.3.4:8081'),
              ResultatTest(CibleTest.passerelle, false, 'passerelle introuvable'),
              ResultatTest(CibleTest.internet, true, '8.8.8.8'),
            ],
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Lancer le test'));
    await tester.pump();
    await tester.tap(find.text('Lancer le test'));
    await tester.pumpAndSettle();

    // Scope au conteneur de la section : « Passerelle » est aussi le libellé
    // du champ de la section « Configuration réseau du tourniquet ».
    final section = find.byKey(const Key('sectionTest'));
    expect(find.descendant(of: section, matching: find.text('Gatectl')),
        findsOneWidget);
    expect(find.descendant(of: section, matching: find.text('Passerelle')),
        findsOneWidget);
    expect(find.descendant(of: section, matching: find.text('Internet')),
        findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    expect(find.byIcon(Icons.cancel), findsOneWidget);
  });

  testWidgets(
    'IP invalide au enregistrement → erreur affichée, pas de succès',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ConnectiviteScreen(networkConfig: _demoCfg, ))),
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

      // La section « Test de connectivité » allonge l'écran : le bouton
      // save n'est plus toujours visible sans défiler.
      await tester.ensureVisible(find.byIcon(Icons.save));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.save));
      await tester.pump();

      expect(find.text('Adresse IPv4 invalide'), findsOneWidget);
      expect(find.text('Configuration réseau enregistrée.'), findsNothing);
    },
  );

  testWidgets(
    'sauvegarde réussie quand tous les champs actifs sont valides',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ConnectiviteScreen(networkConfig: _demoCfg, ))),
      );

      await tester.ensureVisible(find.byIcon(Icons.save));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.save));
      await tester.pump();

      expect(find.text('Adresse IPv4 invalide'), findsNothing);
      expect(find.text('Configuration réseau enregistrée.'), findsOneWidget);
    },
  );

  testWidgets(
    'DHCP + DNS invalide → erreur affichée, pas de succès',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ConnectiviteScreen(networkConfig: _demoCfg, ))),
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
      // curseur clignotant. Avec le bandeau Ethernet qui décale
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
    'insertion refusée au-delà de 15 caractères',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ConnectiviteScreen(networkConfig: _demoCfg, ))),
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

  testWidgets('insertion au milieu du texte (curseur positionné, pas en fin)',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen(networkConfig: _demoCfg, ))),
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

  testWidgets('taper un chiffre remplace une sélection étendue',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen(networkConfig: _demoCfg, ))),
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

  testWidgets('point inséré automatiquement après un octet de 3 chiffres',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen(networkConfig: _demoCfg, ))),
    );
    await tester.tap(find.byType(TextField).at(0));
    await tester.pump();

    final controller =
        tester.widget<TextField>(find.byType(TextField).at(0)).controller!;
    for (var i = 0; i < 14; i++) {
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
    }
    expect(controller.text, '');

    for (final ch in ['1', '9', '2', '1', '6', '8']) {
      await tester.tap(find.text(ch));
      await tester.pump();
    }

    // Le point est apparu tout seul après « 192 », pas après « 168 » (en
    // cours de saisie).
    expect(controller.text, '192.168');
  });

  testWidgets('raccourci IP serveur : un appui remplit le champ',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen(networkConfig: _demoCfg, ))),
    );

    await tester.ensureVisible(find.byKey(const Key('ipShortcut_127.0.0.1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ipShortcut_127.0.0.1')));
    await tester.pump();

    final serverField =
        tester.widget<TextField>(find.byType(TextField).at(4)).controller!;
    expect(serverField.text, '127.0.0.1');
  });

  testWidgets("l'IP serveur ne s'applique au contrôleur partagé qu'au save",
      (tester) async {
    final shared = TextEditingController(text: '192.168.10.41');
    addTearDown(shared.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConnectiviteScreen(networkConfig: _demoCfg, serverIp: shared),
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('ipShortcut_127.0.0.1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ipShortcut_127.0.0.1')));
    await tester.pump();

    // Frappe seule : le partagé ne bouge pas (les flux des autres onglets
    // ne se réabonnent pas encore).
    expect(shared.text, '192.168.10.41');

    await tester.ensureVisible(find.byIcon(Icons.save));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.save));
    await tester.pump();

    expect(shared.text, '127.0.0.1');
  });

  testWidgets('IP serveur invalide → test réseau refusé avec erreur',
      (tester) async {
    var appels = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConnectiviteScreen(
            networkConfig: _demoCfg,
            testeur: (ip) async {
              appels++;
              return const [];
            },
          ),
        ),
      ),
    );

    // Vider le champ serveur (index 4) pour le rendre invalide.
    await tester.ensureVisible(find.byType(TextField).at(4));
    await tester.pump();
    await tester.tap(find.byType(TextField).at(4));
    await tester.pump();
    for (var i = 0; i < 14; i++) {
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
    }

    await tester.ensureVisible(find.text('Lancer le test'));
    await tester.pump();
    await tester.tap(find.text('Lancer le test'), warnIfMissed: false);
    await tester.pump();

    expect(appels, 0);
    expect(find.text('Adresse IPv4 invalide'), findsOneWidget);
  });

  testWidgets('passerelle hors du sous-réseau → erreur au save',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConnectiviteScreen(
            networkConfig: NetworkConfig(
              ip: '192.168.10.41',
              mask: '255.255.255.0',
              gateway: '10.30.0.1',
              dns: '192.168.10.1',
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.byIcon(Icons.save));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.save));
    await tester.pump();

    expect(find.text('Passerelle hors du sous-réseau'), findsOneWidget);
    expect(find.text('Configuration réseau enregistrée.'), findsNothing);
  });

  testWidgets('backspace efface une sélection étendue', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen(networkConfig: _demoCfg, ))),
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
      'backspace avec le curseur en tout début de champ ne supprime rien',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen(networkConfig: _demoCfg, ))),
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

  testWidgets('backspace sur un champ déjà vide ne fait rien (pas de crash)',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen(networkConfig: _demoCfg, ))),
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

  testWidgets('bascule Statique→DHCP : DNS reste éditable, IP grisée',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen(networkConfig: _demoCfg, ))),
    );

    await tester.tap(find.text('Mode DHCP'));
    await tester.pump();

    final ipField = tester.widget<TextField>(find.byType(TextField).at(0));
    final dnsField = tester.widget<TextField>(find.byType(TextField).at(3));
    expect(ipField.enabled, isFalse);
    expect(dnsField.enabled, isTrue);
  });

  testWidgets(
      'le pavé reste ouvert si le DNS était actif au moment du basculement',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen(networkConfig: _demoCfg, ))),
    );

    await tester.tap(find.byType(TextField).at(3)); // focaliser le DNS
    // pumpAndSettle : laisse l'animation d'apparition du curseur clignotant
    // du champ focalisé se terminer. Avec le bandeau Ethernet, qui
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
      'le pavé se ferme si le champ actif devient grisé au basculement',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConnectiviteScreen(networkConfig: _demoCfg, ))),
    );

    await tester.tap(find.byType(TextField).at(0)); // focaliser l'IP
    await tester.pump();
    expect(find.byType(OnScreenKeypad), findsOneWidget);

    await tester.tap(find.text('Mode DHCP'));
    await tester.pump();

    expect(find.byType(OnScreenKeypad), findsNothing); // fermé
  });

  testWidgets('câble détecté → bandeau vert "Câble Ethernet détecté"',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConnectiviteScreen(networkConfig: _demoCfg, ethernetStream: Stream.value(true)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Câble Ethernet détecté'), findsOneWidget);
    expect(find.text('Câble Ethernet non détecté'), findsNothing);
  });

  testWidgets(
      'câble débranché → bandeau rouge "Câble Ethernet non détecté"',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConnectiviteScreen(networkConfig: _demoCfg, ethernetStream: Stream.value(false)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Câble Ethernet non détecté'), findsOneWidget);
    expect(find.text('Câble Ethernet détecté'), findsNothing);
  });

  testWidgets('transition branché → débranché met le bandeau à jour',
      (tester) async {
    final controller = StreamController<bool>();
    addTearDown(controller.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConnectiviteScreen(networkConfig: _demoCfg, ethernetStream: controller.stream),
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

  testWidgets(
      'ConnectiviteScreen et un consommateur externe partagent le même contrôleur serverIp',
      (tester) async {
    final serverIp = TextEditingController(text: '192.168.10.41');
    addTearDown(serverIp.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ConnectiviteScreen(networkConfig: _demoCfg, serverIp: serverIp)),
    ));

    // Champ "Adresse IP" du serveur Fluxia : 5e TextField (IP, Masque,
    // Passerelle, DNS, IP serveur).
    await tester.tap(find.byType(TextField).at(4));
    await tester.pump();
    for (var i = 0; i < 14; i++) {
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
    }
    for (final k in ['1', '0', '.', '0', '.', '0', '.', '1']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }

    // La frappe reste en brouillon ; le contrôleur partagé n'est mis à jour
    // qu'à la sauvegarde.
    expect(serverIp.text, '192.168.10.41');

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down),
        warnIfMissed: false);
    await tester.pump();
    await tester.ensureVisible(find.byIcon(Icons.save));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.save));
    await tester.pump();

    expect(serverIp.text, '10.30.0.1');
  });
}
