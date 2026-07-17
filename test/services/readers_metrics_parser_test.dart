import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/models/reader_info.dart';
import 'package:kioskdiag/services/readers_metrics_parser.dart';

const _fixture = '''
# HELP readers_avail Reader availability
# TYPE readers_avail gauge
readers_avail{reader_id="ts-entree",name="/dev/ttyS3"} 1
readers_avail{reader_id="ts-sortie",name="/dev/ttyS4"} 0
readers_info{reader_id="ts-entree",name="/dev/ttyS3",model="IDCAPT",serial="A123"} 1
readers_info{reader_id="ts-sortie",name="/dev/ttyS4",model="QRCODE",serial="B456"} 1
readers_use_total{reader_id="ts-entree"} 1234
go_goroutines 42
truc_sans_labels 7
ligne invalide
''';

void main() {
  test('parseReadersMetrics : fusionne info/avail/use, ignore le reste', () {
    final readers = parseReadersMetrics(_fixture);
    expect(readers, hasLength(2));

    final entree = readers.firstWhere((r) => r.id == 'ts-entree');
    expect(entree.name, 'IDCAPT — /dev/ttyS3');
    expect(entree.kind, ReaderKind.rfid);
    expect(entree.status, ReaderStatus.ok);
    expect(entree.useCount, 1234);

    final sortie = readers.firstWhere((r) => r.id == 'ts-sortie');
    expect(sortie.kind, ReaderKind.qr);
    expect(sortie.status, ReaderStatus.error);
    expect(sortie.useCount, 0);
  });

  test('parseReadersMetrics : avail manquant → pending, corps vide → liste vide',
      () {
    final readers = parseReadersMetrics(
        'readers_info{reader_id="x",name="p",model="M",serial="S"} 1');
    expect(readers.single.status, ReaderStatus.pending);
    expect(parseReadersMetrics(''), isEmpty);
  });
}
