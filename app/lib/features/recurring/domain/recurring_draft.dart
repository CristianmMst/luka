import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';

part 'recurring_draft.freezed.dart';

/// Por qué el borrador no se puede guardar (spec 005 §10).
enum RecurringDraftError {
  nameRequired,
  nameTooLong,
  amountRequired,
  dayInvalid,
}

/// Lo que la hoja "Nuevo gasto fijo" / "Editar gasto fijo" va a enviar:
/// nombre, monto exacto y día (spec 008 §3.8). El nombre es también la
/// palabra que luka busca en el comercio del banco (spec 011 §4).
@freezed
abstract class RecurringDraft with _$RecurringDraft {
  const factory RecurringDraft({
    required String name,
    Cop? expectedAmount,
    @Default(0) int dayOfMonth,
    String? categoryId,
    String? accountId,
  }) = _RecurringDraft;

  const RecurringDraft._();

  /// Borrador para editar [expense].
  factory RecurringDraft.fromExpense(RecurringExpense expense) =>
      RecurringDraft(
        name: expense.name,
        expectedAmount: expense.expectedAmount,
        dayOfMonth: expense.dayOfMonth,
        categoryId: expense.categoryId,
        accountId: expense.accountId,
      );

  static const maxNameLength = 60;

  /// El backend exige 2 letras o números en el nombre (lo usa como palabra
  /// clave, spec 005 §10).
  static const _minAlnum = 2;

  String get cleanName =>
      name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).join(' ');

  Set<RecurringDraftError> validate() {
    final errors = <RecurringDraftError>{};
    final clean = cleanName;
    final alnum = RegExp(r'[\p{L}\p{N}]', unicode: true).allMatches(clean);
    if (alnum.length < _minAlnum) errors.add(RecurringDraftError.nameRequired);
    if (clean.length > maxNameLength) {
      errors.add(RecurringDraftError.nameTooLong);
    }
    final amount = expectedAmount;
    if (amount == null || amount.cents <= 0) {
      errors.add(RecurringDraftError.amountRequired);
    }
    if (dayOfMonth < 1 || dayOfMonth > 31) {
      errors.add(RecurringDraftError.dayInvalid);
    }
    return errors;
  }
}
