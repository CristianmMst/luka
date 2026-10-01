import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/widgets/settings_group.dart';
import 'package:luka/features/gmail/application/gmail_controller.dart';
import 'package:luka/features/gmail/domain/gmail_connection.dart';
import 'package:luka/features/gmail/domain/gmail_failure.dart';
import 'package:luka/features/gmail/presentation/widgets/gmail_disconnect_dialog.dart';
import 'package:luka/features/gmail/presentation/widgets/gmail_failure_notice.dart';

/// Fila "Gmail" de Ajustes (spec 008 §3.7, AC-1.3): estado de la conexión y
/// su acción (conectar, reconectar o desconectar con confirmación).
class GmailSettingsTile extends ConsumerWidget {
  const GmailSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(gmailControllerProvider.notifier);
    final gmail = ref.watch(gmailControllerProvider);

    final current = gmail.hasError || gmail.isLoading ? null : gmail.value;
    final busy = current?.busy ?? false;
    final info = current?.info;

    Future<void> disconnect() async {
      if (await GmailDisconnectDialog.show(context)) {
        await controller.disconnect();
      }
    }

    final (String status, Color statusColor) = switch ((gmail, info)) {
      (_, final GmailConnectionInfo info) => switch (info.status) {
        GmailStatus.active => (
          info.email == null
              ? l10n.settingsGmailConnectedNoEmail
              : l10n.settingsGmailConnected(info.email!),
          // Bien en verde: el tomate de marca se leería como error.
          context.lukaColors.income,
        ),
        GmailStatus.revoked => (l10n.settingsGmailRevoked, scheme.error),
        GmailStatus.error => (l10n.settingsGmailError, scheme.error),
        GmailStatus.disconnected => (
          l10n.settingsGmailDisconnected,
          scheme.onSurfaceVariant,
        ),
      },
      (AsyncValue(isLoading: true), _) => (
        l10n.settingsGmailLoading,
        scheme.onSurfaceVariant,
      ),
      _ => (l10n.settingsGmailUnavailable, scheme.error),
    };

    final (String? action, VoidCallback? onAction) = switch (info?.status) {
      _ when busy || gmail.isLoading => (null, null),
      null => (l10n.settingsGmailRetry, () => unawaited(controller.refresh())),
      GmailStatus.active => (
        l10n.settingsGmailDisconnect,
        () => unawaited(disconnect()),
      ),
      GmailStatus.revoked || GmailStatus.error => (
        l10n.settingsGmailReconnect,
        () => unawaited(controller.connect()),
      ),
      GmailStatus.disconnected => (
        l10n.settingsGmailConnect,
        () => unawaited(controller.connect()),
      ),
    };

    final failure = current?.failure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Space.xs,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.md - 2,
              Space.sm,
              Space.xs,
              Space.sm,
            ),
            child: Row(
              spacing: Space.sm,
              children: [
                const ExcludeSemantics(
                  child: SettingsIcon(Icons.mail_outline_rounded),
                ),
                Expanded(
                  child: MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          l10n.settingsGmailTitle,
                          style: textTheme.titleSmall,
                        ),
                        Text(
                          status,
                          style: textTheme.bodySmall?.copyWith(
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (busy || gmail.isLoading)
                  const SizedBox.square(
                    dimension: minTouchTarget,
                    child: Padding(
                      padding: EdgeInsets.all(Space.sm + 2),
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  )
                else if (action != null)
                  TextButton(
                    onPressed: onAction,
                    style: info?.status == GmailStatus.active
                        ? TextButton.styleFrom(foregroundColor: scheme.error)
                        : null,
                    child: Text(
                      action,
                      semanticsLabel: l10n.settingsGmailActionSemantics(
                        action,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (failure != null && failure is! GmailConsentCancelled)
          GmailFailureNotice(failure: failure),
      ],
    );
  }
}
