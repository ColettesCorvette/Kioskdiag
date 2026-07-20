import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/util/ipv4.dart';

void main() {
  group('isValidIpv4', () {
    test('adresse valide standard', () {
      expect(isValidIpv4('192.168.10.41'), isTrue);
    });

    test('bornes 0 et 255 valides', () {
      expect(isValidIpv4('0.0.0.0'), isTrue);
      expect(isValidIpv4('255.255.255.255'), isTrue);
    });

    test('chaîne vide invalide', () {
      expect(isValidIpv4(''), isFalse);
    });

    test('octet hors bornes (256) invalide', () {
      expect(isValidIpv4('256.1.1.1'), isFalse);
    });

    test("nombre d'octets insuffisant invalide", () {
      expect(isValidIpv4('1.2.3'), isFalse);
    });

    test("trop d'octets invalide", () {
      expect(isValidIpv4('1.2.3.4.5'), isFalse);
    });

    test('zéro de tête refusé', () {
      expect(isValidIpv4('01.2.3.4'), isFalse);
      expect(isValidIpv4('1.2.3.00'), isFalse);
    });

    test('caractère non numérique invalide', () {
      expect(isValidIpv4('1.2.3.a'), isFalse);
      expect(isValidIpv4('1.2.3.-1'), isFalse);
    });
  });

  group('sameIpv4Subnet', () {
    test('même /24', () {
      expect(
        sameIpv4Subnet('192.168.10.41', '192.168.10.1', '255.255.255.0'),
        isTrue,
      );
    });

    test('sous-réseaux différents', () {
      expect(
        sameIpv4Subnet('192.168.10.41', '10.30.0.1', '255.255.255.0'),
        isFalse,
      );
    });

    test('adresse invalide → false', () {
      expect(sameIpv4Subnet('', '192.168.10.1', '255.255.255.0'), isFalse);
    });
  });

  group('maskFromPrefix', () {
    test('valeurs usuelles', () {
      expect(maskFromPrefix(24), '255.255.255.0');
      expect(maskFromPrefix(16), '255.255.0.0');
      expect(maskFromPrefix(32), '255.255.255.255');
      expect(maskFromPrefix(0), '0.0.0.0');
    });
  });
}
