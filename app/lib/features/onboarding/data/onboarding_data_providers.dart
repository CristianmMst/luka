import 'package:finanzia/core/db/app_database.dart';
import 'package:finanzia/features/onboarding/data/drift_onboarding_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final driftOnboardingStoreProvider = Provider<DriftOnboardingStore>(
  (ref) => DriftOnboardingStore(ref.watch(appDatabaseProvider)),
);
