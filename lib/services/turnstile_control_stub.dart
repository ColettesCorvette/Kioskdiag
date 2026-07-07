import 'dart:async';

import '../models/turnstile_event.dart';

/// Web/preview : accepte toujours la commande (pas de vrai matériel).
Future<bool> commanderRotation(String serverIp, SensRotation sens) async => true;

/// Web/preview : simule une séquence bouton→rotation une fois à l'abonnement
/// (reproduit le comportement de confirmation à ~1,2 s de l'ancien mock),
/// pour que la preview reste utilisable sans matériel. Non re-déclenchable
/// par un tap (décision F4 : le tap sur l'illustration ne fait plus que
/// réinitialiser l'affichage, cf. Task 3).
Stream<EvenementTourniquet> evenements(String serverIp) {
  late final StreamController<EvenementTourniquet> controller;
  Timer? timer;
  var cancelled = false;

  controller = StreamController<EvenementTourniquet>(
    onListen: () {
      controller.add(const BoutonSortiePresse());
      timer = Timer(const Duration(milliseconds: 1200), () {
        if (!cancelled) {
          controller.add(const RotationDetectee(SensRotation.horaire));
        }
      });
    },
    onCancel: () {
      cancelled = true;
      timer?.cancel();
    },
  );
  return controller.stream;
}
