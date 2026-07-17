/// Sens de rotation commandé au tourniquet.
enum SensRotation { horaire, antiHoraire }

/// Événement remonté par la gatectl (GET .../evenements).
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
