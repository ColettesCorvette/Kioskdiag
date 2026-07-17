import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/models/reader_info.dart';

void main() {
  test('readerKindFor : QR/BARCODE → qr, BP/BUTTON/POUSSOIR → button, sinon rfid',
      () {
    expect(readerKindFor('QRCODE-2D', '/dev/ttyS3'), ReaderKind.qr);
    expect(readerKindFor('IDCAPT', 'barcode-front'), ReaderKind.qr);
    expect(readerKindFor('', 'BP sortie'), ReaderKind.button);
    expect(readerKindFor('PUSH_BUTTON', '5'), ReaderKind.button);
    expect(readerKindFor('IDCAPT', '/dev/ttyS3'), ReaderKind.rfid);
    expect(readerKindFor('', ''), ReaderKind.rfid);
  });
}
