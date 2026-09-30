import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';

part 'recurring_draft.freezed.dart';

/// Por qué el borrador no se puede guardar (spec 005 §10).
enum RecurringDraftError {
  nameRequired,
  nameTooLong,
  keywordInvalid,
  amountRequired,
  dayInvalid,
}

/// Márgenes de monto que ofrece la hoja (spec 008 §3.8).
const toleranceChoices = [0, 5, 10, 20, 50];

/// Lo que la hoja "Nuevo gasto fijo" / "Editar gasto fijo" va a enviar.
@freezed
abstract class RecurringDraft with _$RecurringDraft {
  const factory RecurringDraft({
    required String name,
    required String merchantKeyword,
    Cop? expectedAmount,
    @Default(0) int dayOfMonth,
    @Default(10) int tolerancePct,
    @Default(1) int remindDaysBefore,
    String? categoryId,
    String? accountId,
  }) = _RecurringDraft;

  const RecurringDraft._();

  /// Borrador para editar [expense].
  factory RecurringDraft.fromExpense(RecurringExpense expense) =>
      RecurringDraft(
        name: expense.name,
        merchantKeyword: expense.merchantKeyword,
        expectedAmount: expense.expectedAmount,
        dayOfMonth: expense.dayOfMonth,
        tolerancePct: expense.tolerancePct,
        remindDaysBefore: expense.remindDaysBefore,
        categoryId: expense.categoryId,
        accountId: expense.accountId,
      );

  static const maxNameLength = 60;
  static const minKeywordLength = 2;
  static const maxKeywordLength = 40;

  String get cleanName => _collapse(name);
  String get cleanKeyword => _collapse(merchantKeyword);

  Set<RecurringDraftError> validate() {
    final errors = <RecurringDraftError>{};
    if (cleanName.isEmpty) errors.add(RecurringDraftError.nameRequired);
    if (cleanName.length > maxNameLength) {
      errors.add(RecurringDraftError.nameTooLong);
    }
    final keyword = cleanKeyword;
    final alnum = RegExp(r'[\p{L}\p{N}]', unicode: true).allMatches(keyword);
    if (keyword.length < minKeywordLength ||
        keyword.length > maxKeywordLength ||
        alnum.length < minKeywordLength) {
      errors.add(RecurringDraftError.keywordInvalid);
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

  static String _collapse(String value) =>
      value.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).join(' ');
}
