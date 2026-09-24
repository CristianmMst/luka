import 'dart:async';

import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/domain/auth_repository.dart';
import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:finanzia/features/gmail/application/gmail_controller.dart';
import 'package:finanzia/features/gmail/domain/gmail_connection.dart';
import 'package:finanzia/features/gmail/domain/gmail_failure.dart';
import 'package:finanzia/features/gmail/domain/gmail_prompt_store.dart';
import 'package:finanzia/features/gmail/domain/gmail_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGmail extends Mock implements GmailRepository {}

class _MockPrompts extends Mock implements GmailPromptStore {}

class _MockAuth extends Mock implements AuthRepository {}

const _ana = User(
  id: 'u-1',
  email: 'ana@example.com',
  status: UserStatus.active,
);

const _active = GmailConnectionInfo(
  status: GmailStatus.active,
  email: 'ana@gmail.com',
);

void main() {
  late _MockGmail gmail;
  late _MockPrompts prompts;
  late _MockAuth auth;
  late ProviderContainer container;

  ProviderContainer build({User? user = _ana}) {
    when(() => auth.restoreSession()).thenAnswer((_) async => user);
    return container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        gmailRepositoryProvider.overrideWithValue(gmail),
        gmailPromptStoreProvider.overrideWithValue(prompts),
      ],
    );
  }

  GmailController controller() =>
      container.read(gmailControllerProvider.notifier);

  Future<GmailState> settled() =>
      container.read(gmailControllerProvider.future);

  GmailState current() => container.read(gmailControllerProvider).requireValue;

  setUp(() {
    gmail = _MockGmail();
    prompts = _MockPrompts();
    auth = _MockAuth();
    when(() => auth.sessionExpired).thenAnswer((_) => const Stream.empty());
    when(
      () => gmail.status(),
    ).thenAnswer((_) async => GmailConnectionInfo.disconnected);
    when(() => prompts.isDismissed(any())).thenAnswer((_) async => false);
    when(() => prompts.dismiss(any())).thenAnswer((_) async {});
  });

  tearDown(() => container.dispose());

  group('build', () {
    test('sin conexión y sin "Ahora no" → hay que preguntar', () async {
      build();
      final state = await settled();
      expect(state.info, GmailConnectionInfo.disconnected);
      expect(state.promptDismissed, isFalse);
      expect(state.shouldPrompt, isTrue);
      expect(state.busy, isFalse);
      expect(state.failure, isNull);
      verify(() => prompts.isDismissed('u-1')).called(1);
    });

    test('"Ahora no" guardado → no pregunta', () async {
      when(() => prompts.isDismissed('u-1')).thenAnswer((_) async => true);
      build();
      final state = await settled();
      expect(state.promptDismissed, isTrue);
      expect(state.shouldPrompt, isFalse);
    });

    test('ya conectado → no pregunta', () async {
      when(() => gmail.status()).thenAnswer((_) async => _active);
      build();
      final state = await settled();
      expect(state.info, _active);
      expect(state.shouldPrompt, isFalse);
    });

    test('sin sesión → no consulta nada ni pregunta', () async {
      build(user: null);
      final state = await settled();
      expect(state.shouldPrompt, isFalse);
      verifyNever(() => gmail.status());
      verifyNever(() => prompts.isDismissed(any()));
    });

    test('status que falla → AsyncError con el GmailFailure', () async {
      when(() => gmail.status()).thenThrow(const GmailNetworkFailure());
      build();
      await expectLater(settled(), throwsA(isA<GmailNetworkFailure>()));
    });
  });

  group('connect', () {
    test('éxito guarda la conexión y limpia el fallo', () async {
      when(() => gmail.connect()).thenAnswer((_) async => _active);
      build();
      await settled();

      final ok = await controller().connect();

      expect(ok, isTrue);
      expect(current().info, _active);
      expect(current().busy, isFalse);
      expect(current().failure, isNull);
      expect(current().shouldPrompt, isFalse);
    });

    test('marca busy mientras corre e ignora un segundo toque', () async {
      final pending = Completer<GmailConnectionInfo>();
      when(() => gmail.connect()).thenAnswer((_) => pending.future);
      build();
      await settled();

      final first = controller().connect();
      expect(current().busy, isTrue);
      expect(await controller().connect(), isFalse);

      pending.complete(_active);
      expect(await first, isTrue);
      verify(() => gmail.connect()).called(1);
    });

    test('cancelar no es un error', () async {
      when(() => gmail.connect()).thenThrow(const GmailConsentCancelled());
      build();
      await settled();

      expect(await controller().connect(), isFalse);
      expect(current().busy, isFalse);
      expect(current().failure, isNull);
      expect(current().info, GmailConnectionInfo.disconnected);
    });

    test('un fallo queda en el estado para la pantalla', () async {
      when(() => gmail.connect()).thenThrow(const GmailRefreshTokenMissing());
      build();
      await settled();

      expect(await controller().connect(), isFalse);
      expect(current().failure, isA<GmailRefreshTokenMissing>());
      expect(current().busy, isFalse);
    });

    test('reintentar tras un fallo lo limpia', () async {
      var calls = 0;
      when(() => gmail.connect()).thenAnswer((_) async {
        if (calls++ == 0) throw const GmailUpstreamUnavailable();
        return _active;
      });
      build();
      await settled();

      await controller().connect();
      expect(current().failure, isA<GmailUpstreamUnavailable>());
      await controller().connect();
      expect(current().failure, isNull);
      expect(current().info, _active);
    });

    test('sin sesión no abre el consentimiento', () async {
      build(user: null);
      await settled();

      expect(await controller().connect(), isFalse);
      verifyNever(() => gmail.connect());
    });

    test('sin estado cargado no hace nada', () async {
      when(() => gmail.status()).thenThrow(const GmailNetworkFailure());
      build();
      await expectLater(settled(), throwsA(isA<GmailFailure>()));

      expect(await controller().connect(), isFalse);
      verifyNever(() => gmail.connect());
    });
  });

  group('skip', () {
    test('guarda "Ahora no" para el usuario y deja de preguntar', () async {
      build();
      await settled();

      await controller().skip();

      verify(() => prompts.dismiss('u-1')).called(1);
      expect(current().promptDismissed, isTrue);
      expect(current().shouldPrompt, isFalse);
    });

    test('sin sesión no guarda nada', () async {
      build(user: null);
      await settled();

      await controller().skip();

      verifyNever(() => prompts.dismiss(any()));
    });
  });

  group('refresh', () {
    test('vuelve a leer el estado del backend', () async {
      build();
      await settled();
      when(() => gmail.status()).thenAnswer((_) async => _active);

      await controller().refresh();

      expect(current().info, _active);
      expect(current().failure, isNull);
    });

    test('un fallo conserva el último estado conocido', () async {
      build();
      await settled();
      when(() => gmail.status()).thenThrow(const GmailNetworkFailure());

      await controller().refresh();

      expect(current().info, GmailConnectionInfo.disconnected);
      expect(current().failure, isA<GmailNetworkFailure>());
    });

    test('desde un error reconstruye el estado', () async {
      when(() => gmail.status()).thenThrow(const GmailNetworkFailure());
      build();
      await expectLater(settled(), throwsA(isA<GmailFailure>()));
      when(() => gmail.status()).thenAnswer((_) async => _active);

      await controller().refresh();

      expect(current().info, _active);
    });
  });

  group('disconnect', () {
    test('borra la conexión en el backend y queda disconnected', () async {
      when(() => gmail.status()).thenAnswer((_) async => _active);
      when(() => gmail.disconnect()).thenAnswer((_) async {});
      build();
      await settled();

      expect(await controller().disconnect(), isTrue);

      verify(() => gmail.disconnect()).called(1);
      expect(current().info, GmailConnectionInfo.disconnected);
      expect(current().busy, isFalse);
    });

    test('un fallo deja la conexión como estaba', () async {
      when(() => gmail.status()).thenAnswer((_) async => _active);
      when(() => gmail.disconnect()).thenThrow(const GmailNetworkFailure());
      build();
      await settled();

      expect(await controller().disconnect(), isFalse);

      expect(current().info, _active);
      expect(current().failure, isA<GmailNetworkFailure>());
    });
  });
}
