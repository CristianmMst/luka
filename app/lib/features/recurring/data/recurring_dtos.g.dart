// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringExpenseDto _$RecurringExpenseDtoFromJson(Map<String, dynamic> json) =>
    RecurringExpenseDto(
      id: json['id'] as String,
      name: json['name'] as String,
      merchantKeyword: json['merchant_keyword'] as String,
      expectedAmount: json['expected_amount'] as String,
      amountTolerancePct: (json['amount_tolerance_pct'] as num).toInt(),
      dayOfMonth: (json['day_of_month'] as num).toInt(),
      remindDaysBefore: (json['remind_days_before'] as num).toInt(),
      active: json['active'] as bool,
      categoryId: json['category_id'] as String?,
      accountId: json['account_id'] as String?,
    );

OccurrenceExpenseDto _$OccurrenceExpenseDtoFromJson(
  Map<String, dynamic> json,
) => OccurrenceExpenseDto(
  id: json['id'] as String,
  name: json['name'] as String,
  expectedAmount: json['expected_amount'] as String,
  categoryId: json['category_id'] as String?,
);

OccurrenceTransactionDto _$OccurrenceTransactionDtoFromJson(
  Map<String, dynamic> json,
) => OccurrenceTransactionDto(
  id: json['id'] as String,
  amount: json['amount'] as String,
  occurredAt: DateTime.parse(json['occurred_at'] as String),
  merchant: json['merchant'] as String?,
);

OccurrenceDto _$OccurrenceDtoFromJson(Map<String, dynamic> json) =>
    OccurrenceDto(
      id: json['id'] as String,
      recurringExpense: OccurrenceExpenseDto.fromJson(
        json['recurring_expense'] as Map<String, dynamic>,
      ),
      period: json['period'] as String,
      dueDate: json['due_date'] as String,
      status: json['status'] as String,
      matchedBy: json['matched_by'] as String?,
      paidAt: json['paid_at'] == null
          ? null
          : DateTime.parse(json['paid_at'] as String),
      transaction: json['transaction'] == null
          ? null
          : OccurrenceTransactionDto.fromJson(
              json['transaction'] as Map<String, dynamic>,
            ),
    );
