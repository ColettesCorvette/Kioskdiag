import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/models/diagnostic_data.dart';
import 'package:kioskdiag/screens/dashboard_screen.dart';

void main() {
  testWidgets(
      'C2: le disque se rafraîchit toutes les 30s via le lecteur injecté',
      (tester) async {
    var call = 0;
    final readings = [
      const DiskInfo(freeGb: 10.8, usedGb: 21.2, totalGb: 32),
      const DiskInfo(freeGb: 9.5, usedGb: 22.5, totalGb: 32),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardScreen(
            data: DiagnosticData.mock(),
            uptime: DiagnosticData.mock().uptime,
            diskReader: () {
              final reading = readings[call.clamp(0, readings.length - 1)];
              call++;
              return reading;
            },
          ),
        ),
      ),
    );

    expect(find.textContaining('10,8'), findsOneWidget);

    await tester.pump(const Duration(seconds: 30));

    expect(find.textContaining('9,5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, skip: kIsWeb);

  testWidgets(
      'C3: carte mémoire affiche Disponible/Mise en cache, plus de champs Windows',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DashboardScreen(
          data: DiagnosticData.mock(),
          uptime: DiagnosticData.mock().uptime,
        ),
      ),
    ));

    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Mise en cache'), findsOneWidget);
    expect(find.textContaining('Réserve Paginée'), findsNothing);
    expect(find.textContaining('Handles'), findsNothing);
  });

  testWidgets(
      "C3: carte CPU affiche la même durée de fonctionnement que les pastilles d'uptime",
      (tester) async {
    const uptime = Duration(days: 2, hours: 3, minutes: 4, seconds: 5);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DashboardScreen(data: DiagnosticData.mock(), uptime: uptime),
      ),
    ));

    await tester.tap(find.byIcon(Icons.developer_board));
    await tester.pump();

    expect(find.text('2:03:04:05'), findsOneWidget);
    expect(find.textContaining('Sockets'), findsNothing);
    expect(find.textContaining('Handles'), findsNothing);
  });

  testWidgets(
      'C3: échantillonnage mémoire/CPU tourne 65s sans exception (repli /proc absent)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DashboardScreen(
          data: DiagnosticData.mock(),
          uptime: DiagnosticData.mock().uptime,
        ),
      ),
    ));

    await tester.pump(const Duration(seconds: 65));

    expect(tester.takeException(), isNull);
    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Mise en cache'), findsOneWidget);
  });
}
