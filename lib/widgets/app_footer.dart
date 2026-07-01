import 'package:flutter/material.dart';

import '../models/diagnostic_data.dart';
import '../theme.dart';

/// Pied de page partagé : logo texte FLUXIA, copyright/version appli à
/// gauche, version OS à droite. Utilisé dans le corps du Dashboard (portrait)
/// et comme barre commune du shell (paysage).
class AppFooter extends StatelessWidget {
  const AppFooter({super.key, required this.data});

  final DiagnosticData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Flexible : à 600px de large (dalle borne en portrait), la ligne
            // copyright est trop longue pour tenir sur une seule ligne à côté
            // de la colonne "Version OS" → on autorise le retour à la ligne
            // plutôt que de débordér (RenderFlex overflow).
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fluxia(),
                  const SizedBox(height: 4),
                  Text(
                    '${data.copyright} • VERSION ${data.appVersion}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: DiagColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Version OS',
                  style: TextStyle(fontSize: 12, color: DiagColors.textMuted),
                ),
                Text(data.osVersion, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _fluxia() {
    return const Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF222428),
          letterSpacing: 0.5,
        ),
        children: [
          TextSpan(text: 'STREAML'),
          TextSpan(text: 'O', style: TextStyle(color: DiagColors.title)),
          TextSpan(text: 'R'),
        ],
      ),
    );
  }
}
