import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/network/dio_providers.dart';
import 'package:luka/features/privacy/data/privacy_api.dart';
import 'package:luka/features/privacy/data/share_export_saver.dart';

final privacyApiProvider = Provider<PrivacyApi>(
  (ref) => PrivacyApi(ref.watch(apiDioProvider)),
);

final shareExportSaverProvider = Provider<ShareExportSaver>(
  (ref) => const ShareExportSaver(),
);
