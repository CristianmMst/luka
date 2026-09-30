import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/db/app_database.dart';
import 'package:luka/features/review/data/drift_review_repository.dart';

final driftReviewRepositoryProvider = Provider<DriftReviewRepository>(
  (ref) => DriftReviewRepository(ref.watch(appDatabaseProvider)),
);
