import '../models/diagnostic_data.dart';

/// Web/preview : valeur mock fixe (pas de /proc, pas de dart:io).
Duration readUptime() =>
    const Duration(days: 5, hours: 10, minutes: 36, seconds: 22);

/// Web/preview : valeur mock fixe.
DiskInfo readDisk() => const DiskInfo(freeGb: 10.8, usedGb: 21.2, totalGb: 32);
