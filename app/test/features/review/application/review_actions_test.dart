import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/review/application/review_actions.dart';
import 'package:luka/features/review/domain/review_draft.dart';
import 'package:luka/features/review/domain/review_item.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/sync/domain/outbox_operation.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:mocktail/mocktail.dart';

class _Coordinator extends Mock implements SyncCoordinator {}

class _IdleCoordinator extends SyncCoordinator {
  @override
  SyncStatus build() => const SyncStatus();
}

final _item = ReviewItem(
  rawMessageId: 'raw-1',
  channel: 'email',
  sender: 'alertas@banco.co',
  receivedAt: DateTime.utc(2026, 9, 23, 15),
  reason: 'llm_low_confidence',
  partialExtract: const {},
  text: r'Compra por $45.900',
);

void main() {
  late _Coordinator coordinator;
  late ReviewActions actions;

  setUpAll(() {
    registerFallbackValue(
      const OutboxOperation.discardReview(rawMessageId: 'f'),
    );
  });

  setUp(() {
    coordinator = _Coordinator();
    actions = ReviewActions(coordinator);
    when(() => coordinator.enqueue(any())).thenAnswer((_) async {});
    when(() => coordinator.newLocalId()).thenReturn('local-1');
  });

  group('convert', () {
    test('encola la conversion con un id local y el borrador', () async {
      // La fecha del formulario llega en hora local; el wire la pasa a UTC.
      final occurredAt = DateTime(2026, 9, 23, 10, 30);
      await actions.convert(
        _item,
        ReviewDraft(
          amount: Cop.pesos(45900),
          direction: TxDirection.debit,
          occurredAt: occurredAt,
          merchant: '  EXITO ',
          categoryId: 'cat-1',
        ),
      );

      verify(
        () => coordinator.enqueue(
          OutboxOperation.convertReview(
            rawMessageId: 'raw-1',
            localId: 'local-1',
            data: NewTransaction(
              amount: Cop.pesos(45900),
              direction: TxDirection.debit,
              occurredAt: occurredAt,
              merchant: 'EXITO',
              categoryId: 'cat-1',
            ),
          ),
        ),
      ).called(1);
    });

    test('sin comercio ni categoria no los envia', () async {
      final occurredAt = DateTime.utc(2026, 9, 23);
      await actions.convert(
        _item,
        ReviewDraft(
          amount: Cop.pesos(10),
          direction: TxDirection.credit,
          occurredAt: occurredAt,
          merchant: '   ',
        ),
      );

      verify(
        () => coordinator.enqueue(
          OutboxOperation.convertReview(
            rawMessageId: 'raw-1',
            localId: 'local-1',
            data: NewTransaction(
              amount: Cop.pesos(10),
              direction: TxDirection.credit,
              occurredAt: occurredAt,
            ),
          ),
        ),
      ).called(1);
    });

    test('un borrador invalido no se encola', () async {
      await expectLater(
        actions.convert(
          _item,
          ReviewDraft(
            amount: const Cop(0),
            occurredAt: DateTime.utc(2026, 9, 23),
          ),
        ),
        throwsA(
          isA<InvalidReviewDraft>().having((e) => e.errors, 'errors', {
            ReviewDraftError.amountRequired,
            ReviewDraftError.directionRequired,
          }),
        ),
      );

      verifyNever(() => coordinator.enqueue(any()));
      verifyNever(() => coordinator.newLocalId());
    });
  });

  test('discard encola el descarte del mensaje', () async {
    await actions.discard(_item);

    verify(
      () => coordinator.enqueue(
        const OutboxOperation.discardReview(rawMessageId: 'raw-1'),
      ),
    ).called(1);
  });

  test('el provider usa el coordinador de sync', () {
    final container = ProviderContainer(
      overrides: [syncCoordinatorProvider.overrideWith(_IdleCoordinator.new)],
    );
    addTearDown(container.dispose);

    expect(container.read(reviewActionsProvider), isA<ReviewActions>());
  });
}
