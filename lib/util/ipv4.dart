/// Valide une adresse IPv4 stricte : 4 octets séparés par des points, chacun
/// entre 0 et 255. Les zéros de tête sont refusés (« 01 » invalide, seul
/// « 0 » est un octet valide) — décision A3 du spec, ambiguïté RFC tranchée
/// pour éviter toute confusion octal/décimal.
bool isValidIpv4(String input) {
  final parts = input.split('.');
  if (parts.length != 4) return false;
  for (final part in parts) {
    if (part.isEmpty || part.length > 3) return false;
    if (!RegExp(r'^\d+$').hasMatch(part)) return false;
    if (part.length > 1 && part.startsWith('0')) return false;
    final value = int.parse(part);
    if (value > 255) return false;
  }
  return true;
}
