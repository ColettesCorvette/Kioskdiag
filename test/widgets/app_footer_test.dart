import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/models/diagnostic_data.dart';
import 'package:kioskdiag/widgets/app_footer.dart';

void main() {
  testWidgets('AppFooter affiche la version issue du modèle', (tester) async {
    final data = DiagnosticData.mock();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AppFooter(data: data))),
    );
    expect(find.textContaining(data.appVersion), findsOneWidget);
    expect(find.textContaining(data.osVersion), findsOneWidget);
    expect(find.textContaining('STREAML'), findsOneWidget);
  });
}
