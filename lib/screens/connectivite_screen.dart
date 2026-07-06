import 'package:flutter/material.dart';

import '../theme.dart';
import '../util/ipv4.dart';
import '../widgets/onscreen_keypad.dart';

/// Onglet Connectivité : configuration réseau du tourniquet (statique / DHCP),
/// adresse du serveur Fluxia, et actions de test / sauvegarde. La saisie se
/// fait via le pavé numérique embarqué [OnScreenKeypad].
class ConnectiviteScreen extends StatefulWidget {
  const ConnectiviteScreen({super.key});

  @override
  State<ConnectiviteScreen> createState() => _ConnectiviteScreenState();
}

class _ConnectiviteScreenState extends State<ConnectiviteScreen> {
  bool _dhcp = false;

  final _ip = TextEditingController(text: '192.168.10.41');
  final _mask = TextEditingController(text: '255.255.255.0');
  final _gateway = TextEditingController(text: '192.168.10.1');
  final _dns = TextEditingController(text: '192.168.10.1');
  final _serverIp = TextEditingController(text: '192.168.10.41');

  /// Message d'erreur par champ, vide tant qu'aucune sauvegarde invalide n'a
  /// eu lieu.
  final Map<TextEditingController, String> _errors = {};

  /// Champ qui reçoit la frappe du pavé, null si le pavé est masqué.
  TextEditingController? _active;

  @override
  void dispose() {
    for (final c in [_ip, _mask, _gateway, _dns, _serverIp]) {
      c.dispose();
    }
    super.dispose();
  }

  void _focus(TextEditingController c) {
    setState(() => _active = c);
  }

  void _closeKeypad() {
    FocusScope.of(context).unfocus();
    setState(() => _active = null);
  }

  void _onKey(String ch) {
    final c = _active;
    if (c == null) return;
    final sel = c.selection;
    final text = c.text;
    final String newText;
    final int newOffset;
    if (sel.isValid) {
      newText = text.replaceRange(sel.start, sel.end, ch);
      newOffset = sel.start + ch.length;
    } else {
      newText = text + ch;
      newOffset = newText.length;
    }
    if (newText.length > 15) return; // "255.255.255.255" = 15 caractères max.
    if (_errors.remove(c) != null) setState(() {});
    c.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  void _onBackspace() {
    final c = _active;
    if (c == null) return;
    final sel = c.selection;
    final text = c.text;
    if (_errors.remove(c) != null) setState(() {});
    if (sel.isValid && sel.start != sel.end) {
      final newText = text.replaceRange(sel.start, sel.end, '');
      c.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: sel.start),
      );
    } else if (sel.isValid && sel.start > 0) {
      final newText = text.replaceRange(sel.start - 1, sel.start, '');
      c.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: sel.start - 1),
      );
    } else if (!sel.isValid && text.isNotEmpty) {
      // Repli pour un champ jamais touché (sélection pas encore positionnée) :
      // pas de curseur connu, on efface depuis la fin. Si la sélection EST
      // valide et collée à l'offset 0, il n'y a rien avant le curseur à
      // effacer : ne rien faire (c'est le cas que ce correctif ajoute).
      c.text = text.substring(0, text.length - 1);
      c.selection = TextSelection.collapsed(offset: c.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle('CONFIGURATION RÉSEAU DU TOURNIQUET'),
                const SizedBox(height: 10),
                _modeToggle(),
                const SizedBox(height: 14),
                _field('Adresse IP', _ip),
                _field('Masque de sous-réseau', _mask),
                _field('Passerelle', _gateway),
                _field('DNS', _dns),
                const SizedBox(height: 18),
                _sectionTitle('CONFIGURATION SERVEUR DE FLUXIA'),
                const SizedBox(height: 10),
                _field('Adresse IP', _serverIp, alwaysEnabled: true),
                const SizedBox(height: 18),
                _actions(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        if (_active != null)
          OnScreenKeypad(
            onKey: _onKey,
            onBackspace: _onBackspace,
            onClose: _closeKeypad,
          ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF222428),
      ),
    );
  }

  Widget _modeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD6D9DE)),
      ),
      child: Row(
        children: [
          _modeTab(label: 'Mode Statique', selected: !_dhcp, onTap: () {
            setState(() => _dhcp = false);
          }),
          _modeTab(label: 'Mode DHCP', selected: _dhcp, onTap: () {
            setState(() {
              _dhcp = true;
              _active = null;
            });
          }),
        ],
      ),
    );
  }

  Widget _modeTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: selected ? DiagColors.title.withValues(alpha: 0.10) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  const Icon(Icons.check, size: 15, color: DiagColors.title),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? DiagColors.title : const Color(0xFF222428),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool alwaysEnabled = false,
  }) {
    final enabled = alwaysEnabled || !_dhcp;
    final error = _errors[controller];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            enabled: enabled,
            // Pas de clavier système : la saisie passe par OnScreenKeypad.
            readOnly: true,
            showCursor: true,
            onTap: () => _focus(controller),
            style: const TextStyle(fontSize: 14, color: Color(0xFF222428)),
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: error != null ? Colors.red : const Color(0xFFCBCFD6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: error != null ? Colors.red : DiagColors.title,
                  width: 2,
                ),
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                error,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: DiagColors.title,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _testConnectivity,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Tester la connectivité du réseau',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: DiagColors.accentDisk,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _save,
            child: const SizedBox(
              width: 54,
              height: 50,
              child: Icon(Icons.save, color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  void _testConnectivity() {
    _closeKeypad();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test de connectivité du réseau lancé...')),
    );
  }

  void _save() {
    _closeKeypad();
    final toValidate = <TextEditingController>{
      _dns,
      _serverIp,
      if (!_dhcp) ...{_ip, _mask, _gateway},
    };
    setState(() {
      _errors.clear();
      for (final c in toValidate) {
        if (!isValidIpv4(c.text)) {
          _errors[c] = 'Adresse IPv4 invalide';
        }
      }
    });
    if (_errors.isNotEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration réseau enregistrée.')),
    );
  }
}
