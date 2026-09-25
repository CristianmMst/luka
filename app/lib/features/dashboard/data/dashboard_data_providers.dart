import 'package:finanzia/core/db/app_database.dart';
import 'package:finanzia/features/dashboard/data/drift_insights_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final driftInsightsRepositoryProvider = Provider<DriftInsightsRepository>(
  (ref) => DriftInsightsRepository(ref.watch(appDatabaseProvider)),
);
