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

const _fallbackMemTotalKb = 7900000;
const _fallbackMemAvailableKb = 1600000;
const _fallbackMemCachedKb = 2600000;

({int totalKb, int availableKb, int cachedKb}) readMemInfo({
  String path = '/proc/meminfo',
}) {
  try {
    return parseMemInfo(File(path).readAsStringSync());
  } catch (_) {
    return (
      totalKb: _fallbackMemTotalKb,
      availableKb: _fallbackMemAvailableKb,
      cachedKb: _fallbackMemCachedKb,
    );
  }
}

({int totalKb, int availableKb, int cachedKb}) parseMemInfo(String content) {
  int? total, available, cached;
  for (final line in content.split('\n')) {
    if (line.startsWith('MemTotal:')) total = _kbValue(line);
    if (line.startsWith('MemAvailable:')) available = _kbValue(line);
    if (line.startsWith('Cached:')) cached = _kbValue(line);
  }
  if (total == null || available == null || cached == null) {
    throw const FormatException('champ manquant dans /proc/meminfo');
  }
  return (totalKb: total, availableKb: available, cachedKb: cached);
}

int _kbValue(String line) {
  final match = RegExp(r'(\d+)').firstMatch(line);
  if (match == null) throw FormatException('valeur illisible: $line');
  return int.parse(match.group(1)!);
}

const _fallbackCpuStatLine = 'cpu  0 0 0 0 0 0 0 0 0 0';

String readCpuStatLine({String path = '/proc/stat'}) {
  try {
    return File(path).readAsLinesSync().first;
  } catch (_) {
    return _fallbackCpuStatLine;
  }
}

/// % d'utilisation CPU global entre deux lectures successives de la 1re
/// ligne de /proc/stat ("cpu  user nice system idle iowait irq softirq...").
double computeCpuUsage(String prevLine, String currLine) {
  final prev = _cpuFields(prevLine);
  final curr = _cpuFields(currLine);
  if (prev.length < 5 || curr.length < 5) return 0;
  final prevIdle = prev[3] + prev[4];
  final currIdle = curr[3] + curr[4];
  final prevTotal = prev.fold(0, (a, b) => a + b);
  final currTotal = curr.fold(0, (a, b) => a + b);
  final totalDelta = currTotal - prevTotal;
  if (totalDelta <= 0) return 0;
  final idleDelta = currIdle - prevIdle;
  return ((totalDelta - idleDelta) / totalDelta * 100).clamp(0, 100);
}

List<int> _cpuFields(String line) {
  return line
      .trim()
      .split(RegExp(r'\s+'))
      .skip(1)
      .map((s) => int.tryParse(s) ?? 0)
      .toList();
}

const _fallbackCpuName = 'Rockchip RK3568, 4 cœurs Cortex-A55';

String readCpuName({String path = '/proc/cpuinfo'}) {
  try {
    return parseCpuName(File(path).readAsStringSync());
  } catch (_) {
    return _fallbackCpuName;
  }
}

// TODO à vérifier sur borne réelle : format exact de /proc/cpuinfo sur ce
// noyau RK3568 — les noyaux arm64 récents n'exposent pas toujours "model
// name" (courant sur x86) ni "Hardware" (convention historique ARM/RPi, pas
// garantie sur tous les noyaux). Repli générique si aucun des deux absent.
String parseCpuName(String content) {
  for (final line in content.split('\n')) {
    if (line.startsWith('model name')) return line.split(':').last.trim();
  }
  for (final line in content.split('\n')) {
    if (line.startsWith('Hardware')) return line.split(':').last.trim();
  }
  return 'Processeur ARM';
}

int readCpuCores({String path = '/proc/cpuinfo'}) {
  try {
    final n = parseCpuCores(File(path).readAsStringSync());
    return n > 0 ? n : 4;
  } catch (_) {
    return 4;
  }
}

int parseCpuCores(String content) {
  return content.split('\n').where((l) => l.startsWith('processor')).length;
}

String? readCpuSpeedMHz({String path = '/proc/cpuinfo'}) {
  try {
    return parseCpuSpeedGHz(File(path).readAsStringSync());
  } catch (_) {
    return null;
  }
}

String? parseCpuSpeedGHz(String content) {
  for (final line in content.split('\n')) {
    if (line.startsWith('cpu MHz')) {
      final mhz = double.tryParse(line.split(':').last.trim());
      if (mhz != null) {
        return '${(mhz / 1000).toStringAsFixed(2).replaceAll('.', ',')} GHz';
      }
    }
  }
  return null;
}

const _fallbackProcessCount = 190;

int readProcessCount({String path = '/proc'}) {
  try {
    final entries = Directory(path).listSync();
    final count = entries.where((e) {
      final name = e.path.split('/').last;
      return int.tryParse(name) != null;
    }).length;
    return count > 0 ? count : _fallbackProcessCount;
  } catch (_) {
    return _fallbackProcessCount;
  }
}
