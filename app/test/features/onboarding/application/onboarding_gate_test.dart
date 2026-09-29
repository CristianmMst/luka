import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/domain/auth_repository.dart';
import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:finanzia/features/capture/application/capture_flusher.dart';
import 'package:finanzia/features/capture/application/notification_access_controller.dart';
import 'package:finanzia/features/capture/domain/capture_ports.dart';
import 'package:finanzia/features/gmail/application/gmail_controller.dart';
import 'package:finanzia/features/gmail/domain/gmail_connection.dart';
import 'package:finanzia/features/gmail/domain/gmail_failure.dart';
import 'package:finanzia/features/gmail/domain/gmail_repository.dart';
import 'package:finanzia/features/onboarding/application/onboarding_gate.dart';
import 'package:finanzia/features/onboarding/domain/onboarding_step.dart';
import 'package:finanzia/features/onboarding/domain/onboarding_store.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGmail extends Mock implements GmailRepository {}

class _MockStore extends Mock implements OnboardingStore {}

class _MockAuth extends Mock implements AuthRepository {}

class _MockSource extends Mock implements NotificationSource {}

const _ana = User(
  id: 'u-1',
  email: 'ana@example.com',
  status: UserStatus.active,
);

const _active = GmailConnectionInfo(status: GmailStatus.active);

void main() {
  late _MockGmail gmail;
  late _MockStore store;
  late _MockAuth auth;
  late _MockSource source;
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
              onboardingStoreProvider.overrideWithValue(store),
              notificationSourceProvider.overrideWithValue(source),
              foregroundTicksProvider.overrideWithValue(const Stream.empty()),
            ],
          )
          // El router lo escucha así: lo mantiene vivo.
          ..listen(onboardingGateProvider, (_, _) {});
  }

  OnboardingGate gate() => container.read(onboardingGateProvider);

  Future<void> settle() async {
    await container.read(onboardingDoneProvider.future);
    try {
      await container.read(gmailControllerProvider.future);
    } on GmailFailure {
      // El gate lo trata como "no activo".
    }
    await container.read(notificationAccessProvider.future);
  }

  setUp(() {
    gmail = _MockGmail();
    store = _MockStore();
    auth = _MockAuth();
    source = _MockSource();
    when(() => auth.sessionExpired).thenAnswer((_) => const Stream.empty());
    when(
      () => gmail.status(),
    ).thenAnswer((_) async => GmailConnectionInfo.disconnected);
    var done = false;
    when(() => store.isDone(any())).thenAnswer((_) async => done);
    when(() => store.markDone(any())).thenAnswer((_) async => done = true);
    when(() => source.isSupported).thenReturn(true);
    when(() => source.readsNotifications).thenReturn(true);
    when(() => source.isPermissionGranted()).thenAnswer((_) async => false);
  });

  tearDown(() => container.dispose());

  test('mientras se lee el estado → pendiente', () {
    final pending = Completer<GmailConnectionInfo>();
    when(() => gmail.status()).thenAnswer((_) => pending.future);
    build();
    expect(gate(), const OnboardingPending());
  });

  test('sin nada resuelto → desde Gmail', () async {
    build();
    await settle();
    expect(gate(), const OnboardingShow(OnboardingStep.gmail));
  });

  test('Gmail activo → desde notificaciones', () async {
    when(() => gmail.status()).thenAnswer((_) async => _active);
    build();
    await settle();
    expect(gate(), const OnboardingShow(OnboardingStep.notifications));
  });

  test('Gmail activo y acceso concedido → Cuentas', () async {
    when(() => gmail.status()).thenAnswer((_) async => _active);
    when(() => source.isPermissionGranted()).thenAnswer((_) async => true);
    build();
    await settle();
    expect(gate(), const OnboardingShow(OnboardingStep.accounts));
  });

  test('sin captura nativa no hay paso de notificaciones', () async {
    when(() => gmail.status()).thenAnswer((_) async => _active);
    when(() => source.isSupported).thenReturn(false);
    when(() => source.readsNotifications).thenReturn(false);
    build();
    await settle();
    expect(gate(), const OnboardingShow(OnboardingStep.accounts));
  });

  test('en iOS la guía de Apple Pay va en lugar de notificaciones', () async {
    when(() => gmail.status()).thenAnswer((_) async => _active);
    when(() => source.readsNotifications).thenReturn(false);
    build();
    await settle();

    expect(gate(), const OnboardingShow(OnboardingStep.applePay));
    final flow = container.read(onboardingFlowProvider);
    expect(flow.steps, [
      OnboardingStep.gmail,
      OnboardingStep.applePay,
      OnboardingStep.accounts,
    ]);
    expect(flow.next(OnboardingStep.gmail), OnboardingStep.applePay);
    expect(flow.next(OnboardingStep.applePay), OnboardingStep.accounts);
  });

  test('terminado → skip sin esperar el estado de red', () async {
    final pending = Completer<GmailConnectionInfo>();
    when(() => gmail.status()).thenAnswer((_) => pending.future);
    when(() => store.isDone('u-1')).thenAnswer((_) async => true);
    build();
    await container.read(onboardingDoneProvider.future);

    expect(container.read(gmailControllerProvider).isLoading, isTrue);
    expect(gate(), const OnboardingSkip());
    pending.complete(GmailConnectionInfo.disconnected);
  });

  test('sin red → desde Gmail, cuya pantalla ofrece reintentar', () async {
    when(() => gmail.status()).thenThrow(const GmailNetworkFailure());
    build();
    await settle();
    expect(gate(), const OnboardingShow(OnboardingStep.gmail));
  });

  test('sin sesión → skip', () async {
    build(user: null);
    await container.read(onboardingDoneProvider.future);
    expect(gate(), const OnboardingSkip());
  });

  test('terminar guarda la marca y pasa a skip', () async {
    build();
    await settle();

    await container.read(onboardingFlowProvider).finish();
    await container.read(onboardingDoneProvider.future);

    verify(() => store.markDone('u-1')).called(1);
    expect(gate(), const OnboardingSkip());
  });

  test('tras el login vuelve a pendiente en el mismo instante, sin '
      'arrastrar el skip de la sesión cerrada', () async {
    build(user: null);
    await container.read(onboardingDoneProvider.future);
    expect(gate(), const OnboardingSkip());

    final pending = Completer<GmailConnectionInfo>();
    when(() => gmail.status()).thenAnswer((_) => pending.future);
    container.read(authControllerProvider.notifier).signedIn(_ana);

    // Lo que el redirect del router lee justo después del cambio de sesión.
    expect(gate(), const OnboardingPending());
    pending.complete(GmailConnectionInfo.disconnected);
    await settle();
    expect(gate(), const OnboardingShow(OnboardingStep.gmail));
  });

  test('si el estado tarda más que el timeout, muestra desde Gmail', () {
    fakeAsync((async) {
      final pending = Completer<GmailConnectionInfo>();
      when(() => gmail.status()).thenAnswer((_) => pending.future);
      build();
      async.flushMicrotasks();
      expect(gate(), const OnboardingPending());

      async.elapse(
        OnboardingGateController.timeout - const Duration(milliseconds: 1),
      );
      expect(gate(), const OnboardingPending());
      async.elapse(const Duration(milliseconds: 1));
      expect(gate(), const OnboardingShow(OnboardingStep.gmail));

      // Cuando por fin llega, manda el estado real.
      pending.complete(_active);
      async.flushMicrotasks();
      expect(gate(), const OnboardingShow(OnboardingStep.notifications));
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
      expect(gate(), const OnboardingPending());

      // Restaurar la sesión tarda 3 s: no se descuenta del tope.
      async.elapse(const Duration(seconds: 3));
      restored.complete(_ana);
      async.flushMicrotasks();
      expect(gate(), const OnboardingPending());

      async.elapse(
        OnboardingGateController.timeout - const Duration(milliseconds: 1),
      );
      expect(gate(), const OnboardingPending());
      async.elapse(const Duration(milliseconds: 1));
      expect(gate(), const OnboardingShow(OnboardingStep.gmail));
      pending.complete(GmailConnectionInfo.disconnected);
      async.flushMicrotasks();
    });
  });

  group('next', () {
    test('tras Gmail, notificaciones si falta el acceso', () async {
      build();
      await settle();
      expect(
        container.read(onboardingFlowProvider).next(OnboardingStep.gmail),
        OnboardingStep.notifications,
      );
    });

    test('tras Gmail, Cuentas si el acceso ya está', () async {
      when(() => source.isPermissionGranted()).thenAnswer((_) async => true);
      build();
      await settle();
      expect(
        container.read(onboardingFlowProvider).next(OnboardingStep.gmail),
        OnboardingStep.accounts,
      );
    });

    test('tras Cuentas no hay más', () async {
      build();
      await settle();
      final flow = container.read(onboardingFlowProvider);
      expect(flow.next(OnboardingStep.notifications), OnboardingStep.accounts);
      expect(flow.next(OnboardingStep.accounts), isNull);
    });
  });
}
