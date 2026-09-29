import 'package:finanzia/core/db/app_database.dart';
import 'package:finanzia/features/nfc/data/drift_nfc_tag_store.dart';
import 'package:finanzia/features/nfc/data/nfc_manager_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final driftNfcTagStoreProvider = Provider<DriftNfcTagStore>(
  (ref) => DriftNfcTagStore(ref.watch(appDatabaseProvider)),
);

final nfcManagerServiceProvider = Provider<NfcManagerService>(
  (ref) => NfcManagerService(),
);
