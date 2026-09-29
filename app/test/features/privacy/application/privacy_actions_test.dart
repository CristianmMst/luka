import 'package:finanzia/features/privacy/application/privacy_actions.dart';
import 'package:finanzia/features/privacy/domain/privacy_ports.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Remote extends Mock implements PrivacyRemote {}

class _Saver extends Mock implements ExportSaver {}

void main() {
  late _Remote remote;
  late _Saver saver;
  late int signOuts;
  late PrivacyActions actions;

  setUp(() {
    remote = _Remote();
    saver = _Saver();
    signOuts = 0;
    when(
      () => saver.save(any(), fileName: any(named: 'fileName')),
    ).thenAnswer((_) async {});
    actions = PrivacyActions(
      remote: remote,
      saver: saver,
      signOut: () async => signOuts++,
      now: () => DateTime(2026, 9, 29, 10),
    );
  });

  test('el nombre del archivo lleva la fecha', () {
    expect(exportFileName(DateTime(2026, 1, 5)), 'finanzia-2026-01-05.json');
  });

  test('exportar guarda el JSON del servidor tal cual', () async {
    when(() => remote.exportData()).thenAnswer((_) async => '{"a":1}');

    await actions.exportData();

    verify(
      () => saver.save('{"a":1}', fileName: 'finanzia-2026-09-29.json'),
    ).called(1);
  });

  test('si exportar falla no se guarda nada', () async {
    when(() => remote.exportData()).thenThrow(const PrivacyOffline());

    await expectLater(actions.exportData(), throwsA(isA<PrivacyOffline>()));
    verifyNever(() => saver.save(any(), fileName: any(named: 'fileName')));
  });

  test('borrar la cuenta en el servidor y luego cerrar sesión', () async {
    when(() => remote.deleteAccount()).thenAnswer((_) async {});

    await actions.deleteAccount();

    verify(() => remote.deleteAccount()).called(1);
    expect(signOuts, 1);
  });

  test('si el servidor no borra, la sesión y la base local siguen', () async {
    when(() => remote.deleteAccount()).thenThrow(const PrivacyUnexpected());

    await expectLater(
      actions.deleteAccount(),
      throwsA(isA<PrivacyUnexpected>()),
    );
    expect(signOuts, 0);
  });
}
