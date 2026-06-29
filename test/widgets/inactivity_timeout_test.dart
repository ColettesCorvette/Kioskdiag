import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/widgets/inactivity_timeout.dart';

void main() {
  testWidgets('onTimeout après la durée sans interaction', (tester) async {
    var fired = 0;
    await tester.pumpWidget(MaterialApp(
      home: InactivityTimeout(
        timeout: const Duration(minutes: 3),
        onTimeout: () => fired++,
        child: const SizedBox.expand(),
      ),
    ));
    await tester.pump(const Duration(minutes: 2));
    expect(fired, 0);
    await tester.pump(const Duration(minutes: 1, seconds: 1));
    expect(fired, 1);
  });

  testWidgets('une interaction réarme le timer', (tester) async {
    var fired = 0;
    await tester.pumpWidget(MaterialApp(
      home: InactivityTimeout(
        timeout: const Duration(minutes: 3),
        onTimeout: () => fired++,
        child: const SizedBox.expand(),
      ),
    ));
    await tester.pump(const Duration(minutes: 2, seconds: 30));
    await tester.tapAt(const Offset(10, 10)); // event pointeur -> reset
    await tester.pump(const Duration(minutes: 2, seconds: 30));
    expect(fired, 0);
    await tester.pump(const Duration(seconds: 31));
    expect(fired, 1);
  });
}
