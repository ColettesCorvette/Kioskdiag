import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/turnstile_event.dart';

// Contrat d'API PROPOSÉ par le spec F4, À CONFIRMER avec l'équipe gatectl
// avant tout déploiement réel — implémenté selon la proposition du spec,
// jamais testé contre un vrai serveur. Le format JSON des événements
// (tableau, champs "type"/"ts"/"sens") est une proposition de ce lot, non
// spécifiée par le spec, à valider en même temps que le reste du contrat.
const _port = 8080;
const _timeout = Duration(seconds: 10);

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
/// classique annulé dans `onCancel` (jamais de générateur async* +
/// Future.delayed — cf. leçon Lot F2 sur ethernet_status : un générateur
/// suspendu dans un await ne réagit à l'annulation qu'au prochain yield,
/// laissant un Timer actif après la destruction du widget).
Stream<EvenementTourniquet> evenements(String serverIp) {
  late final StreamController<EvenementTourniquet> controller;
  Timer? timer;
  var cancelled = false;
  var depuis = 0;
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
        if (cancelled) continue;
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
