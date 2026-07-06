import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/screens/lecteurs_screen.dart';
import 'package:kioskdiag/theme.dart';
import 'package:kioskdiag/widgets/reader_card.dart';

void main() {
  testWidgets('LecteursScreen affiche les 4 lecteurs mock avec leur nom',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LecteursScreen())),
    );

    expect(find.byType(ReaderCard), findsNWidgets(4));
    expect(find.text('RFID S&L Droite 2 Entrée'), findsOneWidget);
    expect(find.text('QR S&L Droite 2 Entrée'), findsOneWidget);
    expect(find.text('RFID S&L Droite 2 Sortie'), findsOneWidget);
    expect(find.text('BP Sortie Droite 2'), findsOneWidget);
  });

  testWidgets('LecteursScreen : le fond de chaque carte est teinté selon le statut',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LecteursScreen())),
    );

    Color cardColor(int i) {
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ReaderCard).at(i),
              matching: find.byType(Container),
            )
            .first,
      );
      return (container.decoration as BoxDecoration).color!;
    }

    // Ordre du mock (ReaderInfo.mock()) : ok, pending, error, ok.
    expect(cardColor(0), DiagColors.accentDisk.withValues(alpha: 0.12));
    expect(cardColor(1), DiagColors.accentUptime.withValues(alpha: 0.12));
    expect(cardColor(2), DiagColors.red.withValues(alpha: 0.12));
    expect(cardColor(3), DiagColors.accentDisk.withValues(alpha: 0.12));
  });
}
