import 'dart:async';

import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:finanzia/features/review/application/review_list_controller.dart';
import 'package:finanzia/features/review/application/review_providers.dart';
import 'package:finanzia/features/review/domain/review_item.dart';
import 'package:finanzia/features/review/domain/review_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements ReviewRepository {}

/// Sesión controlable desde el test.
class _Auth extends AuthController {
  @override
  Future<AuthState> build() async => const Authenticated(_ana);

  void emit(AuthState next) => state = AsyncData(next);
}

const _ana = User(id: 'ana', email: 'ana@b.co', status: UserStatus.active);
const _beto = User(id: 'beto', email: 'beto@b.co', status: UserStatus.active);

ReviewItem _item(String id) => ReviewItem(
  rawMessageId: id,
  channel: 'notification',
  sender: 'com.bancolombia.app',
  receivedAt: DateTime.utc(2026, 9, 23),
  reason: 'no_template',
  partialExtract: const {},
);

void main() {
  late _Repository repository;
  late StreamController<List<ReviewItem>> rows;
  late ProviderContainer container;

  setUp(() async {
    repository = _Repository();
    rows = StreamController<List<ReviewItem>>.broadcast();
    when(() => repository.watchOpen()).thenAnswer((_) => rows.stream);
    container = ProviderContainer(
      overrides: [
        reviewRepositoryProvider.overrideWithValue(repository),
        authControllerProvider.overrideWith(_Auth.new),
      ],
    );
    await container.read(authControllerProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await rows.close();
  });

  AsyncValue<List<ReviewItem>> state() =>
      container.read(reviewListControllerProvider);

  void start() => container.listen(reviewListControllerProvider, (_, _) {});

  test('arranca cargando y muestra los mensajes abiertos', () async {
    start();
    expect(state(), isA<AsyncLoading<List<ReviewItem>>>());

    rows.add([_item('r1'), _item('r2')]);
    await pumpEventQueue();

    expect(state().value, [_item('r1'), _item('r2')]);
  });

  test('sigue los cambios de la base local', () async {
    start();
    rows.add([_item('r1'), _item('r2')]);
    await pumpEventQueue();

    rows.add([_item('r2')]);
    await pumpEventQueue();

    expect(state().value, [_item('r2')]);
  });

  test('propaga el error de la base local', () async {
    start();
    rows.addError(StateError('db'));
    await pumpEventQueue();

    expect(state().error, isA<StateError>());
  });

  test('al cambiar de usuario vuelve a suscribirse', () async {
    start();
    rows.add([_item('r1')]);
    await pumpEventQueue();
    verify(() => repository.watchOpen()).called(1);

    (container.read(authControllerProvider.notifier) as _Auth).emit(
      const Authenticated(_beto),
    );
    await pumpEventQueue();

    verify(() => repository.watchOpen()).called(1);
  });

  test('reviewItemProvider sigue un mensaje por id', () async {
    final one = StreamController<ReviewItem?>.broadcast();
    addTearDown(one.close);
    when(() => repository.watchOne('r1')).thenAnswer((_) => one.stream);
    container.listen(reviewItemProvider('r1'), (_, _) {});

    one.add(_item('r1'));
    await pumpEventQueue();
    expect(container.read(reviewItemProvider('r1')).value, _item('r1'));

    one.add(null);
    await pumpEventQueue();
    expect(container.read(reviewItemProvider('r1')).value, isNull);
  });

  test('el puerto sin sobrescribir falla', () {
    final bare = ProviderContainer();
    addTearDown(bare.dispose);

    expect(
      () => bare.read(reviewRepositoryProvider),
      throwsA(anything),
    );
  });
}
