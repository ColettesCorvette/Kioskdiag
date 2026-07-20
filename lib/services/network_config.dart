export 'network_config_stub.dart'
    if (dart.library.io) 'network_config_io.dart';

/// Configuration réseau réelle de l'interface du tourniquet, champs null
/// quand l'info n'est pas disponible.
class NetworkConfig {
  const NetworkConfig({this.ip, this.mask, this.gateway, this.dns});

  final String? ip;
  final String? mask;
  final String? gateway;
  final String? dns;
}
