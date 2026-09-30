import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_format.dart';

TransactionView _view({
  String? bank,
  String? kind,
  String? last4,
  String? alias,
}) => TransactionView(
  id: 'tx',
  amount: Cop.pesos(1000),
  direction: TxDirection.debit,
  kind: TxKind.expense,
  occurredAt: DateTime.utc(2026, 9, 23),
  channels: const {},
  sync: SyncMark.none,
  accountBank: bank,
  accountKind: kind,
  accountLast4: last4,
  accountAlias: alias,
);

void main() {
  final l10n = lookupAppLocalizations(const Locale('es'));

  group('accountLabel', () {
    test('banco, tipo y últimos 4', () {
      expect(
        accountLabel(
          l10n,
          _view(bank: 'bancolombia', kind: 'savings', last4: '4821'),
        ),
        'Bancolombia ahorros ···4821',
      );
    });

    test('cada tipo de cuenta sale del arb', () {
      String label(String kind) =>
          accountLabel(l10n, _view(bank: 'nequi', kind: kind))!;
      expect(label('savings'), 'Nequi ahorros');
      expect(label('checking'), 'Nequi corriente');
      expect(label('credit_card'), 'Nequi tarjeta de crédito');
      expect(label('wallet'), 'Nequi billetera');
    });

    test('sin últimos 4 no lleva sufijo', () {
      expect(
        accountLabel(l10n, _view(bank: 'bbva', kind: 'checking', last4: '')),
        'BBVA corriente',
      );
    });

    test('banco y tipo desconocidos se muestran legibles', () {
      expect(
        accountLabel(l10n, _view(bank: 'banco_x', kind: 'cdt_digital')),
        'Banco x cdt digital',
      );
    });

    test('sin cuenta vinculada es null', () {
      expect(accountLabel(l10n, _view()), isNull);
    });
  });
}
