import 'package:finanzia/core/network/dio_providers.dart';
import 'package:finanzia/features/accounts/application/account_actions.dart';
import 'package:finanzia/features/accounts/data/accounts_data_providers.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/data/auth_data_providers.dart';
import 'package:finanzia/features/capture/application/capture_flusher.dart';
import 'package:finanzia/features/capture/data/capture_data_providers.dart';
import 'package:finanzia/features/categories/application/category_actions.dart';
import 'package:finanzia/features/categories/data/categories_data_providers.dart';
import 'package:finanzia/features/dashboard/application/dashboard_providers.dart';
import 'package:finanzia/features/dashboard/data/dashboard_data_providers.dart';
import 'package:finanzia/features/gmail/application/gmail_controller.dart';
import 'package:finanzia/features/gmail/data/gmail_data_providers.dart';
import 'package:finanzia/features/onboarding/application/onboarding_gate.dart';
import 'package:finanzia/features/onboarding/data/onboarding_data_providers.dart';
import 'package:finanzia/features/review/application/review_providers.dart';
import 'package:finanzia/features/review/data/review_data_providers.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/data/sync_data_providers.dart';
import 'package:finanzia/features/transactions/application/transactions_providers.dart';
import 'package:finanzia/features/transactions/data/transactions_data_providers.dart';
import 'package:flutter_riverpod/misc.dart';

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
  connectivityProvider.overrideWith(
    (ref) => ref.watch(connectivityStreamProvider),
  ),
  foregroundTicksProvider.overrideWith(
    (ref) => ref.watch(foregroundTicksStreamProvider),
  ),
  transactionsRepositoryProvider.overrideWith(
    (ref) => ref.watch(driftTransactionsRepositoryProvider),
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
  categoriesRemoteProvider.overrideWith(
    (ref) => ref.watch(categoriesApiProvider),
  ),
  categoriesStoreProvider.overrideWith(
    (ref) => ref.watch(driftCategoriesStoreProvider),
  ),
  accountsRemoteProvider.overrideWith((ref) => ref.watch(accountsApiProvider)),
  accountsStoreProvider.overrideWith(
    (ref) => ref.watch(driftAccountsStoreProvider),
  ),
];
