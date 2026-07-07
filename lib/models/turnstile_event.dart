/// Sens de rotation commandé au tourniquet (cf. spec F4).
enum SensRotation { horaire, antiHoraire }

/// Événement remonté par la gatectl (GET .../evenements) — contrat d'API
/// PROPOSÉ par le spec F4, à confirmer avec l'équipe gatectl.
sealed class EvenementTourniquet {
  const EvenementTourniquet();
}

/// Une rotation du bras a été détectée dans le sens [sens].
class RotationDetectee extends EvenementTourniquet {
  const RotationDetectee(this.sens);
  final SensRotation sens;
}

/// Le bouton poussoir physique de sortie a été pressé.
class BoutonSortiePresse extends EvenementTourniquet {
  const BoutonSortiePresse();
}
