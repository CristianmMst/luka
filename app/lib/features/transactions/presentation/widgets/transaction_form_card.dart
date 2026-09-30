import 'package:flutter/material.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/theme/tokens/type_tokens.dart';
import 'package:luka/features/review/presentation/widgets/review_format.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_format.dart';

/// Tarjeta del formulario de un movimiento: monto, gasto o ingreso, fecha y
/// hora, comercio, categoría, la cuenta si hay [onPickAccount] y, si hay
/// [notes], nota. La usan "Crear movimiento" en Revisión (spec 008 §3.5) y
/// "Registrar" (§3.4). Los errores llegan ya como texto.
class TransactionFormCard extends StatelessWidget {
  const TransactionFormCard({
    required this.amount,
    required this.merchant,
    required this.direction,
    required this.occurredAt,
    required this.categoryName,
    required this.onAmountChanged,
    required this.onDirection,
    required this.onPickDate,
    required this.onPickTime,
    required this.onPickCategory,
    this.notes,
    this.accountName,
    this.onPickAccount,
    this.amountError,
    this.directionError,
    this.dateError,
    this.dateHint,
    super.key,
  });

  final TextEditingController amount;
  final TextEditingController merchant;
  final TextEditingController? notes;
  final TxDirection? direction;
  final DateTime occurredAt;
  final String? categoryName;
  final String? amountError;
  final String? directionError;
  final String? dateError;

  /// Nota bajo la fecha cuando no hay error (p. ej. "es la de recepción").
  final String? dateHint;
  final VoidCallback onAmountChanged;
  final ValueChanged<TxDirection> onDirection;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onPickCategory;

  /// Cuenta elegida (`null`: "Sin cuenta").
  final String? accountName;

  /// Abre el selector de cuenta; `null` oculta la fila (Revisión).
  final VoidCallback? onPickAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;
    final label = textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    final muted = textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
    );
    final error = textTheme.bodySmall?.copyWith(color: scheme.error);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: Radii.noticeAll,
          borderSide: BorderSide(color: color, width: width),
        );
    InputDecoration decoration({String? hint, String? errorText}) =>
        InputDecoration(
          hintText: hint,
          hintStyle: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          errorText: errorText,
          filled: true,
          fillColor: brand.tile,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: Space.sm,
          ),
          enabledBorder: border(scheme.outline),
          focusedBorder: border(scheme.primary, 2),
          errorBorder: border(scheme.error),
          focusedErrorBorder: border(scheme.error, 2),
        );
    final amountColor = switch (direction) {
      TxDirection.debit => brand.expense,
      TxDirection.credit => brand.income,
      null => scheme.onSurface,
    };
    final amountStyle = amountTextStyle.copyWith(
      fontSize: 28,
      color: amountColor,
    );
    final notes = this.notes;
    final dateError = this.dateError;
    final dateHint = this.dateHint;
    final directionError = this.directionError;

    return DecoratedBox(
      decoration: BoxDecoration(color: brand.card, borderRadius: Radii.cardAll),
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Space.xs,
          children: [
            Text(l10n.reviewAmountLabel, style: label),
            TextField(
              controller: amount,
              onChanged: (_) => onAmountChanged(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [CopInputFormatter()],
              style: amountStyle,
              decoration: decoration(errorText: amountError).copyWith(
                hintText: '0',
                hintStyle: amountStyle.copyWith(color: scheme.onSurfaceVariant),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 6),
                  child: Text(r'$', style: amountStyle),
                ),
                prefixIconConstraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(height: Space.xs),
            SegmentedButton<TxDirection>(
              segments: [
                ButtonSegment(
                  value: TxDirection.debit,
                  label: Text(l10n.detailKindExpense),
                  icon: const Icon(Icons.north_east_rounded, size: 18),
                ),
                ButtonSegment(
                  value: TxDirection.credit,
                  label: Text(l10n.detailKindIncome),
                  icon: const Icon(Icons.south_west_rounded, size: 18),
                ),
              ],
              selected: {?direction},
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) onDirection(selection.first);
              },
              style: SegmentedButton.styleFrom(
                minimumSize: const Size(0, minTouchTarget),
                selectedBackgroundColor: scheme.primaryContainer,
                selectedForegroundColor: scheme.onPrimaryContainer,
              ),
            ),
            if (directionError != null)
              Semantics(
                liveRegion: true,
                child: Text(directionError, style: error),
              ),
            const SizedBox(height: Space.xs),
            Row(
              spacing: Space.xs,
              children: [
                Expanded(
                  child: _PickerTile(
                    label: l10n.reviewDateLabel,
                    value: longDate(occurredAt),
                    onTap: onPickDate,
                  ),
                ),
                SizedBox(
                  width: 96,
                  child: _PickerTile(
                    label: l10n.reviewTimeLabel,
                    value: timeOfDay(occurredAt),
                    onTap: onPickTime,
                  ),
                ),
              ],
            ),
            if (dateError != null)
              Text(dateError, style: error)
            else if (dateHint != null)
              Text(dateHint, style: muted),
            const SizedBox(height: Space.xs),
            Text(l10n.reviewMerchantLabel, style: label),
            TextField(
              controller: merchant,
              textCapitalization: TextCapitalization.words,
              style: textTheme.bodyMedium,
              decoration: decoration(hint: l10n.reviewMerchantHint),
            ),
            const SizedBox(height: Space.xs),
            Row(
              children: [
                Expanded(child: Text(l10n.detailCategory, style: label)),
                _CategoryButton(
                  label: categoryName ?? l10n.txNoCategory,
                  onTap: onPickCategory,
                ),
              ],
            ),
            if (onPickAccount case final pickAccount?)
              Row(
                children: [
                  Expanded(child: Text(l10n.accountFieldLabel, style: label)),
                  _CategoryButton(
                    label: accountName ?? l10n.accountPickerNone,
                    semantics: l10n.reviewChangeSemantics(
                      l10n.accountFieldLabel,
                      accountName ?? l10n.accountPickerNone,
                    ),
                    onTap: pickAccount,
                  ),
                ],
              ),
            if (notes != null) ...[
              const SizedBox(height: Space.xs),
              Text(l10n.registerNotesLabel, style: label),
              TextField(
                controller: notes,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 3,
                style: textTheme.bodyMedium,
                decoration: decoration(hint: l10n.reviewMerchantHint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fecha u hora del formulario: botón de 56 dp que abre su selector.
class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: l10n.reviewChangeSemantics(label, value),
      onTap: onTap,
      child: Material(
        color: context.lukaColors.tile,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.noticeAll,
          side: BorderSide(color: scheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.sm,
                vertical: Space.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip de categoría de 36 dp en un área táctil de 48 dp; abre la hoja.
/// Chip tocable de un valor del formulario (categoría, cuenta).
class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.onTap,
    this.semantics,
  });

  final String label;
  final VoidCallback onTap;

  /// Por defecto, "Cambiar categoría: …".
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final foreground = scheme.onPrimaryContainer;

    return Semantics(
      button: true,
      container: true,
      excludeSemantics: true,
      label: semantics ?? l10n.txChangeCategorySemantics(label),
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.chipAll,
        child: SizedBox(
          height: minTouchTarget,
          child: Center(
            widthFactor: 1,
            child: Container(
              height: 36,
              padding: const EdgeInsets.only(left: Space.sm, right: Space.xs),
              decoration: BoxDecoration(
                borderRadius: Radii.chipAll,
                color: scheme.primaryContainer,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: Space.xxs,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                  Icon(Icons.expand_more_rounded, size: 16, color: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
