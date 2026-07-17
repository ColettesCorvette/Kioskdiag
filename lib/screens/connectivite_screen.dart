import 'dart:async';

import 'package:flutter/material.dart';

import '../services/connectivity_check.dart';
import '../services/ethernet_status.dart';
import '../theme.dart';
import '../util/ipv4.dart';
import '../widgets/onscreen_keypad.dart';
import '../widgets/status_banner.dart';

/// Onglet Connectivité : configuration réseau du tourniquet (statique / DHCP),
/// adresse du serveur Fluxia, et actions de test / sauvegarde. La saisie se
/// fait via le pavé numérique embarqué [OnScreenKeypad].
class ConnectiviteScreen extends StatefulWidget {
  const ConnectiviteScreen(
      {super.key, this.serverIp, this.ethernetStream, this.testeur});

  /// IP du serveur Fluxia, partagée avec les autres onglets via
  /// `HomeShell` ; contrôleur local par défaut.
  final TextEditingController? serverIp;

  /// Stream de l'état du câble Ethernet. Par défaut `ethernetConnected()` ;
  /// les tests injectent un `Stream<bool>` canné (même pattern que
  /// `HomeShell.onQuit`/`initialQuarterTurns`).
  final Stream<bool>? ethernetStream;

  /// Testeur de connectivité (gatectl/passerelle/internet). Par défaut
  /// `testerConnectivite` (io réel ou stub web selon la plateforme) ; les
  /// tests injectent un résultat canné.
  final TesteurConnectivite? testeur;

  @override
  State<ConnectiviteScreen> createState() => _ConnectiviteScreenState();
}

class _ConnectiviteScreenState extends State<ConnectiviteScreen> {
  late final Stream<bool> _ethernetStream =
      widget.ethernetStream ?? ethernetConnected();

  bool _dhcp = false;

  final _ip = TextEditingController(text: '192.168.10.41');
  final _mask = TextEditingController(text: '255.255.255.0');
  final _gateway = TextEditingController(text: '192.168.10.1');
  final _dns = TextEditingController(text: '192.168.10.1');
  late final TextEditingController _serverIp =
      widget.serverIp ?? TextEditingController(text: '192.168.10.41');

  /// Message d'erreur par champ, vide tant qu'aucune sauvegarde invalide n'a
  /// eu lieu.
  final Map<TextEditingController, String> _errors = {};

  /// Champ qui reçoit la frappe du pavé, null si le pavé est masqué.
  TextEditingController? _active;

  List<ResultatTest>? _resultats;
  bool _testEnCours = false;

  Future<void> _lancerTest() async {
    setState(() => _testEnCours = true);
    final res =
        await (widget.testeur ?? testerConnectivite)(_serverIp.text);
    if (!mounted) return;
    setState(() {
      _resultats = res;
      _testEnCours = false;
    });
  }

  String _libelle(CibleTest c) => switch (c) {
        CibleTest.gatectl => 'Gatectl',
        CibleTest.passerelle => 'Passerelle',
        CibleTest.internet => 'Internet',
      };

  @override
  void dispose() {
    for (final c in [_ip, _mask, _gateway, _dns]) {
      c.dispose();
    }
    // Ne dispose _serverIp que si on l'a créé nous-mêmes : sinon il est
    // partagé (levé dans HomeShell), sa durée de vie ne nous appartient pas.
    if (widget.serverIp == null) _serverIp.dispose();
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
                _ethernetBanner(),
                const SizedBox(height: 14),
                _sectionTest(),
                const SizedBox(height: 18),
                _sectionTitle('CONFIGURATION RÉSEAU DU TOURNIQUET'),
                const SizedBox(height: 10),
                _modeToggle(),
                const SizedBox(height: 14),
                _field('Adresse IP', _ip),
                _field('Masque de sous-réseau', _mask),
                _field('Passerelle', _gateway),
                _field('DNS', _dns, alwaysEnabled: true),
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

  Widget _ethernetBanner() {
    return StreamBuilder<bool>(
      stream: _ethernetStream,
      builder: (context, snapshot) {
        final connected = snapshot.data ?? false;
        return connected
            ? const StatusBanner(
                color: DiagColors.accentDisk,
                icon: Icons.check_circle_outline,
                text: 'Câble Ethernet détecté',
              )
            : const StatusBanner(
                color: DiagColors.red,
                icon: Icons.error_outline,
                text: 'Câble Ethernet non détecté',
              );
      },
    );
  }

  Widget _sectionTest() {
    return Column(
      key: const Key('sectionTest'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('TEST DE CONNECTIVITÉ'),
        const SizedBox(height: 10),
        for (final r in _resultats ?? const <ResultatTest>[])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  r.ok ? Icons.check_circle : Icons.cancel,
                  size: 18,
                  color: r.ok ? DiagColors.accentDisk : DiagColors.red,
                ),
                const SizedBox(width: 8),
                Text(_libelle(r.cible),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(r.detail,
                    style: const TextStyle(
                        fontSize: 12, color: DiagColors.textMuted)),
              ],
            ),
          ),
        const SizedBox(height: 6),
        ElevatedButton.icon(
          onPressed: _testEnCours ? null : _lancerTest,
          icon: _testEnCours
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.network_check),
          label: const Text('Lancer le test'),
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
              // Ne fermer le pavé que si le champ actif devient grisé par le
              // basculement (DNS et IP serveur Fluxia restent éditables).
              if (_active != _dns && _active != _serverIp) _active = null;
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
    return Material(
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
    // TODO : sauvegarde factice — la config réseau n'est jamais appliquée
    // au système (netplan/nmcli). Seule l'IP serveur est partagée en mémoire.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration réseau enregistrée.')),
    );
  }
}
