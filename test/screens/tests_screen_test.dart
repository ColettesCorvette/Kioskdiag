import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/models/turnstile_event.dart';
import 'package:kioskdiag/screens/tests_screen.dart';

void main() {
  testWidgets('bandeau initial = en attente, aucune rotation commandée',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TestsScreen(
        commanderRotation: (ip, sens) async => true,
        evenements: (ip) => const Stream.empty(),
      ),
    ));
    expect(find.text("En attente d'une commande de rotation."), findsOneWidget);
  });

  testWidgets('F4: commande horaire acceptée puis confirmée → bandeau validé',
      (tester) async {
    final events = StreamController<EvenementTourniquet>.broadcast();
    addTearDown(events.close);
    await tester.pumpWidget(MaterialApp(
      home: TestsScreen(
        commanderRotation: (ip, sens) async => true,
        evenements: (ip) => events.stream,
      ),
    ));

    await tester.tap(find.byIcon(Icons.rotate_right));
    await tester.pump();
    expect(find.text('Commande envoyée...'), findsOneWidget);

    events.add(const RotationDetectee(SensRotation.horaire));
    await tester.pump();

    expect(
      find.text('Rotation du bras dans le sens horaire validée.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'F4: commande anti-horaire acceptée puis confirmée → bandeau validé',
      (tester) async {
    final events = StreamController<EvenementTourniquet>.broadcast();
    addTearDown(events.close);
    await tester.pumpWidget(MaterialApp(
      home: TestsScreen(
        commanderRotation: (ip, sens) async => true,
        evenements: (ip) => events.stream,
      ),
    ));

    await tester.tap(find.byIcon(Icons.rotate_left));
    await tester.pump();

    events.add(const RotationDetectee(SensRotation.antiHoraire));
    await tester.pump();

    expect(
      find.text('Rotation du bras dans le sens anti-horaire validée.'),
      findsOneWidget,
    );
  });

  testWidgets('F4: gatectl refuse la commande → bandeau échec',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TestsScreen(
        commanderRotation: (ip, sens) async => false,
        evenements: (ip) => const Stream.empty(),
      ),
    ));

    await tester.tap(find.byIcon(Icons.rotate_right));
    await tester.pump();

    expect(find.text('Échec : gatectl injoignable.'), findsOneWidget);
  });

  testWidgets(
      'F4: commande acceptée mais aucune confirmation → bandeau échec après le délai',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TestsScreen(
        commanderRotation: (ip, sens) async => true,
        evenements: (ip) => const Stream.empty(),
      ),
    ));

    await tester.tap(find.byIcon(Icons.rotate_right));
    await tester.pump();
    expect(find.text('Commande envoyée...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 10, milliseconds: 100));

    expect(find.text('Échec : délai dépassé.'), findsOneWidget);
  });

  testWidgets(
      'F4: la pastille de sortie reflète le sens réellement confirmé (horaire)',
      (tester) async {
    final events = StreamController<EvenementTourniquet>.broadcast();
    addTearDown(events.close);
    await tester.pumpWidget(MaterialApp(
      home: TestsScreen(
        commanderRotation: (ip, sens) async => true,
        evenements: (ip) => events.stream,
      ),
    ));

    events.add(const BoutonSortiePresse());
    await tester.pump();
    events.add(const RotationDetectee(SensRotation.horaire));
    // Un deuxième événement livré sur un StreamController.broadcast() après
    // un pump() intermédiaire prend un tour de microtask supplémentaire
    // avant que setState ne déclenche le rebuild : un seul pump() ne suffit
    // pas ici (constaté empiriquement, indépendant de la machine à états).
    await tester.pump();
    await tester.pump();

    expect(find.text('Sortie sens Horaire détectée'), findsOneWidget);
  });

  testWidgets(
      'F4: la pastille de sortie reflète le sens réellement confirmé (anti-horaire)',
      (tester) async {
    final events = StreamController<EvenementTourniquet>.broadcast();
    addTearDown(events.close);
    await tester.pumpWidget(MaterialApp(
      home: TestsScreen(
        commanderRotation: (ip, sens) async => true,
        evenements: (ip) => events.stream,
      ),
    ));

    events.add(const BoutonSortiePresse());
    await tester.pump();
    events.add(const RotationDetectee(SensRotation.antiHoraire));
    // cf. commentaire du test symétrique (sens horaire) ci-dessus : le
    // deuxième événement livré nécessite un pump() de plus.
    await tester.pump();
    await tester.pump();

    expect(find.text('Sortie sens Anti-Horaire détectée'), findsOneWidget);
  });

  testWidgets(
      'F4: statut du test bouton poussoir progresse par étapes (pression puis rotation)',
      (tester) async {
    final events = StreamController<EvenementTourniquet>.broadcast();
    addTearDown(events.close);
    await tester.pumpWidget(MaterialApp(
      home: TestsScreen(
        commanderRotation: (ip, sens) async => true,
        evenements: (ip) => events.stream,
      ),
    ));

    expect(find.text('En attente...'), findsNWidgets(2));

    events.add(const BoutonSortiePresse());
    await tester.pump();

    expect(find.text('En attente...'), findsOneWidget);
    expect(find.text('Sortie sens Horaire détectée'), findsNothing);

    events.add(const RotationDetectee(SensRotation.horaire));
    // cf. commentaire plus haut dans ce fichier : deuxième événement livré
    // après un pump() intermédiaire, un pump() de plus est nécessaire.
    await tester.pump();
    await tester.pump();

    expect(find.text('En attente...'), findsNothing);
    expect(find.text('Sortie sens Horaire détectée'), findsOneWidget);
  });

  testWidgets(
      "F4: taper sur l'illustration réinitialise le statut du bouton poussoir",
      (tester) async {
    final events = StreamController<EvenementTourniquet>.broadcast();
    addTearDown(events.close);
    await tester.pumpWidget(MaterialApp(
      home: TestsScreen(
        commanderRotation: (ip, sens) async => true,
        evenements: (ip) => events.stream,
      ),
    ));

    events.add(const BoutonSortiePresse());
    await tester.pump();
    events.add(const RotationDetectee(SensRotation.horaire));
    // cf. commentaire plus haut dans ce fichier : deuxième événement livré
    // après un pump() intermédiaire, un pump() de plus est nécessaire.
    await tester.pump();
    await tester.pump();
    expect(find.text('Sortie sens Horaire détectée'), findsOneWidget);

    await tester.tap(find.byKey(const Key('turnstile_illustration')));
    await tester.pump();

    expect(find.text('En attente...'), findsNWidgets(2));
    expect(find.text('Sortie sens Horaire détectée'), findsNothing);
  });
}
