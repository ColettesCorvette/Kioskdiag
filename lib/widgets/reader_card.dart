import 'package:flutter/material.dart';

import '../models/reader_info.dart';
import '../theme.dart';

/// Carte d'un lecteur : icône, nom, ID, badge de statut et dernier support lu.
/// Le fond est teinté selon le statut.
class ReaderCard extends StatelessWidget {
  const ReaderCard({super.key, required this.reader});

  final ReaderInfo reader;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: reader.status.tint,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: DiagColors.title,
                ),
                child: Icon(reader.kind.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reader.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222428),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _idChip(reader.id),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  const Text(
                    'STATUT :',
                    style: TextStyle(fontSize: 11, color: DiagColors.textMuted),
                  ),
                  const SizedBox(width: 6),
                  _StatusBadge(status: reader.status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Color(0xFF222428)),
                children: [
                  const TextSpan(text: 'Dernière lecture : '),
                  TextSpan(
                    text: reader.lastRead,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _idChip(int id) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x11000000),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'ID : $id',
        style: const TextStyle(fontSize: 11, color: Color(0xFF222428)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReaderStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ReaderStatus.ok:
        return _circle(Icons.check, status.color);
      case ReaderStatus.error:
        return _circle(Icons.priority_high, status.color);
      case ReaderStatus.pending:
        // Sablier sans cercle, comme la maquette.
        return Icon(Icons.hourglass_top, color: status.color, size: 20);
    }
  }

  Widget _circle(IconData icon, Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(icon, color: Colors.white, size: 14),
    );
  }
}
