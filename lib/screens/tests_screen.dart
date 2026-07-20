import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/turnstile_event.dart';
import '../services/turnstile_control.dart' as control;
import '../theme.dart';
import '../widgets/section_card.dart';
import '../widgets/status_banner.dart';

enum _RotationState { enAttente, commandeEnvoyee, validee, echec }

/// Onglet Tests : commande la rotation du tourniquet dans les deux sens via
/// la gatectl et déroule le test du bouton poussoir de sortie à partir des
/// vrais événements remontés.
class TestsScreen extends StatefulWidget {
  const TestsScreen({
    super.key,
    this.serverIp,
    this.commanderRotation,
    this.evenements,
  });

  /// IP du serveur Fluxia, partagée avec l'onglet Connectivité. Par
  /// défaut un contrôleur local (même pattern que `ConnectiviteScreen`).
  final TextEditingController? serverIp;

  /// Par défaut `control.commanderRotation`/`control.evenements` (io réel ou
  /// stub web selon la plateforme) ; les tests injectent un flux canné.
  final Future<bool> Function(String serverIp, SensRotation sens)?
      commanderRotation;
  final Stream<EvenementTourniquet> Function(String serverIp)? evenements;

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  late final TextEditingController _serverIp =
      widget.serverIp ?? TextEditingController(text: control.gatectlDefaultIp());
  late final Future<bool> Function(String, SensRotation) _commanderRotation =
      widget.commanderRotation ?? control.commanderRotation;
  late final Stream<EvenementTourniquet> Function(String) _evenementsSource =
      widget.evenements ?? control.evenements;
  StreamSubscription<EvenementTourniquet>? _sub;
  String _subscribedIp = '';

  _RotationState _rotationState = _RotationState.enAttente;
  SensRotation? _rotationSens;
  String? _echecRaison;
  Timer? _rotationTimeoutTimer;

  bool _rotationDetected = false;
  SensRotation _detectedSens = SensRotation.horaire;

  @override
  void initState() {
    super.initState();
    _subscribedIp = _serverIp.text;
    _sub = _evenementsSource(_subscribedIp).listen(_onEvenement);
    // L'IP serveur est éditable dans l'onglet Connectivité (contrôleur
    // partagé) : sans réabonnement, le flux d'événements continuerait de
    // poller l'ancienne IP alors que les commandes partent vers la nouvelle.
    _serverIp.addListener(_resubscribeIfIpChanged);
  }

  void _resubscribeIfIpChanged() {
    if (_serverIp.text == _subscribedIp) return;
    _subscribedIp = _serverIp.text;
    _sub?.cancel();
    _sub = _evenementsSource(_subscribedIp).listen(_onEvenement);
  }

  @override
  void dispose() {
    _serverIp.removeListener(_resubscribeIfIpChanged);
    _sub?.cancel();
    _rotationTimeoutTimer?.cancel();
    if (widget.serverIp == null) _serverIp.dispose();
    super.dispose();
  }

  /// Sens réellement détecté à la validation. Peut différer du sens commandé :
  /// le relais ne fait que déverrouiller le mécanisme, la rotation vient de la
  /// poussée — on valide donc toute rotation et on affiche le sens constaté.
  SensRotation? _valideSens;

  void _onEvenement(EvenementTourniquet evt) {
    if (evt is RotationDetectee) {
      if (_rotationState == _RotationState.commandeEnvoyee) {
        _rotationTimeoutTimer?.cancel();
        setState(() {
          _rotationState = _RotationState.validee;
          _valideSens = evt.sens;
        });
      }
      // Le bouton poussoir est un contact sec câblé sur la carte mTripod :
      // la pression elle-même n'est pas détectable logiciellement, seule la
      // rotation de sortie qui en résulte l'est.
      else if (!_rotationDetected) {
        setState(() {
          _rotationDetected = true;
          _detectedSens = evt.sens;
        });
      }
    }
  }

  Future<void> _rotate(SensRotation sens) async {
    _rotationTimeoutTimer?.cancel();
    setState(() {
      _rotationState = _RotationState.commandeEnvoyee;
      _rotationSens = sens;
      _echecRaison = null;
    });
    final accepted = await _commanderRotation(_serverIp.text, sens);
    if (!mounted) return;
    if (!accepted) {
      setState(() {
        _rotationState = _RotationState.echec;
        _echecRaison = 'gatectl injoignable';
      });
      return;
    }
    _rotationTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _rotationState == _RotationState.commandeEnvoyee) {
        setState(() {
          _rotationState = _RotationState.echec;
          _echecRaison = 'délai dépassé';
        });
      }
    });
  }

  /// Réinitialise l'affichage du test du bouton poussoir ; la suite ne
  /// bouge que sur les vrais événements du flux.
  void _pressExitButton() {
    setState(() => _rotationDetected = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _rotationButton(
                  sens: SensRotation.horaire,
                  color: DiagColors.title,
                  icon: Icons.rotate_right,
                  label: 'Tourner le tourniquet\nSens Horaire',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _rotationButton(
                  sens: SensRotation.antiHoraire,
                  color: DiagColors.accentUptime,
                  icon: Icons.rotate_left,
                  label: 'Tourner le tourniquet\nSens Anti-Horaire',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _rotationBanner(),
          const SizedBox(height: 16),
          _exitButtonCard(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _rotationButton({
    required SensRotation sens,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _rotate(sens),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rotationBanner() {
    switch (_rotationState) {
      case _RotationState.enAttente:
        return const StatusBanner(
          color: DiagColors.textMuted,
          icon: Icons.info_outline,
          text: "En attente d'une commande de rotation.",
        );
      case _RotationState.commandeEnvoyee:
        return const StatusBanner(
          color: DiagColors.accentUptime,
          icon: Icons.sync,
          text: 'Commande envoyée...',
        );
      case _RotationState.validee:
        String lib(SensRotation? s) =>
            s == SensRotation.horaire ? 'horaire' : 'anti-horaire';
        if (_valideSens != null && _valideSens != _rotationSens) {
          return StatusBanner(
            color: DiagColors.accentUptime,
            icon: Icons.check,
            text: 'Rotation détectée sens ${lib(_valideSens)} '
                '(commande ${lib(_rotationSens)}).',
          );
        }
        return StatusBanner(
          color: DiagColors.accentDisk,
          icon: Icons.check,
          text: 'Rotation du bras dans le sens ${lib(_rotationSens)} validée.',
        );
      case _RotationState.echec:
        return StatusBanner(
          color: DiagColors.red,
          icon: Icons.error_outline,
          text: 'Échec : $_echecRaison.',
        );
    }
  }

  Widget _exitButtonCard() {
    return SectionCard(
      accent: DiagColors.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Test du bouton poussoir de sortie',
                  style: TextStyle(fontSize: 13, color: Color(0xFF222428)),
                ),
              ),
              Icon(Icons.touch_app, size: 20, color: DiagColors.textMuted),
            ],
          ),
          const SizedBox(height: 10),
          _consigne(),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _turnstileIllustration(),
              const SizedBox(width: 12),
              Expanded(child: _exitStatus()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _consigne() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: DiagColors.title.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: DiagColors.title, width: 3),
        ),
      ),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(fontSize: 13, color: DiagColors.title, height: 1.4),
          children: [
            TextSpan(
              text: 'CONSIGNE :\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: 'Appuyez sur le '),
            TextSpan(
              text: 'bouton poussoir physique',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: ' puis poussez le bras : la rotation de sortie confirme '
                  'le test.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _turnstileIllustration() {
    return GestureDetector(
      key: const Key('turnstile_illustration'),
      onTap: _pressExitButton,
      child: Container(
        width: 84,
        height: 104,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F1F3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/illus_test_poussoir.svg',
            width: 60,
            height: 60,
          ),
        ),
      ),
    );
  }

  Widget _exitStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STATUT EN COURS',
          style: TextStyle(fontSize: 11, color: DiagColors.textMuted),
        ),
        const SizedBox(height: 8),
        _statusLine('Rotation de sortie :', done: _rotationDetected),
        const SizedBox(height: 10),
        if (_rotationDetected) ...[
          const Center(
            child: Icon(Icons.arrow_downward, size: 26, color: Color(0xFF222428)),
          ),
          const SizedBox(height: 8),
          _detectedPill(),
        ],
      ],
    );
  }

  Widget _statusLine(String label, {required bool done}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF222428)),
          ),
        ),
        const SizedBox(width: 6),
        if (done)
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: DiagColors.accentDisk,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 13),
          )
        else
          const Text(
            'En attente...',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DiagColors.accentUptime,
            ),
          ),
      ],
    );
  }

  Widget _detectedPill() {
    final label =
        _detectedSens == SensRotation.horaire ? 'Horaire' : 'Anti-Horaire';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: DiagColors.accentDisk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DiagColors.accentDisk.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check, color: DiagColors.accentDisk, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Sortie sens $label détectée',
              style: const TextStyle(
                color: DiagColors.accentDisk,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
