import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/section_card.dart';
import '../widgets/status_banner.dart';

enum _RotationDir { horaire, antiHoraire }

/// Onglet Tests : commande la rotation du tourniquet dans les deux sens et
/// déroule le test du bouton poussoir de sortie.
class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  _RotationDir? _validatedDir;
  // État simulé en attendant le vrai matériel (F4) : sens détecté par le
  // test du bouton poussoir, calé sur la dernière rotation commandée.
  _RotationDir _detectedSens = _RotationDir.horaire;

  // Test du bouton poussoir de sortie.
  bool _buttonPressed = false;
  bool _rotationDetected = false;
  Timer? _rotationTimer;

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  void _rotate(_RotationDir dir) {
    setState(() => _validatedDir = dir);
  }

  /// Simule l'appui sur le bouton poussoir physique : la pression est détectée
  /// immédiatement, la rotation des bras est confirmée peu après.
  void _pressExitButton() {
    _rotationTimer?.cancel();
    setState(() {
      _buttonPressed = true;
      _rotationDetected = false;
      if (_validatedDir != null) _detectedSens = _validatedDir!;
    });
    _rotationTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _rotationDetected = true);
    });
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
                  dir: _RotationDir.horaire,
                  color: DiagColors.title,
                  icon: Icons.rotate_right,
                  label: 'Tourner le tourniquet\nSens Horaire',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _rotationButton(
                  dir: _RotationDir.antiHoraire,
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
    required _RotationDir dir,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _rotate(dir),
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
    if (_validatedDir == null) {
      return const StatusBanner(
        color: DiagColors.textMuted,
        icon: Icons.info_outline,
        text: 'En attente d\'une commande de rotation.',
      );
    }
    final sens = _validatedDir == _RotationDir.horaire
        ? 'horaire'
        : 'anti-horaire';
    return StatusBanner(
      color: DiagColors.accentDisk,
      icon: Icons.check,
      text: 'Rotation du bras dans le sens $sens validée.',
    );
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
              text: ' et attendez la confirmation de passage par rotation '
                  'des bras.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _turnstileIllustration() {
    // Illustration provisoire à remplacer par le vrai asset du tourniquet.
    return GestureDetector(
      onTap: _pressExitButton,
      child: Container(
        width: 84,
        height: 104,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F1F3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.account_balance, size: 44, color: Color(0xFFBFC4CC)),
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
        _statusLine('Pression du Bouton :', done: _buttonPressed),
        const SizedBox(height: 6),
        _statusLine('Rotation détectée :', done: _rotationDetected),
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
        _detectedSens == _RotationDir.horaire ? 'Horaire' : 'Anti-Horaire';
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
