import 'package:finanzia/core/db/app_database.dart';
import 'package:finanzia/features/review/data/drift_review_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final driftReviewRepositoryProvider = Provider<DriftReviewRepository>(
  (ref) => DriftReviewRepository(ref.watch(appDatabaseProvider)),
);
