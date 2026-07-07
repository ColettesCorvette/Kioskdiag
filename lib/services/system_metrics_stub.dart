import '../models/diagnostic_data.dart';

/// Web/preview : valeur mock fixe (pas de /proc, pas de dart:io).
Duration readUptime() =>
    const Duration(days: 5, hours: 10, minutes: 36, seconds: 22);

/// Web/preview : valeur mock fixe.
DiskInfo readDisk() => const DiskInfo(freeGb: 10.8, usedGb: 21.2, totalGb: 32);

({int totalKb, int availableKb, int cachedKb}) readMemInfo() => (
      totalKb: 7900000,
      availableKb: 1600000,
      cachedKb: 2600000,
    );

String readCpuStatLine() => 'cpu  0 0 0 0 0 0 0 0 0 0';

double computeCpuUsage(String prevLine, String currLine) => 0;

String readCpuName() => 'Rockchip RK3568, 4 cœurs Cortex-A55';

int readCpuCores() => 4;

String? readCpuSpeedMHz() => null;

int readProcessCount() => 190;
