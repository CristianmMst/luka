import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/domain/auth_repository.dart';
import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:finanzia/features/gmail/application/gmail_controller.dart';
import 'package:finanzia/features/gmail/application/gmail_gate.dart';
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

void main() {
  late _MockGmail gmail;
  late _MockPrompts prompts;
  late _MockAuth auth;
  late ProviderContainer container;

  ProviderContainer build({User? user = _ana, Future<User?>? restored}) {
    when(
      () => auth.restoreSession(),
    ).thenAnswer((_) => restored ?? Future.value(user));
    return container =
        ProviderContainer(
            overrides: [
              authRepositoryProvider.overrideWithValue(auth),
              gmailRepositoryProvider.overrideWithValue(gmail),
              gmailPromptStoreProvider.overrideWithValue(prompts),
            ],
          )
          // El router lo escucha así: lo mantiene vivo.
          ..listen(gmailGateProvider, (_, _) {});
  }

  GmailGate gate() => container.read(gmailGateProvider);

  Future<void> settle() async {
    try {
      await container.read(gmailControllerProvider.future);
    } on GmailFailure {
      // El gate lo traduce a skip.
    }
  }

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

  test('mientras se lee el estado → pending', () {
    final pending = Completer<GmailConnectionInfo>();
    when(() => gmail.status()).thenAnswer((_) => pending.future);
    build();
    expect(gate(), GmailGate.pending);
  });

  test('sin conectar ni descartar → prompt', () async {
    build();
    await settle();
    expect(gate(), GmailGate.prompt);
  });

  test('activo → skip', () async {
    when(() => gmail.status()).thenAnswer(
      (_) async => const GmailConnectionInfo(status: GmailStatus.active),
    );
    build();
    await settle();
    expect(gate(), GmailGate.skip);
  });

  test('"Ahora no" guardado → skip', () async {
    when(() => prompts.isDismissed('u-1')).thenAnswer((_) async => true);
    build();
    await settle();
    expect(gate(), GmailGate.skip);
  });

  test('"Ahora no" guardado → skip sin esperar el estado de red', () async {
    final pending = Completer<GmailConnectionInfo>();
    when(() => gmail.status()).thenAnswer((_) => pending.future);
    when(() => prompts.isDismissed('u-1')).thenAnswer((_) async => true);
    build();
    await container.read(gmailPromptDismissedProvider.future);

    expect(container.read(gmailControllerProvider).isLoading, isTrue);
    expect(gate(), GmailGate.skip);
    pending.complete(GmailConnectionInfo.disconnected);
  });

  test('sin red → skip: Gmail es opcional', () async {
    when(() => gmail.status()).thenThrow(const GmailNetworkFailure());
    build();
    await settle();
    expect(gate(), GmailGate.skip);
  });

  test('sin sesión → skip', () async {
    build(user: null);
    await settle();
    expect(gate(), GmailGate.skip);
  });

  test('"Ahora no" en la pantalla pasa a skip', () async {
    build();
    await settle();
    await container.read(gmailControllerProvider.notifier).skip();
    expect(gate(), GmailGate.skip);
  });

  test('tras el login vuelve a pending en el mismo instante, sin arrastrar '
      'el skip de la sesión cerrada', () async {
    build(user: null);
    await settle();
    expect(gate(), GmailGate.skip);

    final pending = Completer<GmailConnectionInfo>();
    when(() => gmail.status()).thenAnswer((_) => pending.future);
    container.read(authControllerProvider.notifier).signedIn(_ana);

    // Lo que el redirect del router lee justo después del cambio de sesión.
    expect(gate(), GmailGate.pending);
    pending.complete(GmailConnectionInfo.disconnected);
    await settle();
    expect(gate(), GmailGate.prompt);
  });

  test('si el estado tarda más que el timeout, deja pasar a Inicio', () {
    fakeAsync((async) {
      final pending = Completer<GmailConnectionInfo>();
      when(() => gmail.status()).thenAnswer((_) => pending.future);
      build();
      async.flushMicrotasks();
      expect(gate(), GmailGate.pending);

      async.elapse(
        GmailGateController.timeout - const Duration(milliseconds: 1),
      );
      expect(gate(), GmailGate.pending);
      async.elapse(const Duration(milliseconds: 1));
      expect(gate(), GmailGate.skip);

      // Cuando por fin llega, manda el estado real.
      pending.complete(GmailConnectionInfo.disconnected);
      async.flushMicrotasks();
      expect(gate(), GmailGate.prompt);
    });
  });

  test('el tope arranca cuando la sesión es Authenticated, no al primer '
      'read', () {
    fakeAsync((async) {
      final restored = Completer<User?>();
      final pending = Completer<GmailConnectionInfo>();
      when(() => gmail.status()).thenAnswer((_) => pending.future);
      build(restored: restored.future);
      async.flushMicrotasks();
      expect(gate(), GmailGate.pending);

      // Restaurar la sesión tarda 3 s: no se descuenta del tope de Gmail.
      async.elapse(const Duration(seconds: 3));
      restored.complete(_ana);
      async.flushMicrotasks();
      expect(gate(), GmailGate.pending);

      async.elapse(
        GmailGateController.timeout - const Duration(milliseconds: 1),
      );
      expect(gate(), GmailGate.pending);
      async.elapse(const Duration(milliseconds: 1));
      expect(gate(), GmailGate.skip);
      pending.complete(GmailConnectionInfo.disconnected);
      async.flushMicrotasks();
    });
  });

  test('una sesión nueva rearma el tope', () {
    fakeAsync((async) {
      build(user: null);
      async.flushMicrotasks();
      expect(gate(), GmailGate.skip);

      // Sin sesión no corre ningún tope: el login llega mucho después.
      async.elapse(const Duration(seconds: 30));
      final pending = Completer<GmailConnectionInfo>();
      when(() => gmail.status()).thenAnswer((_) => pending.future);
      container.read(authControllerProvider.notifier).signedIn(_ana);
      async.flushMicrotasks();
      expect(gate(), GmailGate.pending);

      async.elapse(GmailGateController.timeout);
      expect(gate(), GmailGate.skip);
      pending.complete(GmailConnectionInfo.disconnected);
      async.flushMicrotasks();
    });
  });
}
