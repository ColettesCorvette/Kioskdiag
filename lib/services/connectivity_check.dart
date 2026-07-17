export 'connectivity_check_stub.dart'
    if (dart.library.io) 'connectivity_check_io.dart';

/// Cible d'un test de connectivité, dans l'ordre d'affichage.
enum CibleTest { gatectl, passerelle, internet }

/// Résultat d'un test pour une cible.
class ResultatTest {
  const ResultatTest(this.cible, this.ok, [this.detail = '']);

  final CibleTest cible;
  final bool ok;

  /// Ce qui a été testé (IP:port, adresse pingée) ou la cause de l'échec.
  final String detail;
}

/// Signature du testeur, injectable dans ConnectiviteScreen pour les tests.
typedef TesteurConnectivite = Future<List<ResultatTest>> Function(
    String serverIp);
