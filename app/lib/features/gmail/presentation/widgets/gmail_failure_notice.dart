import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/widgets/inline_notice.dart';
import 'package:finanzia/features/gmail/domain/gmail_failure.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Aviso para un [GmailFailure] (onboarding y Ajustes). Cancelar el
/// consentimiento no es un error: no muestra nada.
class GmailFailureNotice extends StatelessWidget {
  const GmailFailureNotice({required this.failure, super.key});

  final GmailFailure failure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notice = switch (failure) {
      GmailConsentCancelled() => null,
      GmailNetworkFailure() => (
        NoticeTone.error,
        l10n.errorNetwork,
        Icons.wifi_off_rounded,
      ),
      GmailRateLimited() => (
        NoticeTone.warning,
        l10n.errorRateLimitedNoWait,
        null,
      ),
      GmailCodeRejected() || GmailRefreshTokenMissing() => (
        NoticeTone.error,
        l10n.gmailErrorRejected,
        null,
      ),
      GmailScopeDenied() => (
        NoticeTone.warning,
        l10n.gmailErrorScopeDenied,
        Icons.mark_email_read_outlined,
      ),
      GmailUpstreamUnavailable() => (
        NoticeTone.warning,
        l10n.gmailErrorUpstream,
        Icons.cloud_off_rounded,
      ),
      GmailMisconfigured(:final detail) => (
        NoticeTone.error,
        // En debug se añade la causa técnica para diagnosticar el setup.
        kDebugMode
            ? '${l10n.gmailErrorMisconfigured}\n($detail)'
            : l10n.gmailErrorMisconfigured,
        null,
      ),
      GmailUnexpected() => (NoticeTone.error, l10n.gmailErrorUnexpected, null),
    };
    if (notice == null) return const SizedBox.shrink();
    final (tone, message, icon) = notice;
    return InlineNotice(tone: tone, message: message, icon: icon);
  }
}
