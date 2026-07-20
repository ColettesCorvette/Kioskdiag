import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kioskdiag/models/turnstile_event.dart';
import 'package:kioskdiag/services/turnstile_control.dart';

// Faux serveur HTTP sur le port gatectl par défaut (8081) : vérifie que le
// flux `evenements` absorbe le backlog sans l'émettre puis livre bien les
// événements suivants. Temps réel (Timer.periodic du service), pas FakeAsync.
void main() {
  test('evenements : backlog absorbé, événement suivant livré', () async {
    final HttpServer server;
    try {
      server = await HttpServer.bind('127.0.0.1', gatectlPort());
    } on SocketException {
      markTestSkipped('port ${gatectlPort()} occupé');
      return;
    }
    final buffer = <Map<String, Object>>[
      {'type': 'rotation_detectee', 'ts': 100, 'sens': 'anti-horaire'},
      {'type': 'bouton_sortie_presse', 'ts': 101},
    ];
    server.listen((req) {
      final depuis = int.tryParse(req.uri.queryParameters['depuis'] ?? '') ?? 0;
      req.response.headers.contentType = ContentType.json;
      req.response.write(
        jsonEncode([
          for (final e in buffer)
            if ((e['ts']! as int) > depuis) e,
        ]),
      );
      req.response.close();
    });

    final recus = <EvenementTourniquet>[];
    final sub = evenements('127.0.0.1').listen(recus.add);

    // Laisse passer le premier tick (calage sur le backlog).
    await Future<void>.delayed(const Duration(milliseconds: 800));
    expect(recus, isEmpty, reason: 'le backlog ne doit pas être rejoué');

    buffer.add({'type': 'rotation_detectee', 'ts': 200, 'sens': 'horaire'});
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    expect(recus, hasLength(1));
    expect(recus.single, isA<RotationDetectee>());
    expect((recus.single as RotationDetectee).sens, SensRotation.horaire);

    await sub.cancel();
    await server.close(force: true);
  });
}
