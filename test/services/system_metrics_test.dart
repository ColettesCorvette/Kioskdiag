import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/models/diagnostic_data.dart';
import 'package:kioskdiag/services/system_metrics_io.dart' as io;
import 'package:kioskdiag/services/system_metrics_stub.dart' as stub;

void main() {
  group('parseUptime', () {
    test('parse un contenu /proc/uptime valide', () {
      expect(
        io.parseUptime('12345.67 54321.00\n'),
        const Duration(seconds: 12345, milliseconds: 670),
      );
    });

    test('ignore le second champ (idle cumulé toutes CPU)', () {
      expect(io.parseUptime('100.0 999999.0'), const Duration(seconds: 100));
    });
  });

  group('readUptime (io)', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('uptime_test'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('lit un fichier réel (chemin injecté)', () {
      final file = File('${tmp.path}/uptime')..writeAsStringSync('42.0 10.0');
      expect(io.readUptime(path: file.path), const Duration(seconds: 42));
    });

    test('fichier absent → repli sur la valeur mock (identique à DiagnosticData.mock())', () {
      final d = io.readUptime(path: '${tmp.path}/absent');
      expect(d, const Duration(days: 5, hours: 10, minutes: 36, seconds: 22));
    });
  });

  group('readUptime (stub web)', () {
    test('retourne la valeur mock fixe', () {
      expect(
        stub.readUptime(),
        const Duration(days: 5, hours: 10, minutes: 36, seconds: 22),
      );
    });
  });

  group('parseDfOutput', () {
    test('parse une sortie df -B1 typique', () {
      const output =
          'Filesystem      1B-blocks       Used  Available Use% Mounted on\n'
          '/dev/mmcblk0p5 32000000000 21200000000 10800000000  67% /data\n';
      final disk = io.parseDfOutput(output);
      expect(disk.totalGb, closeTo(32.0, 0.01));
      expect(disk.usedGb, closeTo(21.2, 0.01));
      expect(disk.freeGb, closeTo(10.8, 0.01));
    });
  });

  group('readDisk (io)', () {
    test('repli sur la valeur mock (df BSD sans -B1 sur cette machine)', () {
      // Ce Mac a un `df` BSD, pas GNU coreutils : `-B1` n'est pas un flag
      // valide, `df` sort en erreur → readDisk() retombe sur le repli,
      // exactement comme sur la borne si /data était absent. Ce test
      // documente ce comportement réel, ce n'est pas un mock déguisé.
      expect(
        io.readDisk(),
        const DiskInfo(freeGb: 10.8, usedGb: 21.2, totalGb: 32),
      );
    });
  });

  group('readDisk (stub web)', () {
    test('retourne la valeur mock fixe', () {
      expect(
        stub.readDisk(),
        const DiskInfo(freeGb: 10.8, usedGb: 21.2, totalGb: 32),
      );
    });
  });

  group('parseMemInfo', () {
    test('extrait MemTotal/MemAvailable/Cached en Ko', () {
      const content = 'MemTotal:        7900000 kB\n'
          'MemFree:          200000 kB\n'
          'MemAvailable:    1600000 kB\n'
          'Cached:          2600000 kB\n';
      final m = io.parseMemInfo(content);
      expect(m.totalKb, 7900000);
      expect(m.availableKb, 1600000);
      expect(m.cachedKb, 2600000);
    });

    test('champ manquant → lève une exception (capturée par readMemInfo)', () {
      expect(() => io.parseMemInfo('MemTotal: 100 kB\n'), throwsFormatException);
    });
  });

  group('computeCpuUsage', () {
    test('calcule le % entre deux lectures de /proc/stat', () {
      // idle+iowait passe de 400 à 450 (delta 50) pendant que le total
      // passe de 1000 à 1200 (delta 200) → 75% de temps non-idle.
      const prev = 'cpu  600 0 0 400 0 0 0 0 0 0';
      const curr = 'cpu  750 0 0 450 0 0 0 0 0 0';
      expect(io.computeCpuUsage(prev, curr), closeTo(75.0, 0.01));
    });

    test('aucun delta (deux lectures identiques) → 0%', () {
      const line = 'cpu  100 0 100 400 0 0 0 0 0 0';
      expect(io.computeCpuUsage(line, line), 0);
    });
  });

  group('parseCpuName', () {
    test('utilise "model name" si présent', () {
      const content = 'processor\t: 0\nmodel name\t: Cortex-A55\n';
      expect(io.parseCpuName(content), 'Cortex-A55');
    });

    test('repli sur "Hardware" si "model name" absent', () {
      const content = 'processor\t: 0\nHardware\t: Rockchip RK3568\n';
      expect(io.parseCpuName(content), 'Rockchip RK3568');
    });

    test('repli générique si aucun des deux champs présent', () {
      expect(io.parseCpuName('processor\t: 0\n'), 'Processeur ARM');
    });
  });

  group('parseCpuCores', () {
    test('compte les lignes "processor"', () {
      const content = 'processor\t: 0\nprocessor\t: 1\n'
          'processor\t: 2\nprocessor\t: 3\n';
      expect(io.parseCpuCores(content), 4);
    });
  });

  group('parseCpuSpeedGHz', () {
    test('convertit "cpu MHz" en GHz formaté', () {
      expect(io.parseCpuSpeedGHz('cpu MHz\t\t: 1800.000\n'), '1,80 GHz');
    });

    test('absent → null', () {
      expect(io.parseCpuSpeedGHz('processor\t: 0\n'), isNull);
    });
  });

  group('readMemInfo/readCpuStatLine/readCpuName/readCpuCores/readCpuSpeedMHz/readProcessCount (io)', () {
    test('/proc absent sur cette machine → replis cohérents avec le mock', () {
      final mem = io.readMemInfo();
      expect(mem.totalKb, 7900000);
      expect(mem.availableKb, 1600000);
      expect(mem.cachedKb, 2600000);

      expect(io.readCpuName(), 'Rockchip RK3568, 4 cœurs Cortex-A55');
      expect(io.readCpuCores(), 4);
      expect(io.readCpuSpeedMHz(), isNull);
      expect(io.readProcessCount(), 190);
    });
  });

  group('(stub web)', () {
    test('replis fixes', () {
      final mem = stub.readMemInfo();
      expect(mem.totalKb, 7900000);
      expect(stub.readCpuName(), 'Rockchip RK3568, 4 cœurs Cortex-A55');
      expect(stub.readCpuCores(), 4);
      expect(stub.readCpuSpeedMHz(), isNull);
      expect(stub.readProcessCount(), 190);
      expect(stub.computeCpuUsage('', ''), 0);
    });
  });
}
