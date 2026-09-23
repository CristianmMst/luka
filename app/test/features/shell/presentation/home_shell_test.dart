import 'package:finanzia/app/app.dart';
import 'package:finanzia/app/router.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/domain/sync_ports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSyncStore extends Mock implements SyncStore {}

class _FixedAuthController extends AuthController {
  _FixedAuthController(this._state);

  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

class _FixedCoordinator extends SyncCoordinator {
  _FixedCoordinator(this._status);

  final SyncStatus _status;

  @override
  SyncStatus build() => _status;
}

void main() {
  const user = User(id: 'u', email: 'a@b.co', status: UserStatus.active);
  late _MockSyncStore store;

  setUp(() {
    store = _MockSyncStore();
  });

  ProviderContainer buildContainer({
    AuthState auth = const Authenticated(user),
    int reviewCount = 0,
  }) {
    when(
      () => store.watchOpenReviewCount(),
    ).thenAnswer((_) => Stream.value(reviewCount));
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _FixedAuthController(auth)),
        syncCoordinatorProvider.overrideWith(
          () => _FixedCoordinator(const SyncStatus()),
        ),
        syncStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> pumpShell(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FinanziaApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la barra inferior muestra los 5 destinos', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpShell(tester, buildContainer());

    // Registrar es un botón circular sin texto visible; solo lleva
    // semantics (diseño ListaB).
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.bySemanticsLabel('Registrar'), findsOneWidget);
    expect(find.text('Revisión'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('tocar un destino cambia de rama', (tester) async {
    await pumpShell(tester, buildContainer());

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();

    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('tocar Movimientos muestra su marcador', (tester) async {
    await pumpShell(tester, buildContainer());

    await tester.tap(find.text('Movimientos'));
    await tester.pumpAndSettle();

    expect(find.text('Llega pronto'), findsNothing);
    expect(find.text('Movimientos'), findsWidgets);
  });

  testWidgets('el badge de Revisión se ve con conteo > 0', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpShell(tester, buildContainer(reviewCount: 2));

    expect(find.text('2'), findsOneWidget);
    expect(find.bySemanticsLabel('2 por revisar'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('el badge de Revisión se oculta con conteo 0', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpShell(tester, buildContainer());

    expect(find.text('0'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('por revisar')), findsNothing);
    handle.dispose();
  });

  testWidgets('una ruta del shell sin sesión redirige a login', (
    tester,
  ) async {
    final container = buildContainer(auth: const Unauthenticated());
    await pumpShell(tester, container);

    container.read(routerProvider).go(Routes.transactions);
    await tester.pumpAndSettle();

    expect(find.text('Continuar con Google'), findsOneWidget);
  });
}
