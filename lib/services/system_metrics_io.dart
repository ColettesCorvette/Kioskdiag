import 'dart:io';

import '../models/diagnostic_data.dart';

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

const _fallbackDisk = DiskInfo(freeGb: 10.8, usedGb: 21.2, totalGb: 32);

/// Espace disque de `path` (par défaut /data : c'est là que tout vit sur la
/// borne, root est figé à 6 Go). `Process.runSync` (jamais la variante
/// asynchrone `Process.run` — évite toute interaction fragile avec la zone
/// FakeAsync des tests widget, cf. leçon Lot F2).
DiskInfo readDisk({String path = '/data'}) {
  try {
    final result = Process.runSync('df', ['-B1', path]);
    if (result.exitCode != 0) {
      throw ProcessException('df', ['-B1', path], 'exitCode=${result.exitCode}');
    }
    return parseDfOutput(result.stdout as String);
  } catch (_) {
    return _fallbackDisk;
  }
}

/// Parse la dernière ligne de `df -B1 <chemin>` :
/// `/dev/mmcblk0p5  32000000000  21200000000  10800000000  67% /data`
DiskInfo parseDfOutput(String stdout) {
  final lines = stdout.trim().split('\n');
  final fields = lines.last.trim().split(RegExp(r'\s+'));
  final totalBytes = double.parse(fields[1]);
  final usedBytes = double.parse(fields[2]);
  const bytesPerGb = 1000 * 1000 * 1000;
  return DiskInfo(
    freeGb: (totalBytes - usedBytes) / bytesPerGb,
    usedGb: usedBytes / bytesPerGb,
    totalGb: totalBytes / bytesPerGb,
  );
}
