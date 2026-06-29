import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/widgets/diag_header.dart';

void main() {
  testWidgets('le bouton Quitter déclenche onQuit', (tester) async {
    var quit = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DiagHeader(
          title: 'T',
          subtitle: 'S',
          onToggleOrientation: () {},
          onResetOrientation: () {},
          onQuit: () => quit++,
        ),
      ),
    ));
    await tester.tap(find.byTooltip('Quitter'));
    expect(quit, 1);
  });
}
