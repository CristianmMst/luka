import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/features/review/domain/review_draft.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReviewDraft.fromPartialExtract', () {
    test('prellena monto, direccion, fecha y comercio', () {
      final draft = ReviewDraft.fromPartialExtract(const {
        'amount': '45900.50',
        'direction': 'debit',
        'occurred_at': '2026-09-23T10:30:00-05:00',
        'merchant': '  EXITO CALLE 80 ',
        'bank': 'bancolombia',
        'confidence': '0.4',
      });

      expect(
        draft,
        ReviewDraft(
          amount: const Cop(4590050),
          direction: TxDirection.debit,
          occurredAt: DateTime.utc(2026, 9, 23, 15, 30),
          merchant: 'EXITO CALLE 80',
        ),
      );
      expect(draft.occurredAt!.isUtc, isTrue);
    });

    test('sin partial_extract queda vacio', () {
      expect(ReviewDraft.fromPartialExtract(const {}), const ReviewDraft());
    });

    test('acepta credito, monto entero y fecha en UTC', () {
      final draft = ReviewDraft.fromPartialExtract(const {
        'amount': '45900',
        'direction': 'credit',
        'occurred_at': '2026-09-23T15:30:00Z',
      });

      expect(draft.amount, Cop.pesos(45900));
      expect(draft.direction, TxDirection.credit);
      expect(draft.occurredAt, DateTime.utc(2026, 9, 23, 15, 30));
    });

    for (final amount in ['0', '0.00', '-5', 'abc', '4.59E+4', '1.234,5']) {
      test('descarta el monto invalido "$amount"', () {
        expect(
          ReviewDraft.fromPartialExtract({'amount': amount}).amount,
          isNull,
        );
      });
    }

    for (final direction in ['DEBIT', 'in', '']) {
      test('descarta la direccion invalida "$direction"', () {
        expect(
          ReviewDraft.fromPartialExtract({'direction': direction}).direction,
          isNull,
        );
      });
    }

    for (final date in ['2026-09-23T10:30:00', '2026-09-23', 'ayer']) {
      test('descarta la fecha sin zona o invalida "$date"', () {
        expect(
          ReviewDraft.fromPartialExtract({'occurred_at': date}).occurredAt,
          isNull,
        );
      });
    }

    test('descarta el comercio vacio', () {
      expect(
        ReviewDraft.fromPartialExtract(const {'merchant': '   '}).merchant,
        isNull,
      );
    });
  });

  group('validate', () {
    final complete = ReviewDraft(
      amount: Cop.pesos(1000),
      direction: TxDirection.debit,
      occurredAt: DateTime.utc(2026, 9, 23),
    );

    test('un borrador completo no tiene errores', () {
      expect(complete.validate(), isEmpty);
      expect(complete.isValid, isTrue);
    });

    test('un borrador vacio tiene todos los errores', () {
      expect(const ReviewDraft().validate(), {
        ReviewDraftError.amountRequired,
        ReviewDraftError.directionRequired,
        ReviewDraftError.occurredAtRequired,
      });
      expect(const ReviewDraft().isValid, isFalse);
    });

    test('InvalidReviewDraft nombra los errores', () {
      expect(
        const InvalidReviewDraft({
          ReviewDraftError.directionRequired,
        }).toString(),
        contains('directionRequired'),
      );
    });

    test('el monto debe ser mayor que cero', () {
      expect(complete.copyWith(amount: const Cop(0)).validate(), {
        ReviewDraftError.amountRequired,
      });
    });
  });
}
