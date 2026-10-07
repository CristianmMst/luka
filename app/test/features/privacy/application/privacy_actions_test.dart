import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/privacy/application/privacy_actions.dart';
import 'package:luka/features/privacy/domain/privacy_ports.dart';
import 'package:mocktail/mocktail.dart';

class _Remote extends Mock implements PrivacyRemote {}

void main() {
  late _Remote remote;
  late int signOuts;
  late List<String> calls;
  late PrivacyActions actions;

  setUp(() {
    remote = _Remote();
    signOuts = 0;
    calls = [];
    actions = PrivacyActions(
      remote: remote,
      signOut: () async {
        signOuts++;
        calls.add('signOut');
      },
      forgetDevice: () async => calls.add('forgetDevice'),
    );
  });

  test('borrar la cuenta en el servidor y luego cerrar sesión', () async {
    when(() => remote.deleteAccount()).thenAnswer((_) async {});

    await actions.deleteAccount();

    verify(() => remote.deleteAccount()).called(1);
    expect(signOuts, 1);
  });

  test(
    'borrar la cuenta olvida lo del teléfono antes de cerrar sesión',
    () async {
      when(() => remote.deleteAccount()).thenAnswer((_) async {});

      await actions.deleteAccount();

      expect(calls, ['forgetDevice', 'signOut']);
    },
  );

  test('si el servidor no borra, la sesión y la base local siguen', () async {
    when(() => remote.deleteAccount()).thenThrow(const PrivacyUnexpected());

    await expectLater(
      actions.deleteAccount(),
      throwsA(isA<PrivacyUnexpected>()),
    );
    expect(signOuts, 0);
    expect(calls, isEmpty);
  });
}
