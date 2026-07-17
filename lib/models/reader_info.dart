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
    required this.useCount,
  });

  final String id;
  final String name;
  final ReaderKind kind;
  final ReaderStatus status;

  /// Lectures cumulées sur ce lecteur (readers_use_total, persistant).
  final int useCount;

  static List<ReaderInfo> mock() => const [
        ReaderInfo(
          id: '10',
          name: 'RFID S&L Droite 2 Entrée',
          kind: ReaderKind.rfid,
          status: ReaderStatus.ok,
          useCount: 1234,
        ),
        ReaderInfo(
          id: '11',
          name: 'QR S&L Droite 2 Entrée',
          kind: ReaderKind.qr,
          status: ReaderStatus.pending,
          useCount: 87,
        ),
        ReaderInfo(
          id: '12',
          name: 'RFID S&L Droite 2 Sortie',
          kind: ReaderKind.rfid,
          status: ReaderStatus.error,
          useCount: 0,
        ),
        ReaderInfo(
          id: '13',
          name: 'BP Sortie Droite 2',
          kind: ReaderKind.button,
          status: ReaderStatus.ok,
          useCount: 412,
        ),
      ];
}

/// Déduit le type de lecteur des labels gatectl (model + port).
ReaderKind readerKindFor(String model, String name) {
  final s = '$model $name'.toUpperCase();
  if (s.contains('QR') || s.contains('BARCODE')) return ReaderKind.qr;
  if (s.contains('BP') || s.contains('BUTTON') || s.contains('POUSSOIR')) {
    return ReaderKind.button;
  }
  return ReaderKind.rfid;
}

/// Photo instantanée de l'état des lecteurs, émise par readers_status.
class ReadersSnapshot {
  const ReadersSnapshot({required this.readers, required this.reachable});

  final List<ReaderInfo> readers;

  /// false si le dernier scrape de la gatectl a échoué (readers = dernière
  /// liste connue, ou mock si aucun scrape n'a jamais réussi).
  final bool reachable;
}
