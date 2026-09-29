import 'package:finanzia/core/db/app_database.dart';
import 'package:finanzia/core/network/dio_providers.dart';
import 'package:finanzia/features/accounts/data/accounts_api.dart';
import 'package:finanzia/features/accounts/data/drift_accounts_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountsApiProvider = Provider<AccountsApi>(
  (ref) => AccountsApi(ref.watch(apiDioProvider)),
);

final driftAccountsStoreProvider = Provider<DriftAccountsStore>(
  (ref) => DriftAccountsStore(ref.watch(appDatabaseProvider)),
);
