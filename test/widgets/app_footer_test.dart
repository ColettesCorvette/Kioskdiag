import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/models/diagnostic_data.dart';
import 'package:kioskdiag/widgets/app_footer.dart';

void main() {
  testWidgets('AppFooter affiche la date du dernier passage Puppet',
      (tester) async {
    final data = DiagnosticData.mock();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AppFooter(data: data))),
    );
    // En test (VM, dart:io dispo), la variante io est utilisée : le fichier
    // d'état par défaut n'existe pas sur la machine de dev/CI → "jamais".
    expect(find.textContaining('MAJ PUPPET :'), findsOneWidget);
    expect(find.textContaining(data.osVersion), findsOneWidget);
    expect(find.bySemanticsLabel('FLUXIA'), findsOneWidget);
  });
}
