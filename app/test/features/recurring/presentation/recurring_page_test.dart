import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/recurring/application/recurring_actions.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';
import 'package:luka/features/recurring/domain/recurring_ports.dart';
import 'package:luka/features/recurring/presentation/occurrence_row.dart';
import 'package:luka/features/recurring/presentation/recurring_page.dart';
import 'package:luka/features/recurring/presentation/recurring_settings_tile.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/domain/category_option.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _Actions extends Mock implements RecurringActions {}

class _Store extends Mock implements RecurringStore {}

/// 15 de octubre de 2026, 10:00 en Colombia.
final _now = DateTime.utc(2026, 10, 15, 15);

const _spotify = RecurringExpense(
  id: 'e-1',
  name: 'Spotify',
  merchantKeyword: 'spotify',
  expectedAmount: Cop(1690000),
  tolerancePct: 10,
  dayOfMonth: 12,
  remindDaysBefore: 1,
  active: true,
);

const _arriendo = RecurringExpense(
  id: 'e-2',
  name: 'Arriendo',
  merchantKeyword: 'inmobiliaria',
  expectedAmount: Cop(150000000),
  tolerancePct: 0,
  dayOfMonth: 28,
  remindDaysBefore: 2,
  active: true,
);

final _paid = RecurringOccurrence(
  id: 'o-1',
  expenseId: 'e-1',
  name: 'Spotify',
  expectedAmount: const Cop(1690000),
  period: '2026-10',
  dueDate: DateTime.utc(2026, 10, 12),
  status: OccurrenceStatus.paid,
  matchedBy: 'auto',
  paidAt: DateTime.utc(2026, 10, 12, 13),
  transactionId: 't-1',
  transactionMerchant: 'SPOTIFY P3A9C1',
  transactionAmount: const Cop(1690000),
  transactionOccurredAt: DateTime.utc(2026, 10, 12, 12),
);

final _pending = RecurringOccurrence(
  id: 'o-2',
  expenseId: 'e-2',
  name: 'Arriendo',
  expectedAmount: const Cop(150000000),
  period: '2026-10',
  dueDate: DateTime.utc(2026, 10, 28),
  status: OccurrenceStatus.pending,
);

void main() {
  late _Actions actions;
  late _Store store;

  setUpAll(() => registerFallbackValue(ColombiaMonth(2026, 10)));

  setUp(() {
    actions = _Actions();
    store = _Store();
    when(() => actions.markPaid(any())).thenAnswer((_) async => _pending);
  });

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    List<RecurringExpense> expenses = const [_spotify, _arriendo],
    List<RecurringOccurrence>? occurrences,
  }) async {
    when(() => store.watchExpenses()).thenAnswer((_) => Stream.value(expenses));
    when(
      () => store.watchOccurrences(any()),
    ).thenAnswer((_) => Stream.value(occurrences ?? [_paid, _pending]));
    await tester.pumpApp(
      child,
      overrides: [
        recurringActionsProvider.overrideWithValue(actions),
        recurringStoreProvider.overrideWithValue(store),
        recurringClockProvider.overrideWithValue(() => _now),
        transactionCategoriesProvider.overrideWith(
          (ref) => Stream.value(const <CategoryOption>[]),
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la pagada va tachada y la pendiente dice cuándo vence', (
    tester,
  ) async {
    await pump(tester, const RecurringPage());

    final paidName = tester.widget<Text>(find.text('Spotify').first);
    expect(paidName.style?.decoration, TextDecoration.lineThrough);
    expect(find.text('Pagado el 12 oct · SPOTIFY P3A9C1'), findsOneWidget);
    final pendingName = tester.widget<Text>(find.text('Arriendo').first);
    expect(pendingName.style?.decoration, isNot(TextDecoration.lineThrough));
    expect(find.text('Vence el 28 oct'), findsOneWidget);
    expect(
      find.textContaining(r'Este mes: $16.900 pagados de'),
      findsOneWidget,
    );
  });

  testWidgets('tocar una pendiente ofrece marcarla como pagada', (
    tester,
  ) async {
    await pump(tester, const RecurringPage());

    await tester.tap(find.text('Arriendo').first);
    await tester.pumpAndSettle();
    expect(find.text('Omitir este mes'), findsOneWidget);
    await tester.tap(find.text('Marcar como pagado'));
    await tester.pumpAndSettle();

    verify(() => actions.markPaid('o-2')).called(1);
    expect(find.text('Marcado como pagado'), findsOneWidget);
  });

  testWidgets('sin conexión se avisa y no cambia nada', (tester) async {
    when(() => actions.markPaid(any())).thenThrow(const RecurringOffline());
    await pump(tester, const RecurringPage());

    await tester.tap(find.text('Arriendo').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar como pagado'));
    await tester.pumpAndSettle();

    expect(
      find.text('Necesitas conexión para cambiar tus gastos fijos.'),
      findsOneWidget,
    );
  });

  testWidgets('lista todos los gastos fijos configurados, también pausados', (
    tester,
  ) async {
    await pump(
      tester,
      const RecurringPage(),
      expenses: [_spotify, _arriendo.copyWith(active: false)],
    );

    expect(find.text('TUS GASTOS FIJOS'), findsOneWidget);
    expect(find.text(r'$16.900 · el 12 de cada mes'), findsOneWidget);
    expect(find.text(r'$1.500.000 · el 28 de cada mes'), findsOneWidget);
    expect(find.text('Pausado'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
  });

  testWidgets('sin gastos fijos invita a crear el primero', (tester) async {
    await pump(
      tester,
      const RecurringPage(),
      expenses: const [],
      occurrences: const [],
    );

    expect(find.text('Aún no tienes gastos fijos'), findsOneWidget);
    expect(find.text('Nuevo gasto fijo'), findsOneWidget);
  });

  testWidgets('las filas miden 48 dp o más', (tester) async {
    await pump(tester, const RecurringPage());

    for (final element in find.byType(OccurrenceRow).evaluate()) {
      expect(element.size!.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('la fila de Ajustes cuenta los activos', (tester) async {
    await pump(
      tester,
      const Scaffold(body: RecurringSettingsTile()),
      expenses: [_spotify, _arriendo.copyWith(active: false)],
    );

    expect(find.text('Gastos fijos'), findsOneWidget);
    expect(find.text('1 activo'), findsOneWidget);
  });

  group('goldens', () {
    setUpAll(loadBrandFonts);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('gastos fijos ${mode.name}', tags: ['golden'], (
        tester,
      ) async {
        when(
          () => store.watchExpenses(),
        ).thenAnswer((_) => Stream.value(const [_spotify, _arriendo]));
        when(
          () => store.watchOccurrences(any()),
        ).thenAnswer((_) => Stream.value([_paid, _pending]));
        await tester.pumpApp(
          const RecurringPage(),
          themeMode: mode,
          overrides: [
            recurringActionsProvider.overrideWithValue(actions),
            recurringStoreProvider.overrideWithValue(store),
            recurringClockProvider.overrideWithValue(() => _now),
            transactionCategoriesProvider.overrideWith(
              (ref) => Stream.value(const <CategoryOption>[]),
            ),
          ],
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(RecurringPage),
          matchesGoldenFile('goldens/recurring_page_${mode.name}.png'),
        );
      });
    }
  });
}
