import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/db/app_database.dart';
import 'package:luka/features/sync/data/sync_data_providers.dart';
import 'package:luka/features/transactions/data/drift_dedupe_hint_store.dart';
import 'package:luka/features/transactions/data/drift_transactions_repository.dart';

final driftTransactionsRepositoryProvider =
    Provider<DriftTransactionsRepository>(
      (ref) => DriftTransactionsRepository(
        ref.watch(appDatabaseProvider),
        ref.watch(syncApiProvider),
      ),
    );

final driftDedupeHintStoreProvider = Provider<DriftDedupeHintStore>(
  (ref) => DriftDedupeHintStore(ref.watch(appDatabaseProvider)),
);
