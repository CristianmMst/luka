import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/privacy/data/privacy_api.dart';
import 'package:luka/features/privacy/domain/privacy_ports.dart';

import '../../../helpers/stub_backend.dart';

void main() {
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
    expect(broken.deleteAccount(), throwsA(isA<PrivacyUnexpected>()));
  });
}
