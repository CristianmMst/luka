import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/theme/tokens/type_tokens.dart';
import 'package:luka/features/accounts/application/account_actions.dart';
import 'package:luka/features/nfc/application/nfc_actions.dart';
import 'package:luka/features/nfc/domain/nfc_ports.dart';
import 'package:luka/features/nfc/presentation/nfc_format.dart';
import 'package:luka/features/review/presentation/widgets/review_format.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/presentation/widgets/category_sheet.dart';
import 'package:luka/features/transactions/presentation/widgets/sheet_frame.dart';

/// Registro rápido de un tag NFC (diseño B "Hoja sobre la app", F4.5b,
/// spec 008 §3.4, AC-4.1/4.2): solo el monto; categoría, cuenta y nota salen
/// de la plantilla del tag. Un tag que este teléfono no conoce pide la
/// categoría y ofrece guardarlo como plantilla. Guarda por el outbox (sin
/// red también).
class QuickAddPage extends ConsumerStatefulWidget {
  const QuickAddPage({required this.tagId, super.key});

  final String tagId;

  /// Página transparente: la hoja queda sobre lo que había debajo.
  static Page<void> page({required String tagId}) => CustomTransitionPage<void>(
    opaque: false,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    child: QuickAddPage(tagId: tagId),
    transitionsBuilder: (context, animation, _, child) => SlideTransition(
      position: Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation),
      child: child,
    ),
  );

  @override
  ConsumerState<QuickAddPage> createState() => _QuickAddPageState();
}

class _QuickAddPageState extends ConsumerState<QuickAddPage> {
  final _amount = TextEditingController();
  String? _categoryId;
  String? _categoryName;
  bool _remember = true;
  bool _amountError = false;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  Future<void> _pickCategory() async {
    final choice = await CategorySheet.show(context, selectedId: _categoryId);
    final id = choice?.id;
    if (id == null || !mounted) return;
    setState(() {
      _categoryId = id;
      _categoryName = choice?.name;
    });
  }

  Future<void> _save(NfcTagTemplate? template) async {
    final amount = parseCopInput(_amount.text);
    if (amount == null || amount.cents <= 0) {
      setState(() => _amountError = true);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final offline = ref.read(syncCoordinatorProvider).offline;
    setState(() => _busy = true);
    await ref
        .read(nfcActionsProvider)
        .saveQuickAdd(
          tagId: widget.tagId,
          amount: amount,
          categoryId: template?.categoryId ?? _categoryId,
          accountId: template?.accountId,
          note: template?.note,
          rememberAs: template == null && _remember
              ? _categoryName ?? l10n.quickAddDefaultTemplateName
              : null,
        );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(offline ? l10n.quickAddSavedOffline : l10n.quickAddSaved),
      ),
    );
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;
    final template = ref.watch(nfcTemplateProvider(widget.tagId));
    final categories = ref.watch(transactionCategoriesProvider).value ?? [];
    final accounts = ref.watch(linkedAccountsProvider).value ?? const [];
    final known = template.value;
    final loading = template.isLoading;
    final chosenCategory = _categoryName ?? l10n.quickAddChooseCategory;

    final title = known?.name ?? l10n.quickAddUnknownTitle;
    final meta = known == null
        ? l10n.quickAddUnknownMeta
        : templateMeta(l10n, known, categories, accounts);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: brand.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              Space.lg,
              10,
              Space.lg,
              Space.lg + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Space.sm,
              children: [
                const SheetHandle(),
                Row(
                  spacing: Space.sm,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.nfc_rounded,
                          size: 20,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Expanded(
                      child: MergeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                title,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              meta,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _busy ? null : _close,
                      tooltip: l10n.quickAddClose,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  l10n.quickAddAmountLabel,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextField(
                  controller: _amount,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [CopInputFormatter()],
                  onChanged: (_) {
                    if (_amountError) setState(() => _amountError = false);
                  },
                  style: amountTextStyle.copyWith(fontSize: 32),
                  decoration: InputDecoration(
                    prefixText: r'$ ',
                    prefixStyle: amountTextStyle.copyWith(fontSize: 32),
                    hintText: '0',
                    errorText: _amountError
                        ? l10n.quickAddAmountRequired
                        : null,
                    border: const OutlineInputBorder(
                      borderRadius: Radii.noticeAll,
                    ),
                  ),
                ),
                if (!loading && known == null) ...[
                  Material(
                    color: brand.tile,
                    shape: RoundedRectangleBorder(
                      borderRadius: Radii.rowAll,
                      side: BorderSide(color: scheme.outline),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _busy ? null : () => unawaited(_pickCategory()),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 52),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${l10n.quickAddCategory}: $chosenCategory',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: scheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  CheckboxListTile(
                    value: _remember,
                    onChanged: _busy
                        ? null
                        : (value) => setState(() => _remember = value ?? false),
                    title: Text(l10n.quickAddRemember),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
                FilledButton(
                  onPressed: _busy || loading
                      ? null
                      : () => unawaited(_save(known)),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Text(l10n.quickAddSave),
                ),
                TextButton(
                  onPressed: _busy ? null : () => context.go(Routes.register),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(minTouchTarget),
                  ),
                  child: Text(l10n.quickAddOpenFull),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
