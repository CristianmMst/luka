import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/capture/application/notification_access_controller.dart';
import 'package:luka/features/capture/presentation/widgets/notification_disclosure_sheet.dart';

/// Fila "Notificaciones del banco" de Ajustes (spec 008 §3.7): acceso activo
/// o inactivo y el enlace al ajuste del sistema. Solo en Android.
class NotificationCaptureTile extends ConsumerWidget {
  const NotificationCaptureTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(notificationCaptureSupportedProvider)) {
      return const SizedBox.shrink();
    }
    final access = ref.watch(notificationAccessProvider);

    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(notificationAccessProvider.notifier);

    Future<void> enable() async {
      // Divulgación prominente antes del ajuste del sistema (spec 010 §2).
      if (await NotificationDisclosureSheet.show(context)) {
        await controller.openSettings();
      }
    }

    final (String status, Color statusColor) = switch (access.value) {
      NotificationAccess.granted => (
        l10n.settingsNotificationsActive,
        scheme.primary,
      ),
      NotificationAccess.denied => (
        l10n.settingsNotificationsInactive,
        scheme.onSurfaceVariant,
      ),
      _ => (l10n.settingsNotificationsLoading, scheme.onSurfaceVariant),
    };

    final (String? action, VoidCallback? onAction) = switch (access.value) {
      NotificationAccess.granted => (
        l10n.settingsNotificationsManage,
        () => unawaited(controller.openSettings()),
      ),
      NotificationAccess.denied => (
        l10n.settingsNotificationsEnable,
        () => unawaited(enable()),
      ),
      _ => (null, null),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.lukaColors.card,
        borderRadius: Radii.rowAll,
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
            ExcludeSemantics(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
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
                    Text(
                      l10n.settingsNotificationsTitle,
                      style: textTheme.titleSmall,
                    ),
                    Text(
                      status,
                      style: textTheme.bodySmall?.copyWith(color: statusColor),
                    ),
                  ],
                ),
              ),
            ),
            if (action != null)
              TextButton(
                onPressed: onAction,
                child: Text(
                  action,
                  semanticsLabel: l10n.settingsNotificationsActionSemantics(
                    action,
                  ),
                ),
              )
            else
              const SizedBox.square(
                dimension: minTouchTarget,
                child: Padding(
                  padding: EdgeInsets.all(Space.sm + 2),
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
