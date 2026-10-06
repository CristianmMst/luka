import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/sync/domain/synced_models.dart';

part 'transaction_view.freezed.dart';

/// Canal por el que se capturó la transacción (spec 008).
enum TxChannel {
  email,
  notification,
  smsNotification,
  manual,
  nfc;

  /// Convierte el string del cable (`sms_notification`, etc.) al enum.
  /// `null` si no se reconoce.
  static TxChannel? fromWire(String wire) => switch (wire) {
    'email' => TxChannel.email,
    'notification' => TxChannel.notification,
    'sms_notification' => TxChannel.smsNotification,
    'manual' => TxChannel.manual,
    'nfc' => TxChannel.nfc,
    _ => null,
  };

  /// Convierte al string del cable.
  String toWire() => switch (this) {
    TxChannel.email => 'email',
    TxChannel.notification => 'notification',
    TxChannel.smsNotification => 'sms_notification',
    TxChannel.manual => 'manual',
    TxChannel.nfc => 'nfc',
  };
}

/// Estado de sincronización para el sello visual de la fila (spec 008).
enum SyncMark { none, pending, rejected }

/// Vista de una transacción para presentación (lista, detalle y agrupación).
@freezed
abstract class TransactionView with _$TransactionView {
  const factory TransactionView({
    required String id,
    required Cop amount,
    required TxDirection direction,
    required TxKind kind,
    required DateTime occurredAt,
    required Set<TxChannel> channels,
    required SyncMark sync,
    String? merchant,
    String? categoryId,
    String? categoryName,
    String? categorySlug,
    String? bank,

    /// Id de la cuenta vinculada (para editarla, spec 008 §3.3).
    String? accountId,

    /// Cuenta vinculada, en crudo (`Bank`/`AccountKind` del cable, spec 004
    /// §2.4); presentation arma la etiqueta con l10n. Sin cuenta, todas
    /// son `null`.
    String? accountBank,
    String? accountKind,
    String? accountLast4,
    String? accountAlias,
    String? notes,
    String? transferPairId,
    String? parsedBy,
  }) = _TransactionView;
}
