import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/auth/domain/auth_repository.dart';
import 'package:luka/features/auth/domain/entities/user.dart';
import 'package:luka/features/push/application/push_registrar.dart';
import 'package:luka/features/push/domain/push_ports.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AuthRepository {}

class _Remote extends Mock implements PushTokenRemote {}

class _Prefs implements PushPrefs {
  bool asked = false;

  @override
  Future<bool> permissionAsked() async => asked;

  @override
  Future<void> markPermissionAsked() async => asked = true;
}

class _FakePush implements PushService {
  PushPermission current = PushPermission.notDetermined;
  PushPermission onRequest = PushPermission.granted;
  String? currentToken = 'tok-1';
  PushOpen? initial;
  int deletes = 0;
  final refresh = StreamController<String>.broadcast();
  final opened = StreamController<PushOpen>.broadcast();
  final foreground = StreamController<PushOpen>.broadcast();

  @override
  bool get isAvailable => true;

  @override
  String get platform => 'android';

  @override
  Future<PushPermission> permission() async => current;

  @override
  Future<PushPermission> requestPermission() async => current = onRequest;

  @override
  Future<String?> token() async => currentToken;

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Future<PushOpen?> initialOpen() async => initial;

  @override
  Stream<PushOpen> get onOpened => opened.stream;

  @override
  Stream<PushOpen> get onForeground => foreground.stream;

  @override
  Future<void> deleteToken() async => deletes++;
}

const _ana = User(
  id: 'u-1',
  email: 'ana@example.com',
  status: UserStatus.active,
  displayName: 'Ana',
);

void main() {
  late _MockRepository repository;
  late _Remote remote;
  late _Prefs prefs;
  late _FakePush push;

  setUp(() {
    repository = _MockRepository();
    remote = _Remote();
    prefs = _Prefs();
    push = _FakePush();
    when(
      () => repository.sessionExpired,
    ).thenAnswer((_) => const Stream.empty());
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
    when(() => repository.signOut()).thenAnswer((_) async {});
    when(() => remote.register(any(), any())).thenAnswer((_) async {});
    when(() => remote.unregister(any())).thenAnswer((_) async {});
  });

  ProviderContainer build({PushService? service}) {
    final c = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        pushServiceProvider.overrideWithValue(service ?? push),
        pushTokenRemoteProvider.overrideWithValue(remote),
        pushPrefsProvider.overrideWithValue(prefs),
        signOutHooksProvider.overrideWith(
          (ref) => [
            () => ref.read(pushRegistrarProvider.notifier).unregister(),
          ],
        ),
      ],
    );
    addTearDown(c.dispose);
    c.listen(pushRegistrarProvider, (_, _) {});
    return c;
  }

  Future<void> signIn(ProviderContainer c) async {
    await c.read(authControllerProvider.future);
    c.read(authControllerProvider.notifier).signedIn(_ana);
    await pumpEventQueue();
  }

  test('con permiso concedido registra el token al entrar', () async {
    push.current = PushPermission.granted;
    final c = build();

    await signIn(c);

    verify(() => remote.register('tok-1', 'android')).called(1);
  });

  test('sin permiso no registra nada', () async {
    final c = build();

    await signIn(c);

    verifyNever(() => remote.register(any(), any()));
  });

  test('un token renovado se registra de nuevo', () async {
    push.current = PushPermission.granted;
    final c = build();
    await signIn(c);

    push.refresh.add('tok-2');
    await pumpEventQueue();

    verify(() => remote.register('tok-2', 'android')).called(1);
  });

  test('explica el permiso una vez; aceptarlo registra el token', () async {
    final c = build();
    await signIn(c);
    final registrar = c.read(pushRegistrarProvider.notifier);

    expect(await registrar.shouldExplainPermission(), isTrue);
    final permission = await registrar.requestPermission();

    expect(permission, PushPermission.granted);
    expect(prefs.asked, isTrue);
    expect(await registrar.shouldExplainPermission(), isFalse);
    expect(c.read(pushRegistrarProvider).permission, PushPermission.granted);
    verify(() => remote.register('tok-1', 'android')).called(1);
  });

  test('un aviso tocado queda pendiente hasta que la app lo abre', () async {
    push.initial = const PushOpen(occurrenceId: 'o-1');
    final c = build();
    await pumpEventQueue();

    expect(c.read(pushRegistrarProvider).pendingOpen?.occurrenceId, 'o-1');
    c.read(pushRegistrarProvider.notifier).consumeOpen();
    expect(c.read(pushRegistrarProvider).pendingOpen, isNull);

    push.foreground.add(const PushOpen(occurrenceId: 'o-2'));
    await pumpEventQueue();
    expect(c.read(pushRegistrarProvider).foreground?.occurrenceId, 'o-2');
    c.read(pushRegistrarProvider.notifier).consumeForeground();
    expect(c.read(pushRegistrarProvider).foreground, isNull);
  });

  test('cerrar sesión borra el token en el servidor y en FCM', () async {
    push.current = PushPermission.granted;
    final c = build();
    await signIn(c);

    await c.read(authControllerProvider.notifier).signOut();

    verify(() => remote.unregister('tok-1')).called(1);
    expect(push.deletes, 1);
    verify(() => repository.signOut()).called(1);
  });

  test('si borrar el token falla, la sesión se cierra igual', () async {
    push.current = PushPermission.granted;
    when(() => remote.unregister(any())).thenThrow(Exception('sin red'));
    final c = build();
    await signIn(c);

    await c.read(authControllerProvider.notifier).signOut();

    verify(() => repository.signOut()).called(1);
    expect(
      c.read(authControllerProvider).value,
      isA<Unauthenticated>(),
    );
  });

  test('sin Firebase no hace nada', () async {
    final c = build(service: const DisabledPushService());
    await signIn(c);
    final registrar = c.read(pushRegistrarProvider.notifier);

    expect(await registrar.shouldExplainPermission(), isFalse);
    expect(await registrar.requestPermission(), PushPermission.denied);
    await registrar.unregister();
    verifyNever(() => remote.register(any(), any()));
    verifyNever(() => remote.unregister(any()));
  });

  test('PushOpen solo acepta recordatorios de gastos fijos', () {
    expect(
      PushOpen.fromData({'type': 'recurring_due', 'occurrence_id': 'o-1'}),
      const PushOpen(occurrenceId: 'o-1'),
    );
    expect(PushOpen.fromData({'type': 'otro', 'occurrence_id': 'o-1'}), isNull);
    expect(PushOpen.fromData({'type': 'recurring_due'}), isNull);
    expect(
      PushOpen.fromData({'type': 'recurring_due', 'occurrence_id': ''}),
      isNull,
    );
  });
}
