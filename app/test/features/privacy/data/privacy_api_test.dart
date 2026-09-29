import 'package:finanzia/features/privacy/data/privacy_api.dart';
import 'package:finanzia/features/privacy/domain/privacy_ports.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/stub_backend.dart';

void main() {
  test('exportar hace GET /v1/me/export y devuelve el texto', () async {
    final backend = StubBackend(
      (_) => const StubResponse(200, {'format_version': 1}),
    );

    final json = await PrivacyApi(stubDio(backend)).exportData();

    expect(json, '{"format_version":1}');
    expect(backend.requests.single.method, 'GET');
    expect(backend.requests.single.path, '/v1/me/export');
  });

  test('borrar hace DELETE /v1/me', () async {
    final backend = StubBackend((_) => const StubResponse(204));

    await PrivacyApi(stubDio(backend)).deleteAccount();

    expect(backend.requests.single.method, 'DELETE');
    expect(backend.requests.single.path, '/v1/me');
  });

  test('sin red falla con PrivacyOffline; otro error, PrivacyUnexpected', () {
    final offline = PrivacyApi(
      stubDio(StubBackend((r) => throw connectionError(r))),
    );
    final broken = PrivacyApi(
      stubDio(StubBackend((_) => StubResponse.error(500, 'internal'))),
    );

    expect(offline.deleteAccount(), throwsA(isA<PrivacyOffline>()));
    expect(offline.exportData(), throwsA(isA<PrivacyOffline>()));
    expect(broken.deleteAccount(), throwsA(isA<PrivacyUnexpected>()));
    expect(broken.exportData(), throwsA(isA<PrivacyUnexpected>()));
  });
}
