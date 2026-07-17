import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/services/connectivity_check.dart';

const _routeFixture = '''
Iface	Destination	Gateway 	Flags	RefCnt	Use	Metric	Mask		MTU	Window	IRTT
eth0	00000000	0102A8C0	0003	0	0	100	00000000	0	0	0
eth0	0002A8C0	00000000	0001	0	0	100	00FFFFFF	0	0	0
''';

void main() {
  test('gatewayFromRouteTable : hex little-endian → IPv4', () {
    expect(gatewayFromRouteTable(_routeFixture), '192.168.40.1');
  });

  test('gatewayFromRouteTable : pas de route par défaut → null', () {
    expect(gatewayFromRouteTable(''), isNull);
    expect(
      gatewayFromRouteTable('Iface\tDestination\tGateway\n'
          'eth0\t0002A8C0\t00000000\t...'),
      isNull,
    );
  });
}
