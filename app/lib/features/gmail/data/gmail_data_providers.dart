import 'package:finanzia/core/google/google_sign_in_setup.dart';
import 'package:finanzia/core/network/dio_providers.dart';
import 'package:finanzia/features/gmail/data/gmail_api.dart';
import 'package:finanzia/features/gmail/data/gmail_authorizer.dart';
import 'package:finanzia/features/gmail/data/gmail_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gmailApiProvider = Provider<GmailApi>(
  (ref) => GmailApi(ref.watch(apiDioProvider)),
);

final gmailAuthorizerProvider = Provider<GmailAuthorizer>(
  (ref) => GmailAuthorizer(ref.watch(googleSignInSetupProvider)),
);

final gmailRepositoryImplProvider = Provider<GmailRepositoryImpl>(
  (ref) => GmailRepositoryImpl(
    authorizer: ref.watch(gmailAuthorizerProvider),
    api: ref.watch(gmailApiProvider),
  ),
);
