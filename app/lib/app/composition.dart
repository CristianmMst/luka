import 'package:flutter_riverpod/misc.dart';
import 'package:luka/core/network/dio_providers.dart';
import 'package:luka/features/accounts/application/account_actions.dart';
import 'package:luka/features/accounts/data/accounts_data_providers.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/auth/data/auth_data_providers.dart';
import 'package:luka/features/capture/application/capture_flusher.dart';
import 'package:luka/features/capture/application/capture_health.dart';
import 'package:luka/features/capture/data/capture_data_providers.dart';
import 'package:luka/features/categories/application/category_actions.dart';
import 'package:luka/features/categories/data/categories_data_providers.dart';
import 'package:luka/features/dashboard/application/dashboard_providers.dart';
import 'package:luka/features/dashboard/data/dashboard_data_providers.dart';
import 'package:luka/features/gmail/application/gmail_controller.dart';
import 'package:luka/features/gmail/data/gmail_data_providers.dart';
import 'package:luka/features/nfc/application/nfc_actions.dart';
import 'package:luka/features/nfc/data/nfc_data_providers.dart';
import 'package:luka/features/onboarding/application/onboarding_gate.dart';
import 'package:luka/features/onboarding/data/onboarding_data_providers.dart';
import 'package:luka/features/privacy/application/privacy_actions.dart';
import 'package:luka/features/privacy/data/privacy_data_providers.dart';
import 'package:luka/features/push/application/push_registrar.dart';
import 'package:luka/features/push/data/push_data_providers.dart';
import 'package:luka/features/recurring/application/local_reminder_sync.dart';
import 'package:luka/features/recurring/application/recurring_actions.dart';
import 'package:luka/features/recurring/data/recurring_data_providers.dart';
import 'package:luka/features/review/application/review_providers.dart';
import 'package:luka/features/review/data/review_data_providers.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/sync/data/sync_data_providers.dart';
import 'package:luka/features/transactions/application/dedupe_hint_controller.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/data/transactions_data_providers.dart';

/// Raíz de composición: conecta los puertos de `core` y de las capas de
/// aplicación con sus implementaciones en `data`. Es el único lugar donde
/// `application` y `data` se encuentran.
List<Override> get appOverrides => [
  sessionBridgeProvider.overrideWith(
    (ref) => ref.watch(sessionManagerProvider),
  ),
  authRepositoryProvider.overrideWith(
    (ref) => ref.watch(authRepositoryImplProvider),
  ),
  gmailRepositoryProvider.overrideWith(
    (ref) => ref.watch(gmailRepositoryImplProvider),
  ),
  onboardingStoreProvider.overrideWith(
    (ref) => ref.watch(driftOnboardingStoreProvider),
  ),
  syncStoreProvider.overrideWith((ref) => ref.watch(driftSyncStoreProvider)),
  syncRemoteProvider.overrideWith((ref) => ref.watch(syncApiProvider)),
  syncSnapshotsProvider.overrideWith(
    (ref) => [ref.watch(recurringSnapshotProvider)],
  ),
  recurringRemoteProvider.overrideWith(
    (ref) => ref.watch(recurringApiProvider),
  ),
  recurringStoreProvider.overrideWith(
    (ref) => ref.watch(driftRecurringStoreProvider),
  ),
  pushServiceProvider.overrideWith(
    (ref) => ref.watch(platformPushServiceProvider),
  ),
  reminderSchedulerProvider.overrideWith(
    (ref) => ref.watch(platformReminderSchedulerProvider),
  ),
  pushTokenRemoteProvider.overrideWith(
    (ref) => ref.watch(pushTokenApiProvider),
  ),
  pushPrefsProvider.overrideWith((ref) => ref.watch(driftPushPrefsProvider)),
  // Antes de cerrar la sesión se borra el token de push (spec 011 §6).
  signOutHooksProvider.overrideWith(
    (ref) => [() => ref.read(pushRegistrarProvider.notifier).unregister()],
  ),
  connectivityProvider.overrideWith(
    (ref) => ref.watch(connectivityStreamProvider),
  ),
  foregroundTicksProvider.overrideWith(
    (ref) => ref.watch(foregroundTicksStreamProvider),
  ),
  transactionsRepositoryProvider.overrideWith(
    (ref) => ref.watch(driftTransactionsRepositoryProvider),
  ),
  dedupeHintStoreProvider.overrideWith(
    (ref) => ref.watch(driftDedupeHintStoreProvider),
  ),
  reviewRepositoryProvider.overrideWith(
    (ref) => ref.watch(driftReviewRepositoryProvider),
  ),
  insightsRepositoryProvider.overrideWith(
    (ref) => ref.watch(driftInsightsRepositoryProvider),
  ),
  notificationSourceProvider.overrideWith(
    (ref) => ref.watch(platformNotificationSourceProvider),
  ),
  captureRemoteProvider.overrideWith((ref) => ref.watch(captureApiProvider)),
  captureGrantStoreProvider.overrideWith(
    (ref) => ref.watch(driftCaptureGrantStoreProvider),
  ),
  categoriesRemoteProvider.overrideWith(
    (ref) => ref.watch(categoriesApiProvider),
  ),
  categoriesStoreProvider.overrideWith(
    (ref) => ref.watch(driftCategoriesStoreProvider),
  ),
  accountsRemoteProvider.overrideWith((ref) => ref.watch(accountsApiProvider)),
  privacyRemoteProvider.overrideWith((ref) => ref.watch(privacyApiProvider)),
  nfcTagStoreProvider.overrideWith(
    (ref) => ref.watch(driftNfcTagStoreProvider),
  ),
  nfcServiceProvider.overrideWith(
    (ref) => ref.watch(nfcManagerServiceProvider),
  ),
  accountsStoreProvider.overrideWith(
    (ref) => ref.watch(driftAccountsStoreProvider),
  ),
];
