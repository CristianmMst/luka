import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/sync/domain/outbox_operation.dart';
import 'package:luka/features/sync/domain/sync_rules.dart';
import 'package:luka/features/sync/domain/synced_models.dart';

void main() {
  final t0 = DateTime.utc(2026, 9, 22, 10);
  final t1 = t0.add(const Duration(minutes: 1));
  const delete = OutboxOperation.deleteTransaction(id: 't');
  const discard = OutboxOperation.discardReview(rawMessageId: 'r');
  const pair = OutboxOperation.setTransferPair(id: 't', pairId: 'u');

  group('shouldApplyRemote', () {
    test('sin fila local, aplica', () {
      expect(shouldApplyRemote(local: null, remoteUpdatedAt: t0), isTrue);
    });
    test('edición local pendiente gana aunque el servidor sea más nuevo', () {
      expect(
        shouldApplyRemote(
          local: (updatedAt: t0, pendingPush: true),
          remoteUpdatedAt: t1,
        ),
        isFalse,
      );
    });
    test('gana el updated_at más reciente; empate aplica (borde >=)', () {
      expect(
        shouldApplyRemote(
          local: (updatedAt: t1, pendingPush: false),
          remoteUpdatedAt: t0,
        ),
        isFalse,
      );
      expect(
        shouldApplyRemote(
          local: (updatedAt: t0, pendingPush: false),
          remoteUpdatedAt: t0,
        ),
        isTrue,
      );
      expect(
        shouldApplyRemote(
          local: (updatedAt: t0, pendingPush: false),
          remoteUpdatedAt: t1,
        ),
        isTrue,
      );
    });
  });

  group('classifyPushFailure', () {
    test('red, 5xx y 429 se reintentan', () {
      expect(
        classifyPushFailure(pair, const RemoteFailure.network()),
        PushOutcome.retryLater,
      );
      expect(
        classifyPushFailure(pair, const RemoteFailure(statusCode: 503)),
        PushOutcome.retryLater,
      );
      expect(
        classifyPushFailure(pair, const RemoteFailure(statusCode: 429)),
        PushOutcome.retryLater,
      );
    });
    test('401 termina el ciclo', () {
      expect(
        classifyPushFailure(pair, const RemoteFailure(statusCode: 401)),
        PushOutcome.sessionEnded,
      );
    });
    test(
      '409 con Retry-After (idempotencia en curso) se reintenta; sin él se '
      'rechaza',
      () {
        expect(
          classifyPushFailure(
            pair,
            const RemoteFailure(
              statusCode: 409,
              retryAfter: Duration(seconds: 1),
            ),
          ),
          PushOutcome.retryLater,
        );
        expect(
          classifyPushFailure(pair, const RemoteFailure(statusCode: 409)),
          PushOutcome.rejected,
        );
      },
    );
    test(
      'borrar algo que ya no existe o descartar algo ya resuelto cuenta '
      'como hecho',
      () {
        expect(
          classifyPushFailure(delete, const RemoteFailure(statusCode: 404)),
          PushOutcome.done,
        );
        expect(
          classifyPushFailure(discard, const RemoteFailure(statusCode: 409)),
          PushOutcome.done,
        );
      },
    );
    test(
      'convertir una revisión ya resuelta (409) o inexistente (404) cuenta '
      'como hecho',
      () {
        final convert = OutboxOperation.convertReview(
          rawMessageId: 'r',
          localId: 'l',
          data: NewTransaction(
            amount: Cop.pesos(1000),
            direction: TxDirection.debit,
            occurredAt: t0,
          ),
        );
        for (final status in [404, 409]) {
          expect(
            classifyPushFailure(convert, RemoteFailure(statusCode: status)),
            PushOutcome.done,
          );
        }
        expect(
          classifyPushFailure(convert, const RemoteFailure(statusCode: 422)),
          PushOutcome.rejected,
        );
      },
    );
    test('otros 4xx se rechazan para resolución manual', () {
      expect(
        classifyPushFailure(pair, const RemoteFailure(statusCode: 400)),
        PushOutcome.rejected,
      );
      expect(
        classifyPushFailure(pair, const RemoteFailure(statusCode: 403)),
        PushOutcome.rejected,
      );
    });
  });

  group('resolveFiscalTag', () {
    test('una transferencia es siempre transferencia', () {
      expect(
        resolveFiscalTag(TxKind.transfer, 'no_deducible'),
        'transferencia',
      );
      expect(resolveFiscalTag(TxKind.transfer, null), 'transferencia');
    });
    test('un gasto o ingreso toma la etiqueta de su categoría', () {
      expect(resolveFiscalTag(TxKind.expense, 'salud'), 'salud');
      expect(resolveFiscalTag(TxKind.income, 'no_deducible'), 'no_deducible');
    });
    test('sin la categoría en local no hay etiqueta', () {
      expect(resolveFiscalTag(TxKind.expense, null), isNull);
    });
  });
}
