import 'dart:async';

import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/finanzia_colors.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/features/capture/application/capture_health.dart';
import 'package:finanzia/features/capture/application/notification_access_controller.dart';
import 'package:finanzia/features/capture/presentation/widgets/notification_disclosure_sheet.dart';
import 'package:finanzia/features/gmail/application/gmail_controller.dart';
import 'package:finanzia/features/gmail/domain/gmail_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Franja ámbar dentro del hero del Inicio (F4.4, diseño B, AC-3.4) cuando
/// la captura automática se detuvo: "Captura detenida · Reactivar ›" o
/// "Gmail se desconectó · Reconectar ›". Tocarla hace la acción; desaparece
/// sola cuando se arregla. Con la captura sana no ocupa espacio.
class CaptureStoppedStrip extends ConsumerWidget {
  const CaptureStoppedStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(captureHealthProvider);
    if (health == CaptureHealth.ok) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final brand = context.finanziaColors;
    final textTheme = Theme.of(context).textTheme;
    final gmail = health == CaptureHealth.gmailRevoked;
    final title = gmail
        ? l10n.captureStoppedGmail
        : l10n.captureStoppedNotifications;
    final action = gmail
        ? l10n.captureStoppedReconnect
        : l10n.captureStoppedReactivate;

    Future<void> reactivate() async {
      // Divulgación prominente antes del ajuste del sistema (spec 010 §2).
      if (await NotificationDisclosureSheet.show(context)) {
        await ref.read(notificationAccessProvider.notifier).openSettings();
      }
    }

    Future<void> reconnect() async {
      final messenger = ScaffoldMessenger.of(context);
      final controller = ref.read(gmailControllerProvider.notifier);
      if (await controller.connect()) return;
      final failure = ref.read(gmailControllerProvider).value?.failure;
      if (failure == null || failure is GmailConsentCancelled) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.captureStoppedReconnectFailed)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Semantics(
        button: true,
        liveRegion: true,
        label: l10n.captureStoppedSemantics(title, action),
        excludeSemantics: true,
        child: Material(
          color: brand.warningContainer,
          borderRadius: Radii.rowAll,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => unawaited(gmail ? reconnect() : reactivate()),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: minTouchTarget),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  14,
                  Space.xs,
                  Space.xs,
                  Space.xs,
                ),
                child: Row(
                  spacing: 10,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: brand.onWarningContainer,
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: ' · $action'),
                          ],
                        ),
                        style: textTheme.bodyMedium?.copyWith(
                          color: brand.onWarningContainer,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: brand.onWarningContainer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
