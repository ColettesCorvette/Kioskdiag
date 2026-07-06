import 'dart:async';
import 'dart:io';

/// Stream de l'état du câble Ethernet, échantillonné toutes les 2 s en lisant
/// /sys/class/net/<iface>/carrier ('1' = câble branché). Interface par défaut
/// eth0, surchargeable via KIOSKDIAG_IFACE (Puppet, par borne).
///
/// Implémenté via StreamController + Timer.periodic (plutôt qu'un générateur
/// async* avec Future.delayed) pour que l'annulation de l'abonnement coupe
/// immédiatement et fiablement le timer sous-jacent : un générateur async*
/// suspendu dans un await ne réagit à l'annulation qu'au prochain yield, ce
/// qui laisse un Timer actif après la destruction du widget (et fait échouer
/// les tests widget avec "A Timer is still pending...").
Stream<bool> ethernetConnected() {
  final iface = Platform.environment['KIOSKDIAG_IFACE'] ?? 'eth0';
  final file = File('/sys/class/net/$iface/carrier');
  late final StreamController<bool> controller;
  Timer? timer;

  void tick() => controller.add(_readCarrier(file));

  controller = StreamController<bool>(
    onListen: () {
      tick();
      timer = Timer.periodic(const Duration(seconds: 2), (_) => tick());
    },
    onCancel: () {
      timer?.cancel();
    },
  );
  return controller.stream;
}

bool _readCarrier(File file) {
  try {
    return file.readAsStringSync().trim() == '1';
  } catch (_) {
    return false;
  }
}
