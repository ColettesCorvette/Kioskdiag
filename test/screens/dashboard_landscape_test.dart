import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/models/diagnostic_data.dart';
import 'package:kioskdiag/screens/dashboard_screen.dart';
import 'package:kioskdiag/widgets/section_card.dart';

void main() {
  testWidgets('Dashboard paysage : uptime et perf côte à côte (2 colonnes)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardScreen(
            data: DiagnosticData.mock(),
            uptime: DiagnosticData.mock().uptime,
            embedFooter: false,
          ),
        ),
      ),
    );
    expect(find.byType(SectionCard), findsNWidgets(3));
    final uptime = tester.getTopLeft(find.byType(SectionCard).at(0));
    final perf = tester.getTopLeft(find.byType(SectionCard).at(2));
    expect(perf.dx, greaterThan(uptime.dx)); // perf à droite de uptime
    expect(perf.dy, closeTo(uptime.dy, 1)); // même haut de ligne → côte à côte
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dashboard étroit : perf sous uptime (colonne unique)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardScreen(
            data: DiagnosticData.mock(),
            uptime: DiagnosticData.mock().uptime,
            embedFooter: false,
          ),
        ),
      ),
    );
    expect(find.byType(SectionCard), findsNWidgets(3));
    final uptime = tester.getTopLeft(find.byType(SectionCard).at(0));
    final perf = tester.getTopLeft(find.byType(SectionCard).at(2));
    expect(perf.dy, greaterThan(uptime.dy)); // perf empilé sous uptime
    expect(tester.takeException(), isNull);
  });
}
