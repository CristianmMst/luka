import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/auth/domain/entities/user.dart';
import 'package:luka/features/dashboard/application/dashboard_controller.dart';
import 'package:luka/features/dashboard/application/dashboard_providers.dart';
import 'package:luka/features/dashboard/domain/insights_repository.dart';
import 'package:luka/features/dashboard/domain/monthly_summary.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements InsightsRepository {}

/// Sesión controlable desde el test.
class _Auth extends AuthController {
  @override
  Future<AuthState> build() async => const Authenticated(_ana);

  void emit(AuthState next) => state = AsyncData(next);
}

const _ana = User(id: 'ana', email: 'ana@b.co', status: UserStatus.active);
const _beto = User(id: 'beto', email: 'beto@b.co', status: UserStatus.active);

MonthlySummary _summary(ColombiaMonth month, {int expensesPesos = 0}) =>
    buildSummary(
      month: month,
      totals: MonthlyTotals(expenses: Cop.pesos(expensesPesos)),
      previousTotals: const MonthlyTotals(),
      spends: const [],
    );

void main() {
  final september = ColombiaMonth(2026, 9);
  final august = ColombiaMonth(2026, 8);
  final july = ColombiaMonth(2026, 7);

  late _Repository repository;
  late Map<ColombiaMonth, StreamController<MonthlySummary>> streams;
  late DateTime now;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(ColombiaMonth(2000, 1)));

  StreamController<MonthlySummary> streamOf(ColombiaMonth month) =>
      streams.putIfAbsent(month, StreamController<MonthlySummary>.broadcast);

  setUp(() async {
    // 2026-09-23 12:00 en Bogota.
    now = DateTime.utc(2026, 9, 23, 17);
    repository = _Repository();
    streams = {};
    when(
      () => repository.watchMonth(any()),
    ).thenAnswer(
      (i) => streamOf(i.positionalArguments.single as ColombiaMonth).stream,
    );
    container = ProviderContainer(
      overrides: [
        insightsRepositoryProvider.overrideWithValue(repository),
        dashboardClockProvider.overrideWithValue(() => now),
        authControllerProvider.overrideWith(_Auth.new),
      ],
    );
    await container.read(authControllerProvider.future);
  });

  tearDown(() async {
    container.dispose();
    for (final stream in streams.values) {
      await stream.close();
    }
  });

  DashboardController controller() =>
      container.read(dashboardControllerProvider.notifier);
  DashboardState state() => container.read(dashboardControllerProvider);

  void start() => container.listen(dashboardControllerProvider, (_, _) {});

  test('arranca en el mes en curso, cargando y sin mes siguiente', () {
    start();

    expect(state().month, september);
    expect(state().currentMonth, september);
    expect(state().summary, isA<AsyncLoading<Object?>>());
    expect(state().canGoNext, isFalse);
    verify(() => repository.watchMonth(september)).called(1);
  });

  test('el mes en curso sale de la hora de Colombia, no de UTC', () {
    // 2026-10-01T04:30Z es el 30 de septiembre a las 23:30 en Bogota.
    now = DateTime.utc(2026, 10, 1, 4, 30);
    start();

    expect(state().month, september);
  });

  test('muestra lo que emite el repositorio y sus cambios', () async {
    start();

    streamOf(september).add(_summary(september, expensesPesos: 10));
    await pumpEventQueue();
    expect(state().summary.requireValue.totals.expenses, Cop.pesos(10));

    streamOf(september).add(_summary(september, expensesPesos: 25));
    await pumpEventQueue();
    expect(state().summary.requireValue.totals.expenses, Cop.pesos(25));
  });

  test('un error del stream queda en summary', () async {
    start();

    streamOf(september).addError(StateError('db'));
    await pumpEventQueue();

    expect(state().summary, isA<AsyncError<Object?>>());
  });

  test('un error del mes nuevo no arrastra las cifras del anterior', () async {
    start();
    streamOf(september).add(_summary(september, expensesPesos: 10));
    await pumpEventQueue();

    controller().previousMonth();
    streamOf(august).addError(StateError('db'));
    await pumpEventQueue();

    // Sin valor, el Inicio pinta el error y no las cifras de septiembre.
    expect(state().month, august);
    expect(state().summary.hasError, isTrue);
    expect(state().summary.hasValue, isFalse);
  });

  test('previousMonth retrocede, recarga y habilita el siguiente', () async {
    start();
    streamOf(september).add(_summary(september));
    await pumpEventQueue();

    controller().previousMonth();

    expect(state().month, august);
    // Mientras llega agosto se conservan las cifras de septiembre.
    expect(state().summary.requireValue.month, september);
    expect(state().canGoNext, isTrue);
    verify(() => repository.watchMonth(august)).called(1);

    streamOf(august).add(_summary(august, expensesPesos: 7));
    await pumpEventQueue();
    expect(state().summary.requireValue.month, august);
  });

  test('previousMonth cruza de enero a diciembre', () {
    now = DateTime.utc(2026, 1, 10, 17);
    start();

    controller().previousMonth();

    expect(state().month, ColombiaMonth(2025, 12));
  });

  test('cambiar de mes cancela la suscripcion anterior', () async {
    start();
    controller().previousMonth();
    await pumpEventQueue();

    expect(streamOf(september).hasListener, isFalse);
    expect(streamOf(august).hasListener, isTrue);

    // Lo que llegue del mes anterior ya no pisa el estado.
    streamOf(september).add(_summary(september));
    await pumpEventQueue();
    expect(state().summary, isA<AsyncLoading<Object?>>());
  });

  test('nextMonth avanza hasta el mes en curso y ahi se detiene', () {
    start();
    controller()
      ..previousMonth()
      ..previousMonth();
    expect(state().month, july);

    controller().nextMonth();
    expect(state().month, august);
    controller().nextMonth();
    expect(state().month, september);
    expect(state().canGoNext, isFalse);

    clearInteractions(repository);
    controller().nextMonth();
    expect(state().month, september);
    verifyNever(() => repository.watchMonth(any()));
  });

  test('si el reloj pasa a otro mes, nextMonth puede seguir', () {
    start();
    now = DateTime.utc(2026, 10, 2, 17);

    controller().nextMonth();

    expect(state().month, ColombiaMonth(2026, 10));
    expect(state().currentMonth, ColombiaMonth(2026, 10));
    expect(state().canGoNext, isFalse);
  });

  test('en el tope, nextMonth solo refresca el mes en curso', () {
    start();
    controller().previousMonth();
    // El reloj retrocede (p. ej. cambio manual de hora): agosto es el tope.
    now = DateTime.utc(2026, 8, 20, 17);

    controller().nextMonth();

    expect(state().month, august);
    expect(state().currentMonth, august);
    expect(state().canGoNext, isFalse);
  });

  test('showCurrentMonth vuelve al mes en curso y recarga', () {
    start();
    controller()
      ..previousMonth()
      ..previousMonth();
    expect(state().month, july);
    clearInteractions(repository);

    controller().showCurrentMonth();

    expect(state().month, september);
    expect(state().canGoNext, isFalse);
    expect(state().summary, isA<AsyncLoading<Object?>>());
    verify(() => repository.watchMonth(september)).called(1);
  });

  test('retry se vuelve a suscribir al mismo mes tras un error', () async {
    start();
    controller().previousMonth();
    streamOf(august).addError(StateError('db'));
    await pumpEventQueue();
    expect(state().summary, isA<AsyncError<Object?>>());
    clearInteractions(repository);

    controller().retry();

    expect(state().month, august);
    expect(state().summary, isA<AsyncLoading<Object?>>());
    verify(() => repository.watchMonth(august)).called(1);
    streamOf(august).add(_summary(august, expensesPesos: 3));
    await pumpEventQueue();
    expect(state().summary.requireValue.totals.expenses, Cop.pesos(3));
  });

  test('dispose cancela la suscripcion', () async {
    start();
    await pumpEventQueue();
    expect(streamOf(september).hasListener, isTrue);

    container.dispose();
    await pumpEventQueue();

    expect(streamOf(september).hasListener, isFalse);
  });

  group('cambio de sesion', () {
    _Auth auth() => container.read(authControllerProvider.notifier) as _Auth;

    void startInAugust() {
      start();
      controller().previousMonth();
      expect(state().month, august);
    }

    test('otro usuario vuelve al mes en curso', () async {
      startInAugust();

      auth().emit(const Authenticated(_beto));
      await pumpEventQueue();

      expect(state().month, september);
      expect(state().summary, isA<AsyncLoading<Object?>>());
      expect(streamOf(august).hasListener, isFalse);
    });

    test('cerrar sesion descarta el mes elegido', () async {
      startInAugust();

      auth().emit(const Unauthenticated());
      await pumpEventQueue();

      expect(state().month, september);
    });

    test('el mismo usuario conserva el mes', () async {
      startInAugust();

      auth().emit(const Authenticated(_ana));
      await pumpEventQueue();

      expect(state().month, august);
    });
  });
}
