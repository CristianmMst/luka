import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/accounts/application/account_actions.dart';
import 'package:luka/features/nfc/application/nfc_actions.dart';
import 'package:luka/features/nfc/domain/nfc_ports.dart';
import 'package:luka/features/nfc/presentation/nfc_format.dart';
import 'package:luka/features/nfc/presentation/nfc_tag_form_sheet.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';

/// Ajustes → "Tags NFC" (F4.5b, spec 008 §3.7): las plantillas de este
/// teléfono, con crear, editar, escribir y borrar.
class NfcTagsPage extends ConsumerWidget {
  const NfcTagsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tags = ref.watch(nfcTagsProvider).value ?? const [];
    final categories = ref.watch(transactionCategoriesProvider).value ?? [];
    final accounts = ref.watch(linkedAccountsProvider).value ?? const [];
    final muted = textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.nfcTagsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.xs,
            Space.screen,
            Space.xl,
          ),
          children: [
            Text(l10n.nfcTagsIntro, style: muted),
            const SizedBox(height: Space.md),
            if (tags.isEmpty)
              Text(l10n.nfcTagsEmpty, style: textTheme.bodyMedium)
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.lukaColors.card,
                  borderRadius: Radii.noticeAll,
                  border: Border.all(color: context.lukaColors.hairline),
                ),
                child: Column(
                  children: [
                    for (final (i, tag) in tags.indexed) ...[
                      if (i > 0)
                        Divider(height: 1, color: scheme.surfaceContainer),
                      _TagRow(
                        tag: tag,
                        meta: templateMeta(l10n, tag, categories, accounts),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: Space.sm),
            OutlinedButton.icon(
              onPressed: () => unawaited(NfcTagFormSheet.show(context)),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.nfcTagsNew),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: BorderSide(color: scheme.primary),
              ),
            ),
            const SizedBox(height: Space.md),
            Text(l10n.nfcTagsLocalNote, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tag, required this.meta});

  final NfcTagTemplate tag;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(left: 14, right: Space.xxs),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Row(
          spacing: Space.sm,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.lukaColors.neutralChip,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.nfc_rounded,
                  size: 18,
                  color: scheme.primary,
                ),
              ),
            ),
            Expanded(
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      tag.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
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
              onPressed: () =>
                  unawaited(NfcTagFormSheet.show(context, existing: tag)),
              tooltip: l10n.nfcTagEditSemantics(tag.name),
              icon: Icon(Icons.edit_outlined, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
