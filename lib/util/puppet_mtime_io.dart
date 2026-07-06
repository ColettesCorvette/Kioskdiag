import 'dart:io';

// TODO à vérifier sur borne réelle : chemin par défaut du fichier d'état
// Puppet. Peut être /var/lib/puppet/state/last_run_summary.yaml selon le
// paquet installé (cf. spec F1) — à figer seulement une fois confirmé.
const _defaultPuppetStatePath =
    '/opt/puppetlabs/puppet/cache/state/last_run_summary.yaml';

/// Date/heure du dernier passage Puppet, formatée pour le footer.
/// `path` sert uniquement aux tests (contourne la résolution par variable
/// d'env, qui n'est pas modifiable depuis un process de test Dart) ; en
/// production, appeler sans argument : la résolution passe alors par
/// KIOSKDIAG_PUPPET_STATE puis le chemin par défaut ci-dessus.
String puppetLastRunLabel({String? path}) {
  final resolved = path ??
      Platform.environment['KIOSKDIAG_PUPPET_STATE'] ??
      _defaultPuppetStatePath;
  final file = File(resolved);
  if (!file.existsSync()) return 'MAJ PUPPET : jamais';
  final mtime = file.statSync().modified;
  return 'MAJ PUPPET : ${_format(mtime)}';
}

String _format(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
}
