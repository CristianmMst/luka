import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:finanzia/features/review/domain/review_item.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';

/// Datos y dobles compartidos por los tests de la pantalla de Revisión.

class SignedInAuth extends AuthController {
  @override
  Future<AuthState> build() async => const Authenticated(
    User(id: 'ana', email: 'ana@b.co', status: UserStatus.active),
  );
}

class FixedCoordinator extends SyncCoordinator {
  FixedCoordinator([this._status = const SyncStatus()]);

  final SyncStatus _status;

  @override
  SyncStatus build() => _status;
}

/// Hora de Bogotá del día [day] de septiembre de 2026, como instante UTC.
DateTime bogota(int day, int hour, int minute) =>
    DateTime.utc(2026, 9, day, hour + 5, minute);

/// Correo de Bancolombia sin plantilla, con un teléfono que no se resalta.
final ReviewItem emailItem = ReviewItem(
  rawMessageId: 'm-email',
  channel: 'email',
  sender: 'alertas@bancolombia.com.co',
  bank: 'bancolombia',
  receivedAt: bogota(23, 12, 41),
  reason: 'no_template',
  partialExtract: const {},
  text:
      r'Bancolombia te informa un pago por $126.400 a EXITO CALLE 80 '
      'desde tu cuenta *4821.\n\nSi no reconoces esta operacion llama al '
      r'604 510 9095. Saldo disponible $1.254.300,50.',
);

/// Notificación leída a medias por el LLM: trae monto, dirección, fecha y
/// comercio.
final ReviewItem notificationItem = ReviewItem(
  rawMessageId: 'm-notif',
  channel: 'notification',
  sender: 'com.nequi.MobileApp',
  bank: 'nequi',
  receivedAt: bogota(22, 18, 30),
  reason: 'llm_low_confidence',
  partialExtract: {
    'amount': '38900.00',
    'direction': 'debit',
    'occurred_at': '2026-09-22T23:25:00+00:00',
    'merchant': 'Rappi',
  },
  text: r'Pagaste $38.900 en RAPPI con tu Nequi.',
);

/// Sin banco reconocido, motivo desconocido y el texto ya purgado.
final ReviewItem purgedItem = ReviewItem(
  rawMessageId: 'm-purged',
  channel: 'sms',
  sender: '891333',
  receivedAt: bogota(21, 9, 5),
  reason: 'parse_error',
  partialExtract: const {},
);
