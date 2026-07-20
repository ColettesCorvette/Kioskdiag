import 'dart:async';

import '../models/turnstile_event.dart';

/// Web/preview : accepte toujours la commande (pas de vrai matériel).
Future<bool> commanderRotation(String serverIp, SensRotation sens) async => true;

/// Web/preview : simule bouton puis rotation ~1,2 s après l'abonnement,
/// pour garder la preview utilisable sans matériel.
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

/// Web/preview : port et IP gatectl par défaut.
int gatectlPort() => 8081;

String gatectlDefaultIp() => '192.168.10.41';
