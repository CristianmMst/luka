import 'package:flutter/material.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/review/presentation/widgets/review_format.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_format.dart';

/// Color de un tipo en Registrar (diseño Y2): tomate el gasto, verde el
/// ingreso; `onAccent` es la tinta que se lee sobre él.
({Color accent, Color onAccent}) kindColors(
  BuildContext context,
  TxDirection? direction,
) {
  final accent = switch (direction) {
    TxDirection.debit => Theme.of(context).colorScheme.primary,
    TxDirection.credit => context.lukaColors.income,
    // Sin elegir (un mensaje en Revisión): neutro.
    null => Theme.of(context).colorScheme.onSurfaceVariant,
  };
  final onAccent =
      ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
      ? Colors.white
      : const Color(0xFF1C0F0C);
  return (accent: accent, onAccent: onAccent);
}

/// Interruptor grande Gasto / Ingreso: la perilla se desliza y toma el
/// color del tipo. Cada lado es un botón con su estado "seleccionado". Sin
/// [direction] no hay perilla: ninguno está elegido.
class KindSwitch extends StatelessWidget {
  const KindSwitch({
    required this.direction,
    required this.onChanged,
    super.key,
  });

  final TxDirection? direction;
  final ValueChanged<TxDirection> onChanged;

  static const height = 56.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final scheme = Theme.of(context).colorScheme;
    final (:accent, :onAccent) = kindColors(context, direction);
    final instant = MediaQuery.disableAnimationsOf(context);
    final expense = direction == TxDirection.debit;

    Widget side(TxDirection value, IconData icon, String label) {
      final selected = value == direction;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          excludeSemantics: true,
          label: label,
          onTap: () => onChanged(value),
          child: InkWell(
            onTap: () => onChanged(value),
            borderRadius: Radii.pillAll,
            child: AnimatedDefaultTextStyle(
              duration: instant
                  ? Duration.zero
                  : const Duration(milliseconds: 150),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w800,
                color: selected ? onAccent : scheme.onSurfaceVariant,
              ),
              child: Builder(
                builder: (context) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 6,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: DefaultTextStyle.of(context).style.color,
                    ),
                    Text(label),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: l10n.registerKindGroup,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: brand.neutralChip,
          borderRadius: Radii.pillAll,
        ),
        child: Stack(
          children: [
            if (direction != null)
              AnimatedAlign(
                duration: instant
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                curve: const Cubic(0.23, 1, 0.32, 1),
                alignment: expense
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1,
                  child: AnimatedContainer(
                    duration: instant
                        ? Duration.zero
                        : const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: Radii.pillAll,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x332A1210),
                          blurRadius: 14,
                          spreadRadius: -6,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Row(
                // Cada lado ocupa todo el alto: área táctil de 48 dp o más.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  side(
                    TxDirection.debit,
                    Icons.south_rounded,
                    l10n.detailKindExpense,
                  ),
                  side(
                    TxDirection.credit,
                    Icons.north_rounded,
                    l10n.detailKindIncome,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El monto grande con el signo del tipo ("−$" o "+$") y la pregunta
/// ("¿Cuánto gastaste?" / "¿Cuánto recibiste?"); sin tipo, "$" y
/// "¿Cuánto fue?".
class AmountField extends StatelessWidget {
  const AmountField({
    required this.controller,
    required this.direction,
    required this.onChanged,
    this.error,
    super.key,
  });

  final TextEditingController controller;
  final TxDirection? direction;
  final VoidCallback onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final (:accent, onAccent: _) = kindColors(context, direction);
    final style = textTheme.displayLarge?.copyWith(
      fontSize: 56,
      height: 1.1,
      letterSpacing: -2.4,
      color: switch (direction) {
        TxDirection.debit => brand.expense,
        TxDirection.credit => brand.income,
        null => scheme.onSurface,
      },
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    UnderlineInputBorder line(Color color) =>
        UnderlineInputBorder(borderSide: BorderSide(color: color, width: 2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Space.xxs,
      children: [
        Text(
          switch (direction) {
            TxDirection.debit => l10n.registerAmountExpense,
            TxDirection.credit => l10n.registerAmountIncome,
            null => l10n.registerAmountUnknown,
          },
          style: textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [CopInputFormatter()],
          cursorColor: accent,
          style: style,
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: style?.copyWith(color: scheme.outlineVariant),
            errorText: error,
            prefixIcon: Text(switch (direction) {
              TxDirection.debit => r'−$',
              TxDirection.credit => r'+$',
              null => r'$',
            }, style: style),
            prefixIconConstraints: const BoxConstraints(),
            contentPadding: const EdgeInsets.only(bottom: Space.xs),
            enabledBorder: line(accent),
            focusedBorder: line(accent),
            errorBorder: line(scheme.error),
            focusedErrorBorder: line(scheme.error),
          ),
        ),
      ],
    );
  }
}

/// La categoría elegida en una fila destacada con el color del tipo;
/// tocarla abre la hoja con buscador.
class CategoryField extends StatelessWidget {
  const CategoryField({
    required this.name,
    required this.icon,
    required this.direction,
    required this.onTap,
    super.key,
  });

  final String name;
  final IconData icon;
  final TxDirection? direction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final (:accent, :onAccent) = kindColors(context, direction);

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: l10n.txChangeCategorySemantics(name),
      onTap: onTap,
      child: Material(
        color: accent.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accent, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                spacing: Space.sm,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, size: 20, color: onAccent),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.detailCategory,
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.registerCategoryChange,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fecha y hora, comercio, cuenta y nota como filas en una tarjeta con
/// borde fino. Comercio y nota se escriben en la fila misma. Sin [notes] o
/// sin [onPickAccount] esas filas no se muestran (Revisión).
class RegistrarDetails extends StatelessWidget {
  const RegistrarDetails({
    required this.occurredAt,
    required this.now,
    required this.merchant,
    required this.onPickDate,
    required this.onPickTime,
    this.notes,
    this.accountName,
    this.onPickAccount,
    this.dateNote,
    this.dateNoteIsError = false,
    super.key,
  });

  final DateTime occurredAt;

  /// "Ahora" del reloj de la app: la fecha de hoy o ayer se dice así.
  final DateTime now;
  final TextEditingController merchant;
  final TextEditingController? notes;
  final String? accountName;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback? onPickAccount;

  /// Nota bajo la fecha ("es la de recepción") o su error.
  final String? dateNote;
  final bool dateNoteIsError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;
    final account = accountName ?? l10n.accountPickerNone;
    final date = _relativeDay(l10n);
    final divider = Divider(height: 1, thickness: 1, color: brand.hairline);

    return Material(
      color: brand.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: brand.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _Row(
            icon: Icons.calendar_today_outlined,
            label: l10n.registerDateTimeLabel,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: Space.xxs,
              children: [
                Flexible(
                  child: _ValueButton(
                    text: date,
                    semantics: l10n.reviewChangeSemantics(
                      l10n.reviewDateLabel,
                      longDate(occurredAt),
                    ),
                    onTap: onPickDate,
                  ),
                ),
                _ValueButton(
                  text: timeOfDay(occurredAt),
                  semantics: l10n.reviewChangeSemantics(
                    l10n.reviewTimeLabel,
                    timeOfDay(occurredAt),
                  ),
                  onTap: onPickTime,
                ),
              ],
            ),
          ),
          if (dateNote case final note?)
            Padding(
              padding: const EdgeInsets.fromLTRB(60, 0, 14, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  liveRegion: dateNoteIsError,
                  child: Text(
                    note,
                    style: textTheme.bodySmall?.copyWith(
                      color: dateNoteIsError
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          divider,
          _Row(
            icon: Icons.storefront_outlined,
            label: l10n.reviewMerchantLabel,
            child: _InlineField(
              controller: merchant,
              hint: l10n.reviewMerchantHint,
              label: l10n.reviewMerchantLabel,
              capitalization: TextCapitalization.words,
            ),
          ),
          if (onPickAccount case final pickAccount?) ...[
            divider,
            Semantics(
              button: true,
              excludeSemantics: true,
              label: l10n.reviewChangeSemantics(
                l10n.accountFieldLabel,
                account,
              ),
              onTap: pickAccount,
              child: InkWell(
                onTap: pickAccount,
                child: _Row(
                  icon: Icons.account_balance_outlined,
                  label: l10n.accountFieldLabel,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          account,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (notes case final notes?) ...[
            divider,
            _Row(
              icon: Icons.notes_rounded,
              label: l10n.registerNotesLabel,
              child: _InlineField(
                controller: notes,
                hint: l10n.registerNotesHint,
                label: l10n.registerNotesLabel,
                capitalization: TextCapitalization.sentences,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

extension on RegistrarDetails {
  /// "Hoy", "Ayer" o "25 sep", en días de Colombia.
  String _relativeDay(AppLocalizations l10n) {
    final day = colombiaLocal(occurredAt);
    final today = colombiaLocal(now);
    final days = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(day.year, day.month, day.day)).inDays;
    return switch (days) {
      0 => l10n.dayToday,
      1 => l10n.dayYesterday,
      _ => shortDate(occurredAt),
    };
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.child});

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brand = context.lukaColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          spacing: Space.sm,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: brand.neutralChip,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: scheme.onSurfaceVariant),
            ),
            // La etiqueta tiene tope: con letra grande se recorta y el valor
            // nunca queda sin ancho.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: ExcludeSemantics(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(alignment: Alignment.centerRight, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueButton extends StatelessWidget {
  const _ValueButton({
    required this.text,
    required this.semantics,
    required this.onTap,
  });

  final String text;
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: semantics,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.chipAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Center(
              widthFactor: 1,
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.controller,
    required this.hint,
    required this.label,
    required this.capitalization,
  });

  final TextEditingController controller;
  final String hint;
  final String label;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    return Semantics(
      label: label,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.end,
        textCapitalization: capitalization,
        style: style,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: style?.copyWith(
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
