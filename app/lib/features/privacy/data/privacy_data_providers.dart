import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/network/dio_providers.dart';
import 'package:luka/features/privacy/data/privacy_api.dart';

final privacyApiProvider = Provider<PrivacyApi>(
  (ref) => PrivacyApi(ref.watch(apiDioProvider)),
);
