import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Fond ondulé décoratif (asset vectoriel), aligné en haut à droite derrière le
/// contenu. Non interactif : à placer dans un Stack sous le contenu.
class WaveBackground extends StatelessWidget {
  const WaveBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: SvgPicture.asset(
        'assets/bg_vagues.svg',
        width: 420,
        fit: BoxFit.fitWidth,
        alignment: Alignment.topRight,
      ),
    );
  }
}
