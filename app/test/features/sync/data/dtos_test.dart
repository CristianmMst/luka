import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/features/sync/data/dtos/catalog_dtos.dart';
import 'package:finanzia/features/sync/data/dtos/review_dto.dart';
import 'package:finanzia/features/sync/data/dtos/transaction_dto.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/stub_backend.dart';

void main() {
  group('TransactionDto', () {
    test('toDomain parsea monto, fechas UTC y enums', () {
      final dto = TransactionDto.fromJson(
        transactionJson(
          amount: '152300.00',
          updatedAt: '2026-09-22T15:00:00.123456Z',
        ),
      );

      final domain = dto.toDomain();

      expect(domain.amount, const Cop(15230000));
      expect(domain.occurredAt.isUtc, isTrue);
      expect(domain.occurredAt, DateTime.utc(2026, 9, 22, 15));
      expect(domain.updatedAt.isUtc, isTrue);
      expect(domain.updatedAt, DateTime.utc(2026, 9, 22, 15, 0, 0, 123, 456));
      expect(domain.direction, TxDirection.debit);
      expect(domain.kind, TxKind.expense);
      expect(domain.merchant, 'Éxito');
    });

    test('direction desconocida lanza error', () {
      final dto = TransactionDto.fromJson(
        transactionJson(direction: 'bizarro'),
      );

      expect(dto.toDomain, throwsArgumentError);
    });

    test('kind desconocido lanza error', () {
      final dto = TransactionDto.fromJson(transactionJson(kind: 'bizarro'));

      expect(dto.toDomain, throwsArgumentError);
    });

    test('channels parsea la lista en el orden recibido', () {
      final dto = TransactionDto.fromJson(
        transactionJson(channels: ['email', 'manual']),
      );

      expect(dto.toDomain().channels, ['email', 'manual']);
    });

    test('channels ausente es lista vacia (compatibilidad)', () {
      final json = transactionJson()..remove('channels');
      final dto = TransactionDto.fromJson(json);

      expect(dto.toDomain().channels, isEmpty);
    });
  });

  group('TransactionPageDto', () {
    test('parsea items y next_cursor', () {
      final page = TransactionPageDto.fromJson({
        'items': [transactionJson(id: 't1')],
        'next_cursor': 'abc',
      });

      expect(page.items, hasLength(1));
      expect(page.items.single.id, 't1');
      expect(page.nextCursor, 'abc');
    });

    test('next_cursor ausente es null', () {
      final page = TransactionPageDto.fromJson({
        'items': <Object?>[],
        'next_cursor': null,
      });

      expect(page.items, isEmpty);
      expect(page.nextCursor, isNull);
    });
  });

  group('CategoryDto', () {
    test('toDomain', () {
      final dto = CategoryDto.fromJson({
        'id': 'c1',
        'user_id': null,
        'slug': 'comida',
        'name': 'Comida',
        'icon': null,
        'color': null,
        'fiscal_tag': 'deducible',
        'is_system': true,
      });

      final domain = dto.toDomain();

      expect(domain.id, 'c1');
      expect(domain.slug, 'comida');
      expect(domain.isSystem, isTrue);
    });
  });

  group('AccountDto', () {
    test('toDomain', () {
      final dto = AccountDto.fromJson({
        'id': 'a1',
        'bank': 'bancolombia',
        'kind': 'debito',
        'last4': '1234',
        'alias': null,
      });

      final domain = dto.toDomain();

      expect(domain.id, 'a1');
      expect(domain.bank, 'bancolombia');
      expect(domain.last4, '1234');
      expect(domain.alias, isNull);
    });
  });

  group('ReviewEntryDto', () {
    test('toDomain con partial_extract', () {
      final dto = ReviewEntryDto.fromJson({
        'raw_message_id': 'r1',
        'channel': 'sms',
        'bank': 'bancolombia',
        'sender': '85555',
        'received_at': '2026-09-22T15:00:00Z',
        'reason': 'sin_categoria',
        'partial_extract': {'amount': '45000'},
        'text': 'texto',
        'created_at': '2026-09-22T15:00:00Z',
      });

      final domain = dto.toDomain();

      expect(domain.rawMessageId, 'r1');
      expect(domain.partialExtract, {'amount': '45000'});
      expect(domain.receivedAt, DateTime.utc(2026, 9, 22, 15));
    });
  });

  group('TransactionSourceDto', () {
    test('toDomain parsea channel y received_at en UTC', () {
      final dto = TransactionSourceDto.fromJson({
        'id': 's1',
        'channel': 'sms_notification',
        'raw_message_id': 'm1',
        'received_at': '2026-09-22T15:00:00Z',
      });

      final domain = dto.toDomain();

      expect(domain.channel, 'sms_notification');
      expect(domain.receivedAt.isUtc, isTrue);
      expect(domain.receivedAt, DateTime.utc(2026, 9, 22, 15));
    });
  });

  group('TransactionDetailDto', () {
    test('parsea la transaccion y sus sources', () {
      final dto = TransactionDetailDto.fromJson({
        ...transactionJson(id: 't1', channels: ['email', 'manual']),
        'sources': [
          {
            'id': 's1',
            'channel': 'email',
            'raw_message_id': 'm1',
            'received_at': '2026-09-22T15:00:00Z',
          },
          {
            'id': 's2',
            'channel': 'manual',
            'raw_message_id': null,
            'received_at': '2026-09-22T16:00:00Z',
          },
        ],
        'pair': null,
      });

      expect(dto.transaction.id, 't1');
      expect(dto.transaction.toDomain().channels, ['email', 'manual']);
      expect(dto.sources, hasLength(2));
      expect(dto.sources.first.toDomain().channel, 'email');
      expect(dto.sources.last.toDomain().channel, 'manual');
      expect(dto.pair, isNull);
    });

    test('pair presente se guarda sin tipar', () {
      final dto = TransactionDetailDto.fromJson({
        ...transactionJson(id: 't1'),
        'sources': <Object?>[],
        'pair': {'id': 'p1'},
      });

      expect(dto.sources, isEmpty);
      expect(dto.pair, {'id': 'p1'});
    });
  });

  group('ReviewPageDto', () {
    test('parsea items y next_cursor', () {
      final page = ReviewPageDto.fromJson({
        'items': [
          {
            'raw_message_id': 'r1',
            'channel': 'sms',
            'bank': null,
            'sender': '85555',
            'received_at': '2026-09-22T15:00:00Z',
            'reason': 'sin_categoria',
            'partial_extract': <String, String>{},
            'text': null,
            'created_at': '2026-09-22T15:00:00Z',
          },
        ],
        'next_cursor': null,
      });

      expect(page.items, hasLength(1));
      expect(page.items.single.rawMessageId, 'r1');
      expect(page.nextCursor, isNull);
    });
  });
}
