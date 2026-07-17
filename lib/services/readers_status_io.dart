import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/reader_info.dart';
import 'readers_metrics_parser.dart';
import 'turnstile_control.dart';

const _timeout = Duration(seconds: 5);

/// État des lecteurs pollé toutes les 2 s sur le /metrics de la gatectl.
/// Timer.periodic annulé dans onCancel + garde busy (pas d'async*, même
/// raison que turnstile_control).
Stream<ReadersSnapshot> readersSnapshots(String serverIp) {
  late final StreamController<ReadersSnapshot> controller;
  Timer? timer;
  var cancelled = false;
  var busy = false;
  var last = ReaderInfo.mock();

  Future<void> tick() async {
    if (busy) return;
    busy = true;
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client
          .getUrl(Uri.parse('http://$serverIp:${gatectlPort()}/metrics'))
          .timeout(_timeout);
      final response = await request.close().timeout(_timeout);
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw const HttpException('statut != 200');
      }
      last = parseReadersMetrics(body);
      if (!cancelled) {
        controller.add(ReadersSnapshot(readers: last, reachable: true));
      }
    } catch (_) {
      if (!cancelled) {
        controller.add(ReadersSnapshot(readers: last, reachable: false));
      }
    } finally {
      client.close(force: true);
      busy = false;
    }
  }

  controller = StreamController<ReadersSnapshot>(
    onListen: () {
      tick();
      timer = Timer.periodic(const Duration(seconds: 2), (_) => tick());
    },
    onCancel: () {
      cancelled = true;
      timer?.cancel();
    },
  );
  return controller.stream;
}
