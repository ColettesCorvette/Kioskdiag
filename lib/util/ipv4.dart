/// Valide une adresse IPv4 stricte : 4 octets séparés par des points, chacun
/// entre 0 et 255. Les zéros de tête sont refusés (« 01 » invalide, seul
/// « 0 » est un octet valide) pour éviter toute confusion octal/décimal.
bool isValidIpv4(String input) {
  return ipv4ToInt(input) != null;
}

/// IPv4 → entier 32 bits, null si invalide (mêmes règles que [isValidIpv4]).
int? ipv4ToInt(String input) {
  final parts = input.split('.');
  if (parts.length != 4) return null;
  var result = 0;
  for (final part in parts) {
    if (part.isEmpty || part.length > 3) return null;
    if (!RegExp(r'^\d+$').hasMatch(part)) return null;
    if (part.length > 1 && part.startsWith('0')) return null;
    final value = int.parse(part);
    if (value > 255) return null;
    result = (result << 8) | value;
  }
  return result;
}

/// Vrai si a et b sont dans le même sous-réseau pour ce masque. Faux si l'une
/// des trois adresses est invalide.
bool sameIpv4Subnet(String a, String b, String mask) {
  final ia = ipv4ToInt(a), ib = ipv4ToInt(b), im = ipv4ToInt(mask);
  if (ia == null || ib == null || im == null) return false;
  return (ia & im) == (ib & im);
}

/// Longueur de préfixe CIDR → masque pointé ("24" → 255.255.255.0).
String maskFromPrefix(int prefix) {
  final m = prefix <= 0 ? 0 : (0xffffffff << (32 - prefix)) & 0xffffffff;
  return '${(m >> 24) & 255}.${(m >> 16) & 255}.${(m >> 8) & 255}.${m & 255}';
}
