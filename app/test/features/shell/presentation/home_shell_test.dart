import 'dart:async';

import 'package:finanzia/app/app.dart';
import 'package:finanzia/app/router.dart';
import 'package:finanzia/core/time/colombia_month.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:finanzia/features/capture/application/capture_flusher.dart';
import 'package:finanzia/features/capture/data/method_channel_notification_source.dart';
import 'package:finanzia/features/dashboard/application/dashboard_providers.dart';
import 'package:finanzia/features/dashboard/domain/insights_repository.dart';
import 'package:finanzia/features/dashboard/domain/monthly_summary.dart';
import 'package:finanzia/features/gmail/application/gmail_controller.dart';
import 'package:finanzia/features/gmail/domain/gmail_connection.dart';
import 'package:finanzia/features/gmail/domain/gmail_repository.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/domain/sync_ports.dart';
import 'package:finanzia/features/transactions/application/transactions_providers.dart';
import 'package:finanzia/features/transactions/domain/transaction_filter.dart';
import 'package:finanzia/features/transactions/domain/transactions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSyncStore extends Mock implements SyncStore {}

class _MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class _MockGmail extends Mock implements GmailRepository {}

/// Inicio se queda cargando: estas pruebas son de la barra inferior.
class _PendingInsights extends Fake implements InsightsRepository {
  @override
  Stream<MonthlySummary> watchMonth(ColombiaMonth month) =>
      const Stream.empty();
}

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
  late _MockTransactionsRepository transactions;
  late _MockGmail gmail;

  setUpAll(() => registerFallbackValue(const TransactionFilter()));

  setUp(() {
    store = _MockSyncStore();
    transactions = _MockTransactionsRepository();
    // Gmail ya conectado: el gate lleva directo al shell.
    gmail = _MockGmail();
    when(() => gmail.status()).thenAnswer(
      (_) async => const GmailConnectionInfo(status: GmailStatus.active),
    );
    when(
      () => transactions.watch(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      () => transactions.watchOne(any()),
    ).thenAnswer((_) => Stream.value(null));
    when(
      () => transactions.watchCategories(),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      () => transactions.fetchSources(any()),
    ).thenAnswer((_) async => const []);
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
        transactionsRepositoryProvider.overrideWithValue(transactions),
        gmailRepositoryProvider.overrideWithValue(gmail),
        notificationSourceProvider.overrideWithValue(
          const NoopNotificationSource(),
        ),
        insightsRepositoryProvider.overrideWithValue(_PendingInsights()),
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

  testWidgets('tocar Movimientos muestra la lista', (tester) async {
    await pumpShell(tester, buildContainer());

    await tester.tap(find.text('Movimientos'));
    await tester.pumpAndSettle();

    expect(find.text('Llega pronto'), findsNothing);
    expect(find.text('Aún no hay movimientos'), findsOneWidget);
  });

  testWidgets(
    'el destino Movimientos no duplica su semantics (etiqueta visible + '
    'Semantics envolvente)',
    (tester) async {
      final handle = tester.ensureSemantics();
      await pumpShell(tester, buildContainer());

      // Antes de la corrección, el `Text(label)` visible (sin excluir de
      // semántica) se fusionaba con el `Semantics(label: ...)` que lo
      // envuelve, y el lector de pantalla anunciaba "Movimientos" dos veces.
      // Con el `ExcludeSemantics` en el label, el nodo queda único y limpio:
      // exactamente un nodo, con su `selected` intacto.
      final movimientos = find.bySemanticsLabel('Movimientos');
      expect(movimientos, findsOneWidget);
      expect(
        tester.getSemantics(movimientos).flagsCollection.isSelected,
        isFalse,
      );

      // Inicio sí está seleccionado por defecto (rama 0): confirma que el
      // estado `selected` se sigue exponiendo correctamente en el nodo único.
      final inicio = find.bySemanticsLabel('Inicio');
      expect(inicio, findsOneWidget);
      expect(tester.getSemantics(inicio).flagsCollection.isSelected, isTrue);

      handle.dispose();
    },
  );

  testWidgets('el badge de Revisión se ve con conteo > 0', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpShell(tester, buildContainer(reviewCount: 2));

    expect(find.text('2'), findsOneWidget);
    expect(find.bySemanticsLabel('2 por revisar'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('el badge de Revisión no se recorta con 10 o más', (
    tester,
  ) async {
    await pumpShell(tester, buildContainer(reviewCount: 12));

    final text = find.text('12');
    expect(text, findsOneWidget);
    final badge = find.ancestor(of: text, matching: find.byType(Container));
    final decoration =
        tester.widget<Container>(badge.first).decoration! as BoxDecoration;
    // Un círculo recorta dos dígitos: la píldora crece a lo ancho.
    expect(decoration.shape, BoxShape.rectangle);
    expect(decoration.borderRadius, isNotNull);
    final badgeSize = tester.getSize(badge.first);
    expect(badgeSize.height, greaterThanOrEqualTo(18));
    expect(
      badgeSize.width,
      greaterThanOrEqualTo(tester.getSize(text).width + 8),
    );
  });

  testWidgets('el detalle se abre a pantalla completa, sin barra inferior', (
    tester,
  ) async {
    final container = buildContainer();
    await pumpShell(tester, container);
    await tester.tap(find.text('Movimientos'));
    await tester.pumpAndSettle();

    unawaited(
      container.read(routerProvider).push('${Routes.transactions}/tx1'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsNothing);
    expect(find.text('Movimientos'), findsNothing);

    container.read(routerProvider).pop();
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Aún no hay movimientos'), findsOneWidget);
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
