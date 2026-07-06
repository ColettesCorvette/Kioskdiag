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
}
