import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/widgets/inline_notice.dart';
import 'package:luka/features/privacy/application/privacy_actions.dart';
import 'package:luka/features/privacy/domain/privacy_ports.dart';
import 'package:luka/features/transactions/presentation/widgets/sheet_frame.dart';

/// Hoja "Privacidad y datos" (diseño B, F4.8b, spec 008 §3.7, RF-11):
/// borrar mi cuenta, que lista lo que se borra y pide escribir BORRAR antes
/// de habilitar el botón (doble confirmación).
class PrivacySheet extends ConsumerStatefulWidget {
  const PrivacySheet({super.key});

  static Future<void> show(BuildContext context) => showLukaSheet<void>(
    context,
    builder: (_) => const PrivacySheet(),
  );

  @override
  ConsumerState<PrivacySheet> createState() => _PrivacySheetState();
}

class _PrivacySheetState extends ConsumerState<PrivacySheet> {
  final _confirm = TextEditingController();
  bool _deleting = false;
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

  Future<void> _delete() async {
    setState(() {
      _deleting = true;
      _failure = null;
    });
    try {
      await ref.read(privacyActionsProvider).deleteAccount();
    } on PrivacyFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
          TextField(
            controller: _confirm,
            enabled: !_deleting,
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
            onPressed: _deleting || !_confirmed(l10n)
                ? null
                : () => unawaited(_delete()),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: Text(
              _deleting ? l10n.privacyDeleting : l10n.privacyDeleteButton,
            ),
          ),
        ],
      ),
    );
  }
}
