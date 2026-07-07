/// Données affichées par l'écran de diagnostic.
///
/// Aujourd'hui en dur via [DiagnosticData.mock] 
library;

class DiskInfo {
  const DiskInfo({
    required this.freeGb,
    required this.usedGb,
    required this.totalGb,
  });

  final double freeGb;
  final double usedGb;
  final double totalGb;

  /// Fraction utilisée de 0 à 1 pour l'anneau.
  double get usedFraction => totalGb == 0 ? 0 : (usedGb / totalGb).clamp(0, 1);
}

class MemoryInfo {
  const MemoryInfo({
    required this.maxGo,
    required this.series,
    required this.available,
    required this.cached,
  });

  /// Échelle max du graphe en Go.
  final double maxGo;

  /// Historique sur ~60 s en Go (mémoire utilisée).
  final List<double> series;

  final String available;
  final String cached;
}

class CpuInfo {
  const CpuInfo({
    required this.name,
    required this.series,
    required this.usage,
    this.speed,
    required this.processes,
    required this.cores,
  });

  /// Nom du processeur (best-effort depuis /proc/cpuinfo, cf. C3).
  final String name;

  /// Historique sur ~60 s en pourcentage.
  final List<double> series;

  final String usage;

  /// Fréquence courante si disponible (ex. "1,80 GHz") ; null sinon.
  final String? speed;
  final String processes;
  final String cores;
}

class DiagnosticData {
  const DiagnosticData({
    required this.title,
    required this.subtitle,
    required this.uptime,
    required this.disk,
    required this.memory,
    required this.cpu,
    required this.osVersion,
    required this.copyright,
  });

  final String title;
  final String subtitle;
  final Duration uptime;
  final DiskInfo disk;
  final MemoryInfo memory;
  final CpuInfo cpu;
  final String osVersion;
  final String copyright;

  factory DiagnosticData.mock() {
    return const DiagnosticData(
      title: 'DIAGNOSTIC TOURNIQUET',
      subtitle: 'SPORTS & LOISIRS ENTRÉE DROITE',
      uptime: Duration(days: 5, hours: 10, minutes: 36, seconds: 22),
      disk: DiskInfo(freeGb: 10.8, usedGb: 21.2, totalGb: 32),
      memory: MemoryInfo(
        maxGo: 7.9,
        series: _memorySeries,
        available: '1,6 Go',
        cached: '2,6 Go',
      ),
      cpu: CpuInfo(
        name: 'Rockchip RK3568, 4 cœurs Cortex-A55',
        series: _cpuSeries,
        usage: '100%',
        speed: '1,80 GHz',
        processes: '190',
        cores: '4',
      ),
      osVersion: '2026.01.1',
      copyright: 'COPYRIGHT © 2018-2026',
    );
  }

  // Courbe d'exemple plat bas puis montée vers un plateau ~6,3 Go.
  static const List<double> _memorySeries = [
    1.5, 1.6, 1.55, 1.7, 1.6, 1.65, 1.7, 1.6, 1.75, 1.7, //
    1.8, 1.75, 1.9, 1.85, 2.0, 1.95, 2.1, 2.0, 2.15, 2.1, //
    2.2, 2.15, 2.3, 2.25, 2.4, 2.3, 2.5, 2.4, 2.6, 2.5, //
    2.7, 2.6, 2.8, 2.7, 2.9, 2.85, 3.0, 3.2, 3.6, 4.0, //
    4.4, 4.8, 5.2, 5.5, 5.8, 6.0, 6.2, 6.3, 6.35, 6.3, //
    6.2, 6.25, 6.3, 6.2, 6.15, 6.2, 6.25, 6.2, 6.3, 6.25, //
  ];

  // Courbe CPU montée vers un plateau ~75 % puis pic à 100 %.
  static const List<double> _cpuSeries = [
    30, 32, 31, 33, 35, 34, 36, 38, 40, 45, //
    55, 62, 68, 72, 74, 73, 72, 73, 74, 73, //
    72, 73, 74, 73, 72, 73, 74, 75, 74, 73, //
    74, 75, 76, 75, 74, 75, 76, 77, 76, 75, //
    74, 73, 72, 71, 70, 72, 74, 76, 78, 80, //
    82, 80, 78, 82, 86, 90, 94, 97, 99, 100, //
  ];
}
