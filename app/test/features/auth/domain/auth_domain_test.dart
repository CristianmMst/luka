import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/domain/auth_failure.dart';
import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User.greetingName', () {
    test('usa el primer nombre de Google', () {
      const user = User(
        id: 'u',
        email: 'ana@example.com',
        status: UserStatus.active,
        displayName: '  Ana María Pérez ',
      );
      expect(user.greetingName, 'Ana');
    });

    test('sin nombre usa la parte local del email', () {
      for (final name in [null, '', '   ']) {
        final user = User(
          id: 'u',
          email: 'ana.perez@example.com',
          status: UserStatus.active,
          displayName: name,
        );
        expect(user.greetingName, 'ana.perez', reason: '$name');
      }
    });
  });

  test('las fallas de auth son un tipo sellado exhaustivo', () {
    // Tear-offs: construyen en runtime (un `const` no ejecuta el constructor).
    const cancelled = AuthCancelled.new;
    const network = AuthNetworkFailure.new;
    const rateLimited = AuthRateLimited.new;
    const rejected = AuthRejected.new;
    const misconfigured = AuthMisconfigured.new;
    const unexpected = AuthUnexpected.new;
    final failures = <AuthFailure>[
      cancelled(),
      network(),
      rateLimited(const Duration(seconds: 5)),
      rejected(),
      misconfigured('sin client id'),
      unexpected(),
    ];
    final labels = failures.map(
      (f) => switch (f) {
        AuthCancelled() => 'cancelled',
        AuthNetworkFailure() => 'network',
        AuthRateLimited(:final retryAfter) => 'rate ${retryAfter?.inSeconds}',
        AuthRejected() => 'rejected',
        AuthMisconfigured(:final detail) => 'misconfigured $detail',
        AuthUnexpected() => 'unexpected',
      },
    );
    expect(labels, [
      'cancelled',
      'network',
      'rate 5',
      'rejected',
      'misconfigured sin client id',
      'unexpected',
    ]);
  });

  test('authRepositoryProvider exige la composición de la app', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      () => container.read(authRepositoryProvider),
      throwsA(anything),
    );
  });
}
