import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/db/app_database.dart';
import 'package:luka/core/network/dio_providers.dart';
import 'package:luka/features/categories/data/categories_api.dart';
import 'package:luka/features/categories/data/drift_categories_store.dart';

final categoriesApiProvider = Provider<CategoriesApi>(
  (ref) => CategoriesApi(ref.watch(apiDioProvider)),
);

final driftCategoriesStoreProvider = Provider<DriftCategoriesStore>(
  (ref) => DriftCategoriesStore(ref.watch(appDatabaseProvider)),
);
