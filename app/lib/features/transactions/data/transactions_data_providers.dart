import 'package:finanzia/core/db/app_database.dart';
import 'package:finanzia/features/sync/data/sync_data_providers.dart';
import 'package:finanzia/features/transactions/data/drift_transactions_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final driftTransactionsRepositoryProvider =
    Provider<DriftTransactionsRepository>(
      (ref) => DriftTransactionsRepository(
        ref.watch(appDatabaseProvider),
        ref.watch(syncApiProvider),
      ),
    );
