import 'dart:io';

/// Rotation par borne, réglée via la variable d'env KIOSKDIAG_ROTATION
/// (0-3, quarts de tour), configurable par Puppet — même principe que
/// `[output] transform=` dans le weston.ini de kioskview, pour les
/// tourniquets dont l'écran est monté dans l'autre sens.
int? quarterTurnsFromEnv() {
  final raw = Platform.environment['KIOSKDIAG_ROTATION'];
  return raw == null ? null : int.tryParse(raw);
}
