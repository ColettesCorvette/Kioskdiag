import 'package:flutter/material.dart';

import '../theme.dart';

/// Pavé numérique affiché à l'écran. Sur la dalle embarquée (flutter-elinux,
/// client Wayland de weston — pas flutter-pi/DRM) il n'y a pas de clavier
/// système : c'est ce widget qui saisit dans le champ actif. Les touches
/// couvrent les besoins d'une saisie d'adresse IP : chiffres et point.
///
/// La hauteur des touches est proportionnelle à la dalle pour que le pavé ne
/// masque jamais plus d'environ 40 % de l'écran.
class OnScreenKeypad extends StatelessWidget {
  const OnScreenKeypad({
    super.key,
    required this.onKey,
    required this.onBackspace,
    required this.onClose,
  });

  /// Caractère saisi.
  final ValueChanged<String> onKey;

  /// Effacement du caractère précédent.
  final VoidCallback onBackspace;

  /// Fermeture du pavé.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final keyH = (screenH * 0.075).clamp(30.0, 46.0);

    return Material(
      color: const Color(0xFFF3F1F8),
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 28,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: onClose,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 22,
                        color: DiagColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              _row(['1', '2', '3'], keyH),
              _row(['4', '5', '6'], keyH),
              _row(['7', '8', '9'], keyH),
              Row(
                children: [
                  Expanded(child: _key('.', keyH)),
                  Expanded(child: _key('0', keyH)),
                  Expanded(
                    child: _KeyButton(
                      onTap: onBackspace,
                      height: keyH,
                      tint: const Color(0xFFF5D9D7),
                      child: const Icon(Icons.backspace_outlined, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(List<String> keys, double h) {
    return Row(children: [for (final k in keys) Expanded(child: _key(k, h))]);
  }

  Widget _key(String label, double h) {
    return _KeyButton(
      onTap: () => onKey(label),
      height: h,
      child: Text(
        label,
        style: const TextStyle(fontSize: 20, color: Color(0xFF222428)),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.onTap,
    required this.child,
    required this.height,
    this.tint,
  });

  final VoidCallback onTap;
  final Widget child;
  final double height;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: tint ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(height: height, child: Center(child: child)),
        ),
      ),
    );
  }
}
