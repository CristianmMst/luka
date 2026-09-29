import 'package:finanzia/core/network/dio_providers.dart';
import 'package:finanzia/features/privacy/data/privacy_api.dart';
import 'package:finanzia/features/privacy/data/share_export_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final privacyApiProvider = Provider<PrivacyApi>(
  (ref) => PrivacyApi(ref.watch(apiDioProvider)),
);

final shareExportSaverProvider = Provider<ShareExportSaver>(
  (ref) => const ShareExportSaver(),
);
