import 'package:flutter/material.dart';

import '../models/reader_info.dart';
import '../services/readers_status.dart';
import '../theme.dart';
import '../widgets/reader_card.dart';

/// Onglet Lecteurs : liste des lecteurs du tourniquet, pollée sur le
/// /metrics de la gatectl. Bannière si la gatectl est injoignable.
class LecteursScreen extends StatefulWidget {
  const LecteursScreen({super.key, this.serverIp, this.snapshots});

  /// Adresse de la gatectl, partagée avec les autres onglets (home_shell).
  final TextEditingController? serverIp;

  /// Par défaut `readersSnapshots` ; les tests injectent un flux canné.
  /// Factory et non stream figé, pour se réabonner quand l'IP change
  /// (comme TestsScreen).
  final Stream<ReadersSnapshot> Function(String serverIp)? snapshots;

  @override
  State<LecteursScreen> createState() => _LecteursScreenState();
}

class _LecteursScreenState extends State<LecteursScreen> {
  late final Stream<ReadersSnapshot> Function(String) _source =
      widget.snapshots ?? readersSnapshots;
  late Stream<ReadersSnapshot> _snapshots;
  String _subscribedIp = '';

  @override
  void initState() {
    super.initState();
    _subscribedIp = widget.serverIp?.text ?? '192.168.10.41';
    _snapshots = _source(_subscribedIp);
    // IP éditable dans l'onglet Connectivité, onglets toujours montés
    // (IndexedStack) : sans réabonnement on pollerait l'ancienne IP.
    widget.serverIp?.addListener(_resubscribeIfIpChanged);
  }

  void _resubscribeIfIpChanged() {
    final ip = widget.serverIp!.text;
    if (ip == _subscribedIp) return;
    // Le StreamBuilder annule l'abonnement à l'ancien flux quand son stream
    // change d'identité (onCancel côté service → Timer arrêté).
    setState(() {
      _subscribedIp = ip;
      _snapshots = _source(ip);
    });
  }

  @override
  void dispose() {
    widget.serverIp?.removeListener(_resubscribeIfIpChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ReadersSnapshot>(
      stream: _snapshots,
      builder: (context, snap) {
        final data = snap.data ??
            ReadersSnapshot(readers: ReaderInfo.mock(), reachable: true);
        return Column(
          children: [
            if (!data.reachable)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: DiagColors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Gatectl injoignable — dernières valeurs connues',
                  style: TextStyle(fontSize: 12, color: DiagColors.red),
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: data.readers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) =>
                    ReaderCard(reader: data.readers[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}
