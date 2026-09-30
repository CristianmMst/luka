import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/accounts/domain/account_draft.dart';

void main() {
  test('solo el banco es obligatorio', () {
    expect(const AccountDraft(bank: 'nequi').validate(), isEmpty);
    expect(const AccountDraft().validate(), {AccountDraftError.invalidBank});
    expect(
      const AccountDraft(bank: 'banco_x').validate(),
      {AccountDraftError.invalidBank},
    );
  });

  test('el tipo debe ser uno del backend', () {
    expect(
      const AccountDraft(bank: 'nequi', kind: 'cdt').validate(),
      {AccountDraftError.invalidKind},
    );
    for (final kind in accountKinds) {
      expect(AccountDraft(bank: 'bbva', kind: kind).isValid, isTrue);
    }
  });

  test('los últimos dígitos son de 1 a 4 números', () {
    for (final ok in ['1', '12', '1234', ' 4821 ', '']) {
      expect(
        AccountDraft(bank: 'bancolombia', last4: ok).isValid,
        isTrue,
        reason: ok,
      );
    }
    for (final bad in ['12345', '12a4', '-123', '12 3']) {
      expect(
        AccountDraft(bank: 'bancolombia', last4: bad).validate(),
        {AccountDraftError.invalidLast4},
        reason: bad,
      );
    }
  });

  test('el alias admite hasta 60 caracteres sin contar espacios de borde', () {
    final max = 'a' * AccountDraft.maxAliasLength;
    expect(AccountDraft(bank: 'nequi', alias: '  $max  ').isValid, isTrue);
    expect(
      AccountDraft(bank: 'nequi', alias: '${max}b').validate(),
      {AccountDraftError.aliasTooLong},
    );
  });

  test('vacíos se envían como null y lo demás recortado', () {
    const blank = AccountDraft(bank: 'nequi', last4: '  ', alias: ' ');
    expect(blank.cleanLast4, isNull);
    expect(blank.cleanAlias, isNull);

    const filled = AccountDraft(
      bank: 'nequi',
      last4: ' 98 ',
      alias: ' Nómina ',
    );
    expect(filled.cleanLast4, '98');
    expect(filled.cleanAlias, 'Nómina');
  });
}
