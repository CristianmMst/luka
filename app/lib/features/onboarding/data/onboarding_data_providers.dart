import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/db/app_database.dart';
import 'package:luka/features/onboarding/data/drift_onboarding_store.dart';

final driftOnboardingStoreProvider = Provider<DriftOnboardingStore>(
  (ref) => DriftOnboardingStore(ref.watch(appDatabaseProvider)),
);
