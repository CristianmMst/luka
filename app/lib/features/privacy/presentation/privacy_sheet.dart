import 'dart:async';

import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/finanzia_colors.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/core/widgets/inline_notice.dart';
import 'package:finanzia/features/privacy/application/privacy_actions.dart';
import 'package:finanzia/features/privacy/domain/privacy_ports.dart';
import 'package:finanzia/features/transactions/presentation/widgets/sheet_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hoja "Privacidad y datos" (diseño B, F4.8b, spec 008 §3.7, RF-11):
/// exportar mis datos y borrar mi cuenta, que lista lo que se borra y pide
/// escribir BORRAR antes de habilitar el botón (doble confirmación).
class PrivacySheet extends ConsumerStatefulWidget {
  const PrivacySheet({super.key});

  static Future<void> show(BuildContext context) => showFinanziaSheet<void>(
    context,
    builder: (_) => const PrivacySheet(),
  );

  @override
  ConsumerState<PrivacySheet> createState() => _PrivacySheetState();
}

enum _Busy { none, exporting, deleting }

class _PrivacySheetState extends ConsumerState<PrivacySheet> {
  final _confirm = TextEditingController();
  _Busy _busy = _Busy.none;
  PrivacyFailure? _failure;

  @override
  void initState() {
    super.initState();
    _confirm.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  bool _confirmed(AppLocalizations l10n) =>
      _confirm.text.trim().toUpperCase() == l10n.privacyDeleteConfirmWord;

  Future<void> _run(_Busy what, Future<void> Function() action) async {
    setState(() {
      _busy = what;
      _failure = null;
    });
    try {
      await action();
    } on PrivacyFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final actions = ref.read(privacyActionsProvider);
    final busy = _busy != _Busy.none;
    final failureMessage = switch (_failure) {
      PrivacyOffline() => l10n.privacyErrorOffline,
      PrivacyUnexpected() => l10n.privacyErrorUnexpected,
      null => null,
    };

    Widget item(String text) => Row(
      spacing: Space.sm,
      children: [
        Icon(Icons.close_rounded, size: 18, color: scheme.error),
        Expanded(child: Text(text, style: textTheme.bodyMedium)),
      ],
    );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Space.lg,
        10,
        Space.lg,
        Space.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Space.sm,
        children: [
          const SheetHandle(),
          Semantics(
            header: true,
            child: Text(
              l10n.privacySheetTitle,
              style: textTheme.headlineSmall?.copyWith(fontSize: 22),
            ),
          ),
          Material(
            color: context.finanziaColors.tile,
            borderRadius: Radii.rowAll,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: busy
                  ? null
                  : () => unawaited(_run(_Busy.exporting, actions.exportData)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: Space.xs,
                  ),
                  child: Row(
                    spacing: Space.sm,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            Text(
                              l10n.privacyExportTitle,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _busy == _Busy.exporting
                                  ? l10n.privacyExporting
                                  : l10n.privacyExportBody,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_busy == _Busy.exporting)
                        const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          Icons.download_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.xs),
          Semantics(
            header: true,
            child: Text(
              l10n.privacyDeleteTitle,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.error,
              ),
            ),
          ),
          Text(l10n.privacyDeleteIntro, style: textTheme.bodyMedium),
          item(l10n.privacyDeleteItemTransactions),
          item(l10n.privacyDeleteItemMessages),
          item(l10n.privacyDeleteItemData),
          item(l10n.privacyDeleteItemGmail),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: busy
                  ? null
                  : () => unawaited(_run(_Busy.exporting, actions.exportData)),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, minTouchTarget),
                padding: EdgeInsets.zero,
              ),
              child: Text(l10n.privacyExportFirst),
            ),
          ),
          TextField(
            controller: _confirm,
            enabled: !busy,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.privacyDeleteConfirmLabel,
              hintText: l10n.privacyDeleteConfirmWord,
              border: const OutlineInputBorder(borderRadius: Radii.rowAll),
            ),
          ),
          if (failureMessage != null)
            InlineNotice(message: failureMessage, tone: NoticeTone.error),
          FilledButton(
            onPressed: busy || !_confirmed(l10n)
                ? null
                : () => unawaited(
                    _run(_Busy.deleting, actions.deleteAccount),
                  ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: Text(
              _busy == _Busy.deleting
                  ? l10n.privacyDeleting
                  : l10n.privacyDeleteButton,
            ),
          ),
        ],
      ),
    );
  }
}
