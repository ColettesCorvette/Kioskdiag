import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/services/readers_status.dart';
import 'package:kioskdiag/services/turnstile_control.dart';

void main() {
  test('gatectlPort : défaut 8081 (env non posée dans les tests)', () {
    expect(gatectlPort(), 8081);
  });

  test(
      'readersSnapshots : serveur injoignable → snapshot mock reachable=false, '
      'annulation propre (pas de Timer pendant)', () async {
    final sub = readersSnapshots('127.0.0.1').listen(null);
    final first = await readersSnapshots('127.0.0.1').first
        .timeout(const Duration(seconds: 15));
    expect(first.reachable, false);
    expect(first.readers, isNotEmpty); // repli mock
    await sub.cancel();
  });
}
