import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/db/app_database.dart';
import 'package:luka/features/nfc/data/drift_nfc_tag_store.dart';
import 'package:luka/features/nfc/data/nfc_manager_service.dart';

final driftNfcTagStoreProvider = Provider<DriftNfcTagStore>(
  (ref) => DriftNfcTagStore(ref.watch(appDatabaseProvider)),
);

final nfcManagerServiceProvider = Provider<NfcManagerService>(
  (ref) => NfcManagerService(),
);
