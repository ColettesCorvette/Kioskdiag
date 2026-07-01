import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/widgets/wave_background.dart';

void main() {
  testWidgets('WaveBackground rend un SvgPicture sans erreur', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WaveBackground())),
    );
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
