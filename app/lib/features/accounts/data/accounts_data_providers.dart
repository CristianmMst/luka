import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/db/app_database.dart';
import 'package:luka/core/network/dio_providers.dart';
import 'package:luka/features/accounts/data/accounts_api.dart';
import 'package:luka/features/accounts/data/drift_accounts_store.dart';

final accountsApiProvider = Provider<AccountsApi>(
  (ref) => AccountsApi(ref.watch(apiDioProvider)),
);

final driftAccountsStoreProvider = Provider<DriftAccountsStore>(
  (ref) => DriftAccountsStore(ref.watch(appDatabaseProvider)),
);
