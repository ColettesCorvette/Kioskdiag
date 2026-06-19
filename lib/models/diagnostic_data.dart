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
    required this.usable,
    required this.available,
    required this.committed,
    required this.cached,
    required this.pagedPool,
    required this.nonPagedPool,
    required this.speed,
    required this.slots,
    required this.formFactor,
    required this.reserved,
  });

  /// Échelle max du graphe en Go.
  final double maxGo;

  /// Historique sur ~60 s en Go.
  final List<double> series;

  final String usable;
  final String available;
  final String committed;
  final String cached;
  final String pagedPool;
  final String nonPagedPool;
  final String speed;
  final String slots;
  final String formFactor;
  final String reserved;
}

class CpuInfo {
  const CpuInfo({
    required this.name,
    required this.series,
    required this.usage,
    required this.speed,
    required this.processes,
    required this.threads,
    required this.handles,
    required this.upTime,
    required this.baseSpeed,
    required this.sockets,
    required this.cores,
    required this.logicalProcessors,
    required this.virtualization,
    required this.l1,
    required this.l2,
    required this.l3,
  });

  /// Nom complet du processeur.
  final String name;

  /// Historique sur ~60 s en pourcentage.
  final List<double> series;

  final String usage;
  final String speed;
  final String processes;
  final String threads;
  final String handles;
  final String upTime;
  final String baseSpeed;
  final String sockets;
  final String cores;
  final String logicalProcessors;
  final String virtualization;
  final String l1;
  final String l2;
  final String l3;
}

class DiagnosticData {
  const DiagnosticData({
    required this.title,
    required this.subtitle,
    required this.uptime,
    required this.disk,
    required this.memory,
    required this.cpu,
    required this.appVersion,
    required this.osVersion,
    required this.copyright,
  });

  final String title;
  final String subtitle;
  final Duration uptime;
  final DiskInfo disk;
  final MemoryInfo memory;
  final CpuInfo cpu;
  final String appVersion;
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
        usable: '7,9 Go (28,3 Mo)',
        available: '1,6 Go',
        committed: '6,3/7,9 Go',
        cached: '2,6 Go',
        pagedPool: '198 Mo',
        nonPagedPool: '356 Mo',
        speed: '2123 MT/s',
        slots: '2 sur 2',
        formFactor: 'Rangée de puces',
        reserved: '112 Mo',
      ),
      cpu: CpuInfo(
        name: 'Intel® Core™ i9-10900K CPU @ 3.70GHz',
        series: _cpuSeries,
        usage: '100%',
        speed: '4,77 GHz',
        processes: '190',
        threads: '2508',
        handles: '198723',
        upTime: '3:13:07:13',
        baseSpeed: '2,70 GHz',
        sockets: '1',
        cores: '2',
        logicalProcessors: '4',
        virtualization: 'Activé',
        l1: '128 Ko',
        l2: '512 Ko',
        l3: '3,0 Mo',
      ),
      appVersion: '2025.52.4',
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
