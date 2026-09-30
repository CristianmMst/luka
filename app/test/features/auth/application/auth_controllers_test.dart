import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/auth/application/sign_in_controller.dart';
import 'package:luka/features/auth/domain/auth_failure.dart';
import 'package:luka/features/auth/domain/auth_repository.dart';
import 'package:luka/features/auth/domain/entities/user.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AuthRepository {}

const _ana = User(
  id: 'u-1',
  email: 'ana@example.com',
  status: UserStatus.active,
  displayName: 'Ana',
);

void main() {
  late _MockRepository repository;
  late StreamController<void> expired;
  late ProviderContainer container;

  setUp(() {
    repository = _MockRepository();
    expired = StreamController<void>.broadcast();
    when(() => repository.sessionExpired).thenAnswer((_) => expired.stream);
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
    when(() => repository.signOut()).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() async {
    container.dispose();
    await expired.close();
  });

  group('AuthController', () {
    test('arranca en loading y resuelve la sesión restaurada', () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => _ana);
      expect(
        container.read(authControllerProvider),
        isA<AsyncLoading<AuthState>>(),
      );
      final state = await container.read(authControllerProvider.future);
      expect(state, isA<Authenticated>());
    });

    test('sin sesión → Unauthenticated', () async {
      expect(
        await container.read(authControllerProvider.future),
        isA<Unauthenticated>(),
      );
    });

    test('restore que falla → Unauthenticated', () async {
      when(
        () => repository.restoreSession(),
      ).thenThrow(const AuthNetworkFailure());
      expect(
        await container.read(authControllerProvider.future),
        isA<Unauthenticated>(),
      );
    });

    test('sesión expirada desde la red → Unauthenticated(expired)', () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => _ana);
      await container.read(authControllerProvider.future);

      expired.add(null);
      await pumpEventQueue();

      final state = container.read(authControllerProvider).value;
      expect(
        state,
        isA<Unauthenticated>().having(
          (s) => s.sessionExpired,
          'sessionExpired',
          isTrue,
        ),
      );
    });

    test('signOut → Unauthenticated', () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => _ana);
      await container.read(authControllerProvider.future);
      await container.read(authControllerProvider.notifier).signOut();
      verify(() => repository.signOut()).called(1);
      expect(
        container.read(authControllerProvider).value,
        isA<Unauthenticated>(),
      );
    });
  });

  group('SignInController', () {
    late ProviderSubscription<AsyncValue<void>> sub;

    setUp(() async {
      await container.read(authControllerProvider.future);
      sub = container.listen(signInControllerProvider, (_, _) {});
    });

    tearDown(() => sub.close());

    Future<void> signIn() =>
        container.read(signInControllerProvider.notifier).signIn();

    test('éxito: autentica la sesión global', () async {
      when(() => repository.signInWithGoogle()).thenAnswer((_) async => _ana);
      await signIn();
      expect(sub.read(), isA<AsyncData<void>>());
      expect(
        container.read(authControllerProvider).value,
        isA<Authenticated>(),
      );
    });

    test('cancelar no es error', () async {
      when(
        () => repository.signInWithGoogle(),
      ).thenThrow(const AuthCancelled());
      await signIn();
      expect(sub.read(), isA<AsyncData<void>>());
    });

    test('falla tipada queda en AsyncError', () async {
      when(
        () => repository.signInWithGoogle(),
      ).thenThrow(const AuthNetworkFailure());
      await signIn();
      expect(sub.read().error, isA<AuthNetworkFailure>());
      expect(
        container.read(authControllerProvider).value,
        isA<Unauthenticated>(),
      );
    });

    test('un segundo toque mientras carga se ignora', () async {
      final pending = Completer<User>();
      when(
        () => repository.signInWithGoogle(),
      ).thenAnswer((_) => pending.future);
      final first = signIn();
      await signIn();
      pending.complete(_ana);
      await first;
      verify(() => repository.signInWithGoogle()).called(1);
    });
  });
}
