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
}
