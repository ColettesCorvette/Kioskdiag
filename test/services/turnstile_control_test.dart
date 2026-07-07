import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/models/turnstile_event.dart';
import 'package:kioskdiag/services/turnstile_control_io.dart' as io;
import 'package:kioskdiag/services/turnstile_control_stub.dart' as stub;

void main() {
  group('commanderRotation (io)', () {
    test('serveur injoignable (localhost, rien à l\'écoute) → false, pas d\'exception',
        () async {
      final ok = await io.commanderRotation('127.0.0.1', SensRotation.horaire);
      expect(ok, isFalse);
    });
  });

  group('evenements (io)', () {
    test('serveur injoignable → aucun événement, annulation propre, pas d\'exception',
        () async {
      final events = <EvenementTourniquet>[];
      final sub = io.evenements('127.0.0.1').listen(events.add);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await sub.cancel();
      expect(events, isEmpty);
    });
  });

  group('commanderRotation/evenements (stub web)', () {
    test('commanderRotation retourne toujours true', () async {
      expect(await stub.commanderRotation('x', SensRotation.horaire), isTrue);
    });

    test('evenements simule bouton poussoir puis rotation horaire à ~1,2s',
        () async {
      final events = <EvenementTourniquet>[];
      final sub = stub.evenements('x').listen(events.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events, hasLength(1));
      expect(events.single, isA<BoutonSortiePresse>());

      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(events, hasLength(2));
      expect(events[1], isA<RotationDetectee>());
      expect((events[1] as RotationDetectee).sens, SensRotation.horaire);

      await sub.cancel();
    });

    test('annuler l\'abonnement avant la confirmation empêche tout événement tardif',
        () async {
      final events = <EvenementTourniquet>[];
      final sub = stub.evenements('x').listen(events.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(events, hasLength(1)); // seul le BoutonSortiePresse initial
    });
  });
}
