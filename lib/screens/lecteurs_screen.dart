import 'package:flutter/material.dart';

import '../models/reader_info.dart';
import '../widgets/reader_card.dart';

/// Onglet Lecteurs : la liste des lecteurs du tourniquet avec leur statut.
class LecteursScreen extends StatelessWidget {
  LecteursScreen({super.key});

  final List<ReaderInfo> _readers = ReaderInfo.mock();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _readers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => ReaderCard(reader: _readers[i]),
    );
  }
}
