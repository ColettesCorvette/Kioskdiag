import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
}
