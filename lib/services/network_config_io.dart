import 'dart:io';

import '../util/ipv4.dart';
import 'connectivity_check.dart';
import 'network_config.dart';

/// Lit la configuration réseau réelle : IP/masque via `ip -o -4 addr`
/// (interface KIOSKDIAG_IFACE, défaut eth0), passerelle via /proc/net/route,
/// DNS via /etc/resolv.conf. Champs null si indisponibles (Mac, tests).
NetworkConfig readNetworkConfig() {
  final iface = Platform.environment['KIOSKDIAG_IFACE'] ?? 'eth0';
  String? ip;
  String? mask;
  try {
    final r = Process.runSync('ip', ['-o', '-4', 'addr', 'show', 'dev', iface]);
    final m = RegExp(r'inet (\d+\.\d+\.\d+\.\d+)/(\d+)')
        .firstMatch(r.stdout as String);
    if (m != null) {
      ip = m[1];
      mask = maskFromPrefix(int.parse(m[2]!));
    }
  } catch (_) {}

  String? gateway;
  try {
    gateway =
        gatewayFromRouteTable(File('/proc/net/route').readAsStringSync());
  } catch (_) {}

  String? dns;
  try {
    for (final line in File('/etc/resolv.conf').readAsLinesSync()) {
      final f = line.trim().split(RegExp(r'\s+'));
      if (f.length >= 2 && f[0] == 'nameserver' && isValidIpv4(f[1])) {
        dns = f[1];
        break;
      }
    }
  } catch (_) {}

  return NetworkConfig(ip: ip, mask: mask, gateway: gateway, dns: dns);
}
