import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/features/sync/domain/outbox_operation.dart';
import 'package:luka/features/sync/domain/rejected_change.dart';

/// "hace 3 min", "hace 2 h", "hace 1 día" desde [then] hasta [now].
String syncAgo(AppLocalizations l10n, DateTime then, DateTime now) {
  final elapsed = now.difference(then);
  if (elapsed.inMinutes < 1) return l10n.syncAgoNow;
  if (elapsed.inHours < 1) return l10n.syncAgoMinutes(elapsed.inMinutes);
  if (elapsed.inDays < 1) return l10n.syncAgoHours(elapsed.inHours);
  return l10n.syncAgoDays(elapsed.inDays);
}

/// Qué cambio es, en lenguaje claro.
String rejectedOpLabel(AppLocalizations l10n, OutboxOperation op) =>
    switch (op) {
      CreateTransactionOp() => l10n.rejectedOpCreate,
      PatchTransactionOp() => l10n.rejectedOpPatch,
      SetTransferPairOp() || UnsetTransferPairOp() => l10n.rejectedOpTransfer,
      DeleteTransactionOp() => l10n.rejectedOpDelete,
      ConvertReviewOp() => l10n.rejectedOpConvertReview,
      DiscardReviewOp() => l10n.rejectedOpDiscardReview,
    };

/// Por qué se rechazó, en lenguaje claro.
String rejectedReasonLabel(AppLocalizations l10n, String? code) =>
    switch (classifyRejectedReason(code)) {
      RejectedReason.gone => l10n.rejectedReasonGone,
      RejectedReason.invalid => l10n.rejectedReasonInvalid,
      RejectedReason.dependency => l10n.rejectedReasonDependency,
      RejectedReason.other => l10n.rejectedReasonOther,
    };
