import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/app_theme.dart';
import 'package:luka/features/review/application/review_actions.dart';
import 'package:luka/features/review/application/review_providers.dart';
import 'package:luka/features/review/domain/review_draft.dart';
import 'package:luka/features/review/domain/review_item.dart';
import 'package:luka/features/review/domain/review_repository.dart';
import 'package:luka/features/review/presentation/review_detail_page.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/domain/category_option.dart';
import 'package:luka/features/transactions/domain/transactions_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';
import 'review_fixtures.dart';

class _Repository extends Mock implements ReviewRepository {}

class _Transactions extends Mock implements TransactionsRepository {}

class _Actions extends Mock implements ReviewActions {}

const _categories = [
  CategoryOption(
    id: 'mercado',
    name: 'Mercado',
    isSystem: true,
    slug: 'mercado',
  ),
  CategoryOption(
    id: 'restaurantes',
    name: 'Restaurantes',
    isSystem: true,
    slug: 'restaurantes',
  ),
];

const _line =
    'CALLE 80 desde tu cuenta *4821. Dudas al 604 510 9095 o al '
    '018000912345.';

/// Correo de unos 8 KB: líneas con montos y teléfonos, y un final
/// reconocible.
final ReviewItem _longItem = ReviewItem(
  rawMessageId: 'm-long',
  channel: 'email',
  sender: 'alertas@bancolombia.com.co',
  bank: 'bancolombia',
  receivedAt: bogota(23, 12, 41),
  reason: 'no_template',
  partialExtract: const {},
  text: [
    for (var i = 0; i < 75; i++)
      'Bancolombia te informa una compra por \$${i + 1}2.400 en EXITO $_line',
    'FIN DEL MENSAJE',
  ].join('\n'),
);

void main() {
  late _Repository repository;
  late _Transactions transactions;
  late _Actions actions;
  late Map<String, StreamController<ReviewItem?>> streams;

  setUpAll(() {
    registerFallbackValue(emailItem);
    registerFallbackValue(const ReviewDraft());
  });

  setUp(() {
    repository = _Repository();
    transactions = _Transactions();
    actions = _Actions();
    final rows = {
      for (final item in [emailItem, notificationItem, purgedItem, _longItem])
        item.rawMessageId: item,
    };
    streams = {};
    // Como Drift: cada suscripción recibe la fila actual y los cambios.
    when(() => repository.watchOne(any())).thenAnswer((invocation) {
      final id = invocation.positionalArguments.first as String;
      final controller = streams.putIfAbsent(
        id,
        StreamController<ReviewItem?>.broadcast,
      );
      return Stream.multi((sink) {
        sink.add(rows[id]);
        final sub = controller.stream.listen(sink.add);
        sink.onCancel = sub.cancel;
      });
    });
    when(
      () => transactions.watchCategories(),
    ).thenAnswer((_) => Stream.value(_categories));
    // El outbox borra la fila al encolar (optimista).
    void removeRow(Invocation invocation) {
      final item = invocation.positionalArguments.first as ReviewItem;
      streams[item.rawMessageId]?.add(null);
    }

    when(() => actions.convert(any(), any())).thenAnswer((invocation) async {
      removeRow(invocation);
    });
    when(() => actions.discard(any())).thenAnswer((invocation) async {
      removeRow(invocation);
    });
  });

  tearDown(() async {
    for (final controller in streams.values) {
      await controller.close();
    }
  });

  /// El detalle de [id] dentro de un GoRouter, sobre la lista.
  Future<void> pumpDetail(
    WidgetTester tester, {
    String id = 'm-notif',
    ThemeMode themeMode = ThemeMode.light,
    Size size = const Size(390, 1400),
  }) async {
    tester.view
      ..physicalSize = size * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/revision/$id',
      routes: [
        GoRoute(
          path: '/revision',
          builder: (_, _) => const Scaffold(body: Text('lista')),
          routes: [
            GoRoute(
              path: ':rawMessageId',
              builder: (_, state) => ReviewDetailPage(
                rawMessageId: state.pathParameters['rawMessageId']!,
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reviewRepositoryProvider.overrideWithValue(repository),
          reviewActionsProvider.overrideWithValue(actions),
          transactionsRepositoryProvider.overrideWithValue(transactions),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          locale: const Locale('es', 'CO'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String amountText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).first).controller!.text;

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('prellena el formulario con lo que sí se extrajo', (
    tester,
  ) async {
    await pumpDetail(tester);

    expect(find.text('Revisar mensaje'), findsOneWidget);
    expect(find.text('Nequi'), findsOneWidget);
    expect(find.text('La lectura no fue confiable'), findsOneWidget);
    expect(
      find.textContaining('Pagaste', findRichText: true),
      findsOneWidget,
    );
    expect(amountText(tester), '38.900');
    final direction = tester.widget<SegmentedButton<TxDirection>>(
      find.byType(SegmentedButton<TxDirection>),
    );
    expect(direction.selected, {TxDirection.debit});
    expect(find.text('Martes 22 sep 2026'), findsOneWidget);
    expect(find.text('18:25'), findsOneWidget);
    expect(find.text('Rappi'), findsOneWidget);
    expect(find.text('Sin categoría'), findsOneWidget);
    expect(
      find.text(
        'Es la fecha en que llegó el mensaje; cámbiala si no coincide.',
      ),
      findsNothing,
    );
  });

  testWidgets('sin fecha extraída propone la de recepción y lo dice', (
    tester,
  ) async {
    await pumpDetail(tester, id: 'm-email');

    expect(amountText(tester), isEmpty);
    final direction = tester.widget<SegmentedButton<TxDirection>>(
      find.byType(SegmentedButton<TxDirection>),
    );
    expect(direction.selected, isEmpty);
    expect(find.text('Miércoles 23 sep 2026'), findsOneWidget);
    expect(find.text('12:41'), findsOneWidget);
    expect(
      find.text(
        'Es la fecha en que llegó el mensaje; cámbiala si no coincide.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('tocar un monto resaltado o su botón llena el monto', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpDetail(tester, id: 'm-email');

    // Los teléfonos no se ofrecen como monto.
    expect(find.text('Toca un monto para usarlo'), findsOneWidget);
    expect(find.text(r'$126.400'), findsOneWidget);
    expect(find.text(r'$1.254.300,50'), findsOneWidget);
    expect(find.textContaining('9095', findRichText: true), findsOneWidget);

    await tapVisible(
      tester,
      find.bySemanticsLabel('Usar 1.254.300,50 pesos como monto'),
    );
    expect(amountText(tester), '1.254.300,50');

    await tester.tapOnText(find.textRange.ofSubstring(r'$126.400').first);
    await tester.pumpAndSettle();
    expect(amountText(tester), '126.400');
    handle.dispose();
  });

  testWidgets('el monto se escribe con puntos de miles', (tester) async {
    await pumpDetail(tester, id: 'm-email');

    await tester.enterText(find.byType(TextField).first, '1234567');
    await tester.pump();

    expect(amountText(tester), '1.234.567');
  });

  testWidgets('sin monto ni tipo muestra los errores y no convierte', (
    tester,
  ) async {
    await pumpDetail(tester, id: 'm-email');

    await tapVisible(tester, find.text('Crear movimiento').last);

    expect(find.text('Escribe el monto'), findsOneWidget);
    expect(find.text('Elige si es un gasto o un ingreso'), findsOneWidget);
    verifyNever(() => actions.convert(any(), any()));

    await tapVisible(tester, find.text('Ingreso'));
    expect(find.text('Elige si es un gasto o un ingreso'), findsNothing);
    await tester.enterText(find.byType(TextField).first, '5000');
    await tester.pump();
    expect(find.text('Escribe el monto'), findsNothing);
  });

  testWidgets('crear movimiento convierte con el borrador y vuelve', (
    tester,
  ) async {
    await pumpDetail(tester);

    await tester.enterText(find.byType(TextField).last, ' Rappi Colombia ');
    await tapVisible(
      tester,
      find.bySemanticsLabel('Cambiar categoría: Sin categoría'),
    );
    await tester.tap(find.text('Restaurantes'));
    await tester.pumpAndSettle();
    expect(find.text('Restaurantes'), findsOneWidget);

    await tapVisible(tester, find.text('Crear movimiento').last);

    verify(
      () => actions.convert(
        notificationItem,
        ReviewDraft(
          amount: Cop.pesos(38900),
          direction: TxDirection.debit,
          occurredAt: DateTime.utc(2026, 9, 22, 23, 25),
          merchant: ' Rappi Colombia ',
          categoryId: 'restaurantes',
        ),
      ),
    ).called(1);
    expect(find.text('lista'), findsOneWidget);
    expect(find.text('Movimiento creado'), findsOneWidget);
    expect(find.text('Este mensaje ya no está por revisar.'), findsNothing);
  });

  testWidgets('con la fecha de recepción convierte con esa fecha', (
    tester,
  ) async {
    await pumpDetail(tester, id: 'm-email');

    await tapVisible(
      tester,
      find.bySemanticsLabel('Usar 126.400 pesos como monto'),
    );
    await tapVisible(tester, find.text('Gasto'));
    await tapVisible(tester, find.text('Crear movimiento').last);

    verify(
      () => actions.convert(
        emailItem,
        ReviewDraft(
          amount: Cop.pesos(126400),
          direction: TxDirection.debit,
          occurredAt: emailItem.receivedAt,
          merchant: '',
        ),
      ),
    ).called(1);
  });

  testWidgets('cambiar la fecha y la hora mueve el instante', (tester) async {
    // El "Aceptar" de los selectores de Material en español.
    final ok = find.textContaining(RegExp(r'^aceptar$', caseSensitive: false));
    await pumpDetail(tester, id: 'm-email');

    await tapVisible(tester, find.text('Miércoles 23 sep 2026'));
    await tester.tap(find.text('20'));
    await tester.tap(ok);
    await tester.pumpAndSettle();
    expect(find.text('Domingo 20 sep 2026'), findsOneWidget);
    expect(
      find.text(
        'Es la fecha en que llegó el mensaje; cámbiala si no coincide.',
      ),
      findsNothing,
    );

    await tapVisible(tester, find.text('12:41'));
    // Modo de escritura: hora y minutos como texto.
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.first, '08');
    await tester.enterText(fields.last, '05');
    await tester.tap(ok);
    await tester.pumpAndSettle();
    expect(find.text('08:05'), findsOneWidget);

    await tapVisible(
      tester,
      find.bySemanticsLabel('Usar 126.400 pesos como monto'),
    );
    await tapVisible(tester, find.text('Gasto'));
    await tapVisible(tester, find.text('Crear movimiento').last);

    final draft =
        verify(() => actions.convert(emailItem, captureAny())).captured.single
            as ReviewDraft;
    expect(draft.occurredAt, DateTime.utc(2026, 9, 20, 13, 5));
  });

  testWidgets('si no se puede guardar lo avisa y se queda', (tester) async {
    when(
      () => actions.convert(any(), any()),
    ).thenAnswer((_) async => throw StateError('db'));
    await pumpDetail(tester);

    await tapVisible(tester, find.text('Crear movimiento').last);

    expect(
      find.text('No pudimos guardar el cambio. Intenta de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('lista'), findsNothing);
  });

  testWidgets('un borrador rechazado por la acción muestra sus errores', (
    tester,
  ) async {
    when(() => actions.convert(any(), any())).thenAnswer(
      (_) async =>
          throw const InvalidReviewDraft({ReviewDraftError.amountRequired}),
    );
    await pumpDetail(tester);

    await tapVisible(tester, find.text('Crear movimiento').last);

    expect(find.text('Escribe el monto'), findsOneWidget);
  });

  testWidgets('descartar pide confirmación y luego descarta', (tester) async {
    await pumpDetail(tester);

    await tapVisible(tester, find.text('Descartar'));
    expect(find.text('¿Descartar este mensaje?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    verifyNever(() => actions.discard(any()));
    expect(find.text('Revisar mensaje'), findsOneWidget);

    await tapVisible(tester, find.text('Descartar'));
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Descartar'),
      ),
    );
    await tester.pumpAndSettle();

    verify(() => actions.discard(notificationItem)).called(1);
    expect(find.text('lista'), findsOneWidget);
    expect(find.text('Descartado'), findsOneWidget);
  });

  testWidgets('volver regresa a la lista', (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    expect(find.text('lista'), findsOneWidget);
  });

  testWidgets('sin texto lo dice y no ofrece montos', (tester) async {
    await pumpDetail(tester, id: 'm-purged');

    expect(
      find.text('El texto de este mensaje ya no está disponible.'),
      findsOneWidget,
    );
    expect(find.text('Toca un monto para usarlo'), findsNothing);
  });

  testWidgets('un mensaje que ya no está lo dice', (tester) async {
    await pumpDetail(tester, id: 'otro');

    expect(find.text('Este mensaje ya no está por revisar.'), findsOneWidget);
  });

  testWidgets('las áreas táctiles y el contraste cumplen', (tester) async {
    await pumpDetail(tester, id: 'm-email');

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  group('con un texto de 8 KB en un teléfono', () {
    const phone = Size(390, 844);

    /// Posición global del final del texto largo.
    Offset textEnd(WidgetTester tester) {
      final paragraph = tester.renderObject<RenderParagraph>(
        find.textContaining('FIN DEL MENSAJE', findRichText: true),
      );
      final length = paragraph.text.toPlainText().length;
      final caret = paragraph.getOffsetForCaret(
        TextPosition(offset: length),
        Rect.zero,
      );
      return paragraph.localToGlobal(caret);
    }

    bool onScreen(Offset point, {double bottom = 844}) =>
        point.dy >= 0 && point.dy <= bottom;

    testWidgets('no desborda y deja llegar al final y al botón', (
      tester,
    ) async {
      expect(_longItem.text!.length, greaterThan(8000));
      await pumpDetail(tester, id: 'm-long', size: phone);
      expect(tester.takeException(), isNull);

      // Recortado, el formulario queda cerca y el texto no se desplaza por
      // dentro.
      expect(find.text('Monto'), findsOneWidget);
      await tapVisible(tester, find.text('Ver mensaje completo'));
      expect(find.text('Ver menos'), findsOneWidget);

      // A mitad de pantalla queda "Ver menos", justo debajo del final.
      await tester.dragUntilVisible(
        find.text('Ver menos'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('Ver menos')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      expect(onScreen(textEnd(tester)), isTrue);

      await tapVisible(tester, find.text('Crear movimiento').last);
      expect(tester.takeException(), isNull);
      expect(find.text('Escribe el monto'), findsOneWidget);
    });

    testWidgets('con el teclado abierto el monto sigue a la vista', (
      tester,
    ) async {
      await pumpDetail(tester, id: 'm-long', size: phone);
      final amount = find.byType(TextField).first;

      await tapVisible(tester, amount);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final field = tester.getRect(amount);
      expect(field.top, greaterThanOrEqualTo(0));
      expect(field.bottom, lessThanOrEqualTo(844 - 300));
      await tester.enterText(amount, '5000');
      await tester.pump();
      expect(amountText(tester), '5.000');
    });
  });

  group('goldens', () {
    setUpAll(loadBrandFonts);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('detalle ${mode.name}', tags: ['golden'], (tester) async {
        await pumpDetail(
          tester,
          id: 'm-email',
          themeMode: mode,
          size: const Size(390, 1240),
        );
        await expectLater(
          find.byType(ReviewDetailPage),
          matchesGoldenFile('goldens/review_detail_${mode.name}.png'),
        );
      });
    }
  });
}
