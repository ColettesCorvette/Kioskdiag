import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/turnstile_event.dart';

// Port gatectl : 8081 partout ou presque, KIOSKDIAG_GATECTL_PORT pour
// les exceptions (bièvre : 3099).
final _port = int.tryParse(
        Platform.environment['KIOSKDIAG_GATECTL_PORT'] ?? '') ??
    8081;
const _timeout = Duration(seconds: 10);

/// Port de la gatectl, partagé par les services qui lui parlent.
int gatectlPort() => _port;

/// IP par défaut de la gatectl, configurable par borne (127.0.0.1 quand
/// elle est locale). Modifiable ensuite dans l'onglet Connectivité.
String gatectlDefaultIp() =>
    Platform.environment['KIOSKDIAG_GATECTL_IP'] ?? '192.168.10.41';

/// Commande une rotation du tourniquet. `true` si la gatectl a accepté la
/// commande (202), `false` sinon (y compris injoignable/timeout).
Future<bool> commanderRotation(String serverIp, SensRotation sens) async {
  final client = HttpClient()..connectionTimeout = _timeout;
  try {
    final sensStr = sens == SensRotation.horaire ? 'horaire' : 'anti-horaire';
    final request = await client
        .postUrl(Uri.parse('http://$serverIp:$_port/api/tourniquet/rotation'))
        .timeout(_timeout);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'sens': sensStr}));
    final response = await request.close().timeout(_timeout);
    await response.drain<void>();
    return response.statusCode == 202;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}

/// Stream des événements de la gatectl (polling 500 ms). `Timer.periodic`
/// annulé dans `onCancel` — pas de générateur async* : suspendu dans un
/// await, il ne voit l'annulation qu'au prochain yield et laisse le Timer
/// actif après la destruction du widget.
Stream<EvenementTourniquet> evenements(String serverIp) {
  late final StreamController<EvenementTourniquet> controller;
  Timer? timer;
  var cancelled = false;
  var depuis = 0;
  // Le buffer gatectl garde jusqu'à 100 événements passés : le premier
  // tick sert uniquement à se caler sur le dernier ts, sans les émettre,
  // sinon chaque ouverture de l'onglet rejoue l'historique (fausses
  // validations de rotation / bouton).
  var first = true;
  // Un seul tick en vol à la fois : gatectl injoignable = chaque requête
  // attend jusqu'au timeout (10 s), et sans cette garde le Timer 500 ms
  // empilerait ~20 requêtes concurrentes en permanence (et deux ticks
  // simultanés pourraient faire régresser `depuis` → événements dupliqués).
  var busy = false;

  Future<void> tick() async {
    if (busy) return;
    busy = true;
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client
          .getUrl(Uri.parse(
              'http://$serverIp:$_port/api/tourniquet/evenements?depuis=$depuis'))
          .timeout(_timeout);
      final response = await request.close().timeout(_timeout);
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) return;
      final decoded = jsonDecode(body) as List<dynamic>;
      for (final raw in decoded) {
        final map = raw as Map<String, dynamic>;
        final ts = map['ts'] as int?;
        if (ts != null && ts > depuis) depuis = ts;
        if (cancelled || first) continue;
        final type = map['type'] as String?;
        if (type == 'bouton_sortie_presse') {
          controller.add(const BoutonSortiePresse());
        } else if (type == 'rotation_detectee') {
          final sensStr = map['sens'] as String?;
          controller.add(RotationDetectee(
            sensStr == 'horaire' ? SensRotation.horaire : SensRotation.antiHoraire,
          ));
        }
      }
      first = false;
    } catch (_) {
      // Gatectl injoignable pour ce cycle : on retente au prochain tick.
    } finally {
      client.close(force: true);
      busy = false;
    }
  }

  controller = StreamController<EvenementTourniquet>(
    onListen: () {
      timer = Timer.periodic(const Duration(milliseconds: 500), (_) => tick());
    },
    onCancel: () {
      cancelled = true;
      timer?.cancel();
    },
  );
  return controller.stream;
}
