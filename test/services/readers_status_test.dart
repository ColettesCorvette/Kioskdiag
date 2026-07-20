import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/services/readers_status.dart';
import 'package:kioskdiag/services/turnstile_control.dart';

void main() {
  test('gatectlPort : défaut 8081 (env non posée dans les tests)', () {
    expect(gatectlPort(), 8081);
  });

  test(
      'readersSnapshots : serveur injoignable → snapshot vide reachable=false, '
      'annulation propre (pas de Timer pendant)', () async {
    // .invalid (NXDOMAIN garanti) : 127.0.0.1 entrerait en collision avec le
    // faux serveur du test des événements, qui écoute sur le même port.
    final sub = readersSnapshots('gatectl.invalid').listen(null);
    final first = await readersSnapshots('gatectl.invalid').first
        .timeout(const Duration(seconds: 15));
    expect(first.reachable, false);
    expect(first.readers, isEmpty); // jamais de valeurs fictives sur la borne
    await sub.cancel();
  });
}
