import 'package:flutter/material.dart';

import '../theme.dart';

/// Type de lecteur, qui détermine l'icône affichée.
enum ReaderKind { rfid, qr, button }

/// État d'un lecteur, qui détermine la couleur de la carte et le badge.
enum ReaderStatus { ok, pending, error }

extension ReaderKindUi on ReaderKind {
  IconData get icon {
    switch (this) {
      case ReaderKind.rfid:
        return Icons.sensors;
      case ReaderKind.qr:
        return Icons.qr_code_2;
      case ReaderKind.button:
        return Icons.touch_app;
    }
  }
}

extension ReaderStatusUi on ReaderStatus {
  Color get color {
    switch (this) {
      case ReaderStatus.ok:
        return DiagColors.accentDisk;
      case ReaderStatus.pending:
        return DiagColors.accentUptime;
      case ReaderStatus.error:
        return DiagColors.red;
    }
  }

  /// Teinte de fond de la carte.
  Color get tint => color.withValues(alpha: 0.12);
}

class ReaderInfo {
  const ReaderInfo({
    required this.id,
    required this.name,
    required this.kind,
    required this.status,
    required this.lastRead,
  });

  final int id;
  final String name;
  final ReaderKind kind;
  final ReaderStatus status;

  /// Dernier support lu sur ce lecteur.
  final String lastRead;

  static List<ReaderInfo> mock() => const [
        ReaderInfo(
          id: 10,
          name: 'RFID S&L Droite 2 Entrée',
          kind: ReaderKind.rfid,
          status: ReaderStatus.ok,
          lastRead: 'NomSupportLu',
        ),
        ReaderInfo(
          id: 11,
          name: 'QR S&L Droite 2 Entrée',
          kind: ReaderKind.qr,
          status: ReaderStatus.pending,
          lastRead: 'NomSupportLu',
        ),
        ReaderInfo(
          id: 12,
          name: 'RFID S&L Droite 2 Sortie',
          kind: ReaderKind.rfid,
          status: ReaderStatus.error,
          lastRead: 'NomSupportLu',
        ),
        ReaderInfo(
          id: 13,
          name: 'BP Sortie Droite 2',
          kind: ReaderKind.button,
          status: ReaderStatus.ok,
          lastRead: 'NomSupportLu',
        ),
      ];
}
