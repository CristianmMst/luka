import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/db/app_database.dart';
import 'package:luka/features/dashboard/data/drift_insights_repository.dart';

final driftInsightsRepositoryProvider = Provider<DriftInsightsRepository>(
  (ref) => DriftInsightsRepository(ref.watch(appDatabaseProvider)),
);
