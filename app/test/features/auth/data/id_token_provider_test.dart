import 'package:finanzia/core/google/google_sign_in_setup.dart';
import 'package:finanzia/features/auth/data/id_token_provider.dart';
import 'package:finanzia/features/auth/domain/auth_failure.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

/// Lo que Google puede meter en `description`/`details`: nunca al log.
const _pii = 'ana.secreta@gmail.com';

void main() {
  late _MockGoogleSignIn client;
  late List<String> logs;
  late DebugPrintCallback original;

  setUp(() {
    client = _MockGoogleSignIn();
    when(
      () => client.initialize(serverClientId: any(named: 'serverClientId')),
    ).thenAnswer((_) async {});
    when(() => client.supportsAuthenticate()).thenReturn(true);
    logs = [];
    original = debugPrint;
    debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
  });

  tearDown(() => debugPrint = original);

  GoogleIdTokenProvider provider() => GoogleIdTokenProvider(
    GoogleSignInSetup(serverClientId: 'web-client-id', client: client),
  );

  test(
    'configuración rota: AuthMisconfigured y log solo con el código',
    () async {
      when(() => client.authenticate()).thenThrow(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
          description: 'cuenta $_pii sin SHA-1',
          details: _pii,
        ),
      );

      await expectLater(
        provider().obtainIdToken(),
        throwsA(
          isA<AuthMisconfigured>().having(
            (f) => f.detail,
            'detail',
            'clientConfigurationError',
          ),
        ),
      );
    },
  );

  test('ningún GoogleSignInException loguea description ni details', () async {
    for (final code in GoogleSignInExceptionCode.values) {
      when(() => client.authenticate()).thenThrow(
        GoogleSignInException(code: code, description: _pii, details: _pii),
      );
      await expectLater(provider().obtainIdToken(), throwsA(isA<Object>()));
    }

    expect(logs, isNotEmpty);
    for (final line in logs) {
      expect(line, isNot(contains(_pii)));
    }
    final firstCode = GoogleSignInExceptionCode.values.first.name;
    expect(logs.first, '[auth] GoogleSignInException $firstCode');
  });
}
