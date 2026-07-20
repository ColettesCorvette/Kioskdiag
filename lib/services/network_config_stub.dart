import 'network_config.dart';

/// Web/preview : valeurs de démonstration, pas de stack réseau accessible.
NetworkConfig readNetworkConfig() => const NetworkConfig(
      ip: '192.168.10.41',
      mask: '255.255.255.0',
      gateway: '192.168.10.1',
      dns: '192.168.10.1',
    );
