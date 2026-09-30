import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/auth/domain/auth_failure.dart';
import 'package:luka/features/auth/domain/auth_repository.dart';
import 'package:luka/features/auth/domain/entities/user.dart';
import 'package:luka/features/auth/presentation/login_page.dart';
import 'package:luka/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockRepository extends Mock implements AuthRepository {}

void main() {
  late _MockRepository repository;
  late StreamController<void> expired;

  setUp(() {
    repository = _MockRepository();
    expired = StreamController<void>.broadcast();
    when(() => repository.sessionExpired).thenAnswer((_) => expired.stream);
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
  });

  tearDown(() => expired.close());

  Future<void> pumpLogin(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpApp(
      const LoginPage(),
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      themeMode: themeMode,
    );
    await tester.pumpAndSettle();
  }

  Finder button() => find.byType(GoogleSignInButton);

  testWidgets('muestra la propuesta y el botón de Google', (tester) async {
    await pumpLogin(tester);
    expect(find.text('Tus gastos se anotan solos.'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('1 registro'), findsOneWidget);
  });

  testWidgets('mientras conecta bloquea el botón', (tester) async {
    final pending = Completer<User>();
    when(
      () => repository.signInWithGoogle(),
    ).thenAnswer((_) => pending.future);
    await pumpLogin(tester);

    await tester.tap(button());
    await tester.pump();

    expect(find.text('Conectando con Google…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(button());
    verify(() => repository.signInWithGoogle()).called(1);

    pending.completeError(const AuthCancelled());
    await tester.pumpAndSettle();
  });

  testWidgets('sin red muestra el aviso y ofrece reintentar', (tester) async {
    when(
      () => repository.signInWithGoogle(),
    ).thenThrow(const AuthNetworkFailure());
    await pumpLogin(tester);

    await tester.tap(button());
    await tester.pumpAndSettle();

    expect(
      find.text('Sin conexión. Revisa tu internet e inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar con Google'), findsOneWidget);
  });

  testWidgets('cancelar vuelve al estado inicial sin aviso', (tester) async {
    when(
      () => repository.signInWithGoogle(),
    ).thenThrow(const AuthCancelled());
    await pumpLogin(tester);

    await tester.tap(button());
    await tester.pumpAndSettle();

    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.textContaining('Inténtalo'), findsNothing);
  });

  testWidgets('429 deshabilita el botón con cuenta regresiva', (tester) async {
    when(
      () => repository.signInWithGoogle(),
    ).thenThrow(const AuthRateLimited(Duration(seconds: 3)));
    await pumpLogin(tester);

    await tester.tap(button());
    await tester.pump();

    expect(find.textContaining('Podrás volver a intentarlo en 0:03'), findsOne);
    expect(
      tester.widget<GoogleSignInButton>(button()).onPressed,
      isNull,
    );

    await tester.pump(const Duration(seconds: 4));
    expect(find.textContaining('Podrás volver'), findsNothing);
    expect(
      tester.widget<GoogleSignInButton>(button()).onPressed,
      isNotNull,
    );
  });

  testWidgets('sesión cerrada por seguridad muestra el aviso', (tester) async {
    when(() => repository.restoreSession()).thenAnswer(
      (_) async => const User(
        id: 'u',
        email: 'a@b.co',
        status: UserStatus.active,
      ),
    );
    await pumpLogin(tester);

    expired.add(null);
    await tester.pumpAndSettle();

    expect(find.textContaining('Tu sesión se cerró'), findsOneWidget);
  });

  group('goldens', () {
    setUpAll(loadBrandFonts);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('login ${mode.name}', tags: ['golden'], (tester) async {
        await pumpLogin(tester, themeMode: mode);
        await expectLater(
          find.byType(LoginPage),
          matchesGoldenFile('goldens/login_${mode.name}.png'),
        );
      });
    }
  });
}
