import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/db/app_database.dart';
import 'package:luka/core/network/dio_providers.dart';
import 'package:luka/features/recurring/data/drift_recurring_store.dart';
import 'package:luka/features/recurring/data/recurring_api.dart';

final recurringApiProvider = Provider<RecurringApi>(
  (ref) => RecurringApi(ref.watch(apiDioProvider)),
);

final driftRecurringStoreProvider = Provider<DriftRecurringStore>(
  (ref) => DriftRecurringStore(ref.watch(appDatabaseProvider)),
);
