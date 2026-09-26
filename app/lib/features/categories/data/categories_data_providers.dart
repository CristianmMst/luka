import 'package:finanzia/core/db/app_database.dart';
import 'package:finanzia/core/network/dio_providers.dart';
import 'package:finanzia/features/categories/data/categories_api.dart';
import 'package:finanzia/features/categories/data/drift_categories_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoriesApiProvider = Provider<CategoriesApi>(
  (ref) => CategoriesApi(ref.watch(apiDioProvider)),
);

final driftCategoriesStoreProvider = Provider<DriftCategoriesStore>(
  (ref) => DriftCategoriesStore(ref.watch(appDatabaseProvider)),
);
