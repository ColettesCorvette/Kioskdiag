import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/models/reader_info.dart';

void main() {
  test('readerKindFor : QR/BARCODE → qr, BP/BUTTON/POUSSOIR → button, sinon rfid',
      () {
    expect(readerKindFor('QRCODE-2D', '/dev/ttyS3'), ReaderKind.qr);
    expect(readerKindFor('IDCAPT', 'barcode-front'), ReaderKind.qr);
    expect(readerKindFor('VGUANG', '/dev/ttyS9'), ReaderKind.qr);
    expect(readerKindFor('', 'BP sortie'), ReaderKind.button);
    expect(readerKindFor('PUSH_BUTTON', '5'), ReaderKind.button);
    expect(readerKindFor('IDCAPT', '/dev/ttyS3'), ReaderKind.rfid);
    expect(readerKindFor('', ''), ReaderKind.rfid);
  });

  test('mergeReaders : un lecteur absent du scrape reste affiché en erreur',
      () {
    const s7 = ReaderInfo(
      id: '7',
      name: 'VGUANG — /dev/ttyS7',
      kind: ReaderKind.qr,
      status: ReaderStatus.ok,
      useCount: 12,
    );
    const s9 = ReaderInfo(
      id: '9',
      name: 'VGUANG — /dev/ttyS9',
      kind: ReaderKind.qr,
      status: ReaderStatus.ok,
      useCount: 34,
    );

    // S7 disparaît du scrape courant : conservé, statut erreur, compteur gardé.
    final merged = mergeReaders([s7, s9], [s9]);
    expect(merged.map((r) => r.id), ['7', '9']);
    expect(merged.first.status, ReaderStatus.error);
    expect(merged.first.useCount, 12);
    expect(merged.last.status, ReaderStatus.ok);

    // S7 revient : ses vraies valeurs reprennent la main.
    final back = mergeReaders(merged, [s7, s9]);
    expect(back.map((r) => r.status), everyElement(ReaderStatus.ok));
  });
}
