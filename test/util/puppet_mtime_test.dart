import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/util/puppet_mtime_io.dart' as io;
import 'package:kioskdiag/util/puppet_mtime_stub.dart' as stub;

void main() {
  group('puppetLastRunLabel (io)', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('puppet_mtime_test');
    });

    tearDown(() {
      tmp.deleteSync(recursive: true);
    });

    test('fichier absent → "MAJ PUPPET : jamais"', () {
      final path = '${tmp.path}/absent.yaml';
      expect(io.puppetLastRunLabel(path: path), 'MAJ PUPPET : jamais');
    });

    test('fichier présent → date/heure formatées de sa mtime', () {
      final file = File('${tmp.path}/last_run_summary.yaml')
        ..writeAsStringSync('---');
      file.setLastModifiedSync(DateTime(2026, 7, 2, 14, 32));

      final label = io.puppetLastRunLabel(path: file.path);

      expect(label, 'MAJ PUPPET : 02/07/2026 14:32');
    });

    test('heures/minutes/jour/mois à un chiffre sont zéro-paddées', () {
      final file = File('${tmp.path}/last_run_summary.yaml')
        ..writeAsStringSync('---');
      file.setLastModifiedSync(DateTime(2026, 1, 5, 4, 7));

      final label = io.puppetLastRunLabel(path: file.path);

      expect(label, 'MAJ PUPPET : 05/01/2026 04:07');
    });
  });

  group('puppetLastRunLabel (stub web)', () {
    test('retourne un tiret', () {
      expect(stub.puppetLastRunLabel(), 'MAJ PUPPET : —');
    });
  });
}
