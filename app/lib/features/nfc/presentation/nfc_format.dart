import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/features/accounts/domain/accounts_ports.dart';
import 'package:luka/features/accounts/presentation/linked_account_row.dart';
import 'package:luka/features/nfc/domain/nfc_ports.dart';
import 'package:luka/features/nfc/domain/quick_add_link.dart';
import 'package:luka/features/transactions/domain/category_option.dart';

/// La ruta del registro rápido si [uri] es el enlace de un tag
/// (`luka://quick-add?tag=…`); `null` para cualquier otra ruta.
String? quickAddLocation(Uri uri) {
  final tagId = tagIdFromQuickAddUri(uri);
  if (tagId == null) return null;
  return Uri(
    path: Routes.quickAdd,
    queryParameters: {'tag': tagId},
  ).toString();
}

/// Nombre de la categoría de una plantilla (`null` si no tiene o ya no
/// existe).
String? templateCategoryName(
  NfcTagTemplate template,
  List<CategoryOption> categories,
) {
  final id = template.categoryId;
  if (id == null) return null;
  for (final category in categories) {
    if (category.id == id) return category.name;
  }
  return null;
}

/// Nombre de la cuenta de una plantilla (`null` si no tiene o ya no
/// existe).
String? templateAccountName(
  AppLocalizations l10n,
  NfcTagTemplate template,
  List<LinkedAccount> accounts,
) {
  final id = template.accountId;
  if (id == null) return null;
  for (final account in accounts) {
    if (account.id == id) return linkedAccountTitle(l10n, account);
  }
  return null;
}

/// "Restaurantes · Nómina"; sin categoría, "Sin categoría".
String templateMeta(
  AppLocalizations l10n,
  NfcTagTemplate template,
  List<CategoryOption> categories,
  List<LinkedAccount> accounts,
) => [
  templateCategoryName(template, categories) ?? l10n.nfcTagMetaNone,
  ?templateAccountName(l10n, template, accounts),
].join(' · ');

/// Mensaje de un fallo de NFC.
String nfcFailureMessage(AppLocalizations l10n, NfcFailure failure) =>
    switch (failure) {
      NfcUnavailable(availability: NfcAvailability.unsupported) =>
        l10n.nfcErrorUnsupported,
      NfcUnavailable() => l10n.nfcErrorDisabled,
      NfcTagNotWritable() => l10n.nfcErrorNotWritable,
      NfcTagTooSmall() => l10n.nfcErrorTooSmall,
      NfcCancelled() || NfcIoError() => l10n.nfcErrorIo,
    };
