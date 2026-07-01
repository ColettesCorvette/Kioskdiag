import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/models/diagnostic_data.dart';
import 'package:kioskdiag/screens/dashboard_screen.dart';
import 'package:kioskdiag/widgets/section_card.dart';

void main() {
  testWidgets('Dashboard paysage rend les 3 cartes sans overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardScreen(data: DiagnosticData.mock(), embedFooter: false),
        ),
      ),
    );
    // uptime, disque, perf → au moins 3 SectionCard.
    expect(find.byType(SectionCard), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
