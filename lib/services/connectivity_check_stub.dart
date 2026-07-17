import 'connectivity_check.dart';

/// Web/preview : tout est « ok » après un délai simulé.
Future<List<ResultatTest>> testerConnectivite(String serverIp) async {
  await Future<void>.delayed(const Duration(milliseconds: 300));
  return [
    ResultatTest(CibleTest.gatectl, true, '$serverIp:8081'),
    const ResultatTest(CibleTest.passerelle, true, '192.168.40.1'),
    const ResultatTest(CibleTest.internet, true, '8.8.8.8'),
  ];
}

/// Pas de /proc en web : jamais de passerelle. Même signature que la
/// branche io pour l'analyseur.
String? gatewayFromRouteTable(String table) => null;
