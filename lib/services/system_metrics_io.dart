import 'dart:io';

// Les valeurs de repli ci-dessous sont IDENTIQUES à DiagnosticData.mock() :
// tout `read*` de ce fichier tombe dessus si le fichier /proc attendu est
// absent ou illisible — cas systématique sur cette machine de dev (macOS,
// pas de /proc) et donc sur `flutter test`, qui tourne toujours sur la VM
// Dart native (jamais kIsWeb, cf. leçon Lot F2 sur ethernet_status).
const _fallbackUptime = Duration(days: 5, hours: 10, minutes: 36, seconds: 22);

/// Uptime système lu depuis /proc/uptime (1er champ, secondes). `path` sert
/// aux tests ; en production, appeler sans argument.
Duration readUptime({String path = '/proc/uptime'}) {
  try {
    return parseUptime(File(path).readAsStringSync());
  } catch (_) {
    return _fallbackUptime;
  }
}

/// Parse "12345.67 54321.00\n" — le 1er nombre est l'uptime système en
/// secondes, le second le temps idle cumulé toutes CPU confondues (ignoré).
Duration parseUptime(String content) {
  final seconds = double.parse(content.trim().split(RegExp(r'\s+')).first);
  return Duration(milliseconds: (seconds * 1000).round());
}
