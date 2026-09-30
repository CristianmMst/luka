import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:luka/core/google/google_sign_in_setup.dart';
import 'package:luka/features/auth/data/id_token_provider.dart';
import 'package:luka/features/gmail/data/gmail_authorizer.dart';
import 'package:luka/features/gmail/domain/gmail_failure.dart';
import 'package:mocktail/mocktail.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockAuthorizationClient extends Mock
    implements GoogleSignInAuthorizationClient {}

const _scope = 'https://www.googleapis.com/auth/gmail.readonly';

void main() {
  late _MockGoogleSignIn client;
  late _MockAuthorizationClient authorization;
  late GoogleSignInSetup setup;

  setUp(() {
    client = _MockGoogleSignIn();
    authorization = _MockAuthorizationClient();
    when(
      () => client.initialize(serverClientId: any(named: 'serverClientId')),
    ).thenAnswer((_) async {});
    when(() => client.authorizationClient).thenReturn(authorization);
    setup = GoogleSignInSetup(serverClientId: 'web-client-id', client: client);
  });

  test('pide gmail.readonly para el servidor y devuelve el código', () async {
    when(() => authorization.authorizeServer([_scope])).thenAnswer(
      (_) async => const GoogleSignInServerAuthorization(serverAuthCode: '4/x'),
    );

    final code = await GmailAuthorizer(setup).obtainServerAuthCode();

    expect(code, '4/x');
    verify(() => client.initialize(serverClientId: 'web-client-id')).called(1);
  });

  test('comparte la inicialización con el login', () async {
    when(() => authorization.authorizeServer(any())).thenAnswer(
      (_) async => const GoogleSignInServerAuthorization(serverAuthCode: 'c'),
    );
    when(() => client.signOut()).thenAnswer((_) async {});

    await GoogleIdTokenProvider(setup).signOut();
    await GmailAuthorizer(setup).obtainServerAuthCode();
    await GmailAuthorizer(setup).obtainServerAuthCode();

    verify(
      () => client.initialize(serverClientId: any(named: 'serverClientId')),
    ).called(1);
  });

  test('sin client ID → GmailMisconfigured sin tocar Google', () async {
    final unconfigured = GoogleSignInSetup(
      serverClientId: null,
      client: client,
    );
    await expectLater(
      GmailAuthorizer(unconfigured).obtainServerAuthCode(),
      throwsA(isA<GmailMisconfigured>()),
    );
    verifyNever(
      () => client.initialize(serverClientId: any(named: 'serverClientId')),
    );
  });

  test('sin código de servidor → GmailUnexpected', () async {
    when(
      () => authorization.authorizeServer(any()),
    ).thenAnswer((_) async => null);
    await expectLater(
      GmailAuthorizer(setup).obtainServerAuthCode(),
      throwsA(isA<GmailUnexpected>()),
    );
  });

  test('mapea GoogleSignInException como el login', () async {
    final cases = <GoogleSignInExceptionCode, Matcher>{
      GoogleSignInExceptionCode.canceled: isA<GmailConsentCancelled>(),
      GoogleSignInExceptionCode.interrupted: isA<GmailConsentCancelled>(),
      GoogleSignInExceptionCode.clientConfigurationError:
          isA<GmailMisconfigured>(),
      GoogleSignInExceptionCode.providerConfigurationError:
          isA<GmailMisconfigured>(),
      GoogleSignInExceptionCode.uiUnavailable: isA<GmailUnexpected>(),
      GoogleSignInExceptionCode.userMismatch: isA<GmailUnexpected>(),
      GoogleSignInExceptionCode.unknownError: isA<GmailUnexpected>(),
    };
    for (final MapEntry(:key, :value) in cases.entries) {
      when(
        () => authorization.authorizeServer(any()),
      ).thenThrow(GoogleSignInException(code: key));
      await expectLater(
        GmailAuthorizer(setup).obtainServerAuthCode(),
        throwsA(value),
        reason: key.name,
      );
    }
  });
}
