import 'dart:async';
import 'dart:io';

import 'connectivity_check.dart';
import 'turnstile_control.dart';

/// Teste séquentiellement : gatectl (TCP), passerelle (ping), internet
/// (ping 8.8.8.8). Ponctuel (bouton) ; les tests widget injectent leur
/// testeur, cette branche ne tourne jamais sous FakeAsync.
Future<List<ResultatTest>> testerConnectivite(String serverIp) async {
  final port = gatectlPort();
  final res = <ResultatTest>[];

  try {
    final s = await Socket.connect(serverIp, port,
        timeout: const Duration(seconds: 3));
    s.destroy();
    res.add(ResultatTest(CibleTest.gatectl, true, '$serverIp:$port'));
  } catch (_) {
    res.add(ResultatTest(CibleTest.gatectl, false, '$serverIp:$port'));
  }

  final gw = gatewayFromRouteTable(_routeTable());
  if (gw == null) {
    res.add(const ResultatTest(
        CibleTest.passerelle, false, 'passerelle introuvable'));
  } else {
    res.add(ResultatTest(CibleTest.passerelle, await _ping(gw), gw));
  }

  res.add(ResultatTest(CibleTest.internet, await _ping('8.8.8.8'), '8.8.8.8'));
  return res;
}

String _routeTable() {
  try {
    return File('/proc/net/route').readAsStringSync();
  } catch (_) {
    return ''; // Mac/preview : pas de /proc → passerelle introuvable.
  }
}

Future<bool> _ping(String host) async {
  try {
    final r = await Process.run('ping', ['-c', '1', '-W', '2', host])
        .timeout(const Duration(seconds: 5));
    return r.exitCode == 0;
  } catch (_) {
    return false;
  }
}

/// Passerelle par défaut de /proc/net/route : ligne dont Destination vaut
/// 00000000, champ Gateway en hex little-endian ("0102A8C0" → 192.168.40.1).
String? gatewayFromRouteTable(String table) {
  for (final line in table.split('\n').skip(1)) {
    final f = line.trim().split(RegExp(r'\s+'));
    if (f.length < 3 || f[1] != '00000000') continue;
    final hex = f[2];
    if (hex.length != 8) continue;
    final b = [
      for (var i = 0; i < 8; i += 2) int.parse(hex.substring(i, i + 2), radix: 16)
    ];
    return '${b[3]}.${b[2]}.${b[1]}.${b[0]}';
  }
  return null;
}
