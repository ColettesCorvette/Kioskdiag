import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/screens/tests_screen.dart';

void main() {
  testWidgets('A2: pastille affiche Horaire quand ce sens a été commandé',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TestsScreen()));

    await tester.tap(find.byIcon(Icons.rotate_right));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.account_balance));
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Sortie sens Horaire détectée'), findsOneWidget);
  });

  testWidgets(
      'A2: pastille affiche Anti-Horaire quand ce sens a été commandé',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TestsScreen()));

    await tester.tap(find.byIcon(Icons.rotate_left));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.account_balance));
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Sortie sens Anti-Horaire détectée'), findsOneWidget);
  });

  testWidgets('G: bandeau initial = en attente, aucune rotation commandée',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TestsScreen()));
    expect(find.text("En attente d'une commande de rotation."), findsOneWidget);
  });

  testWidgets('G: bandeau validé après une commande horaire', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TestsScreen()));
    await tester.tap(find.byIcon(Icons.rotate_right));
    await tester.pump();
    expect(
      find.text('Rotation du bras dans le sens horaire validée.'),
      findsOneWidget,
    );
  });

  testWidgets('G: bandeau validé après une commande anti-horaire',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TestsScreen()));
    await tester.tap(find.byIcon(Icons.rotate_left));
    await tester.pump();
    expect(
      find.text('Rotation du bras dans le sens anti-horaire validée.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'G: statut du test bouton poussoir progresse par étapes (pression puis rotation)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TestsScreen()));

    // Avant tout appui : les deux lignes de statut affichent "En attente...".
    expect(find.text('En attente...'), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.account_balance));
    await tester.pump();

    // Juste après l'appui : pression détectée, rotation pas encore.
    expect(find.text('En attente...'), findsOneWidget);
    expect(find.text('Sortie sens Horaire détectée'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1200));

    // Après le délai simulé : rotation détectée, pastille affichée.
    expect(find.text('En attente...'), findsNothing);
    expect(find.text('Sortie sens Horaire détectée'), findsOneWidget);
  });
}
