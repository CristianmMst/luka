import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_draft.freezed.dart';

/// Bancos que acepta el backend (`Bank`, spec 004 §2.4), en el orden del
/// selector.
const accountBanks = [
  'bancolombia',
  'nequi',
  'davivienda',
  'daviplata',
  'bbva',
  'banco_bogota',
  'other',
];

/// Tipos de cuenta (`AccountKind`, spec 004 §2.4).
const accountKinds = ['savings', 'checking', 'credit_card', 'wallet'];

enum AccountDraftError {
  /// Sin banco o uno que el backend no conoce.
  invalidBank,
  invalidKind,

  /// Los últimos dígitos no son de 1 a 4 números.
  invalidLast4,

  /// Más de [AccountDraft.maxAliasLength] caracteres.
  aliasTooLong,
}

/// Formulario de crear o editar una cuenta vinculada (spec 005 §7). Los
/// últimos 4 y el alias son opcionales: vacíos viajan como `null`.
@freezed
abstract class AccountDraft with _$AccountDraft {
  const factory AccountDraft({
    @Default('') String bank,
    @Default('savings') String kind,
    @Default('') String last4,
    @Default('') String alias,
  }) = _AccountDraft;

  const AccountDraft._();

  /// El límite de `CreateAccountRequest.alias` en el backend.
  static const maxAliasLength = 60;

  static final _last4 = RegExp(r'^[0-9]{1,4}$');

  String? get cleanLast4 => _blankToNull(last4);

  String? get cleanAlias => _blankToNull(alias);

  Set<AccountDraftError> validate() => {
    if (!accountBanks.contains(bank)) AccountDraftError.invalidBank,
    if (!accountKinds.contains(kind)) AccountDraftError.invalidKind,
    if (cleanLast4 case final digits? when !_last4.hasMatch(digits))
      AccountDraftError.invalidLast4,
    if ((cleanAlias?.length ?? 0) > maxAliasLength)
      AccountDraftError.aliasTooLong,
  };

  bool get isValid => validate().isEmpty;

  static String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
