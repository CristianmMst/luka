import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/features/transactions/application/transaction_actions.dart';
import 'package:finanzia/features/transactions/domain/transaction_view.dart';
import 'package:finanzia/features/transactions/presentation/widgets/category_sheet.dart';
import 'package:finanzia/features/transactions/presentation/widgets/merchant_rule_dialog.dart';
import 'package:finanzia/features/transactions/presentation/widgets/transaction_format.dart';
import 'package:flutter/material.dart';

/// Cambio de categoría de la lista y del detalle: abre la hoja y, si hay
/// comercio, pregunta "¿Aplicar siempre a {comercio}?" (AC-7.2). Cerrar la
/// hoja o el diálogo no cambia nada.
Future<void> changeCategory(
  BuildContext context,
  TransactionActions actions,
  TransactionView tx,
) async {
  final l10n = AppLocalizations.of(context);
  final choice = await CategorySheet.show(
    context,
    selectedId: tx.categoryId,
    subtitle: l10n.categorySheetSubtitle(
      displayName(l10n, tx),
      listAmount(tx.amount, tx.kind),
    ),
  );
  final id = choice?.id;
  if (id == null || id == tx.categoryId || !context.mounted) return;
  var always = false;
  if (hasMerchant(tx)) {
    final answer = await MerchantRuleDialog.show(
      context,
      merchant: tx.merchant!.trim(),
      categoryName: choice?.name ?? '',
    );
    if (answer == null) return;
    always = answer;
  }
  await actions.changeCategory(tx, id, always: always);
}
