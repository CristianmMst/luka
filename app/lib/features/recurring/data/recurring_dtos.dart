import 'package:json_annotation/json_annotation.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';

part 'recurring_dtos.g.dart';

/// `RecurringExpenseResponse` (spec 005 §10).
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class RecurringExpenseDto {
  const RecurringExpenseDto({
    required this.id,
    required this.name,
    required this.merchantKeyword,
    required this.expectedAmount,
    required this.amountTolerancePct,
    required this.dayOfMonth,
    required this.remindDaysBefore,
    required this.active,
    this.categoryId,
    this.accountId,
  });

  factory RecurringExpenseDto.fromJson(Map<String, dynamic> json) =>
      _$RecurringExpenseDtoFromJson(json);

  final String id;
  final String name;
  final String merchantKeyword;
  final String expectedAmount;
  final int amountTolerancePct;
  final int dayOfMonth;
  final int remindDaysBefore;
  final bool active;
  final String? categoryId;
  final String? accountId;

  RecurringExpense toDomain() => RecurringExpense(
    id: id,
    name: name,
    merchantKeyword: merchantKeyword,
    expectedAmount: Cop.parse(expectedAmount),
    tolerancePct: amountTolerancePct,
    dayOfMonth: dayOfMonth,
    remindDaysBefore: remindDaysBefore,
    active: active,
    categoryId: categoryId,
    accountId: accountId,
  );
}

/// El gasto fijo embebido en una ocurrencia.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class OccurrenceExpenseDto {
  const OccurrenceExpenseDto({
    required this.id,
    required this.name,
    required this.expectedAmount,
    this.categoryId,
  });

  factory OccurrenceExpenseDto.fromJson(Map<String, dynamic> json) =>
      _$OccurrenceExpenseDtoFromJson(json);

  final String id;
  final String name;
  final String expectedAmount;
  final String? categoryId;
}

/// El movimiento que pagó la ocurrencia.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class OccurrenceTransactionDto {
  const OccurrenceTransactionDto({
    required this.id,
    required this.amount,
    required this.occurredAt,
    this.merchant,
  });

  factory OccurrenceTransactionDto.fromJson(Map<String, dynamic> json) =>
      _$OccurrenceTransactionDtoFromJson(json);

  final String id;
  final String amount;
  final DateTime occurredAt;
  final String? merchant;
}

/// `OccurrenceResponse` (spec 005 §10).
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class OccurrenceDto {
  const OccurrenceDto({
    required this.id,
    required this.recurringExpense,
    required this.period,
    required this.dueDate,
    required this.status,
    this.matchedBy,
    this.paidAt,
    this.transaction,
  });

  factory OccurrenceDto.fromJson(Map<String, dynamic> json) =>
      _$OccurrenceDtoFromJson(json);

  final String id;
  final OccurrenceExpenseDto recurringExpense;
  final String period;
  final String dueDate;
  final String status;
  final String? matchedBy;
  final DateTime? paidAt;
  final OccurrenceTransactionDto? transaction;

  RecurringOccurrence toDomain() {
    final due = DateTime.parse(dueDate);
    return RecurringOccurrence(
      id: id,
      expenseId: recurringExpense.id,
      name: recurringExpense.name,
      expectedAmount: Cop.parse(recurringExpense.expectedAmount),
      categoryId: recurringExpense.categoryId,
      period: period,
      dueDate: DateTime.utc(due.year, due.month, due.day),
      status: OccurrenceStatus.fromWire(status),
      matchedBy: matchedBy,
      paidAt: paidAt,
      transactionId: transaction?.id,
      transactionMerchant: transaction?.merchant,
      transactionAmount: switch (transaction?.amount) {
        final amount? => Cop.parse(amount),
        null => null,
      },
      transactionOccurredAt: transaction?.occurredAt,
    );
  }
}
