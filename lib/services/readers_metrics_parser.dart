import '../models/reader_info.dart';

/// Parse le texte Prometheus de la gatectl et n'en retient que les
/// familles readers_info / readers_avail / readers_use_total. Une carte
/// lecteur par série readers_info ; avail absent → pending.
List<ReaderInfo> parseReadersMetrics(String body) {
  final lineRe = RegExp(r'^(\w+)\{([^}]*)\}\s+(\S+)$');
  final labelRe = RegExp(r'(\w+)="([^"]*)"');
  final avail = <String, bool>{}; // clé "reader_id|name"
  final use = <String, int>{}; // clé reader_id
  final infos = <Map<String, String>>[];

  for (final raw in body.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final m = lineRe.firstMatch(line);
    if (m == null) continue;
    final value = double.tryParse(m[3]!);
    if (value == null) continue;
    final labels = {for (final l in labelRe.allMatches(m[2]!)) l[1]!: l[2]!};
    switch (m[1]) {
      case 'readers_info':
        infos.add(labels);
      case 'readers_avail':
        avail['${labels['reader_id']}|${labels['name']}'] = value == 1;
      case 'readers_use_total':
        use[labels['reader_id'] ?? ''] = value.round();
    }
  }

  return [
    for (final i in infos)
      ReaderInfo(
        id: i['reader_id'] ?? '?',
        name: _readableName(i['model'] ?? '', i['name'] ?? ''),
        kind: readerKindFor(i['model'] ?? '', i['name'] ?? ''),
        status: switch (avail['${i['reader_id']}|${i['name']}']) {
          true => ReaderStatus.ok,
          false => ReaderStatus.error,
          null => ReaderStatus.pending,
        },
        useCount: use[i['reader_id']] ?? 0,
      ),
  ];
}

/// "VGUANG" + "/dev/ttyS9" → "Lecteur QR ttyS9 (VGUANG)" : libellé lisible
/// plutôt que les identifiants bruts de la gatectl.
String _readableName(String model, String port) {
  final kindLabel = switch (readerKindFor(model, port)) {
    ReaderKind.qr => 'Lecteur QR',
    ReaderKind.button => 'Bouton',
    ReaderKind.rfid => 'Lecteur RFID',
  };
  final tty = port.split('/').last;
  return [
    kindLabel,
    if (tty.isNotEmpty) tty,
    if (model.isNotEmpty) '($model)',
  ].join(' ');
}
