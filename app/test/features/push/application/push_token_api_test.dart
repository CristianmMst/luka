import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/push/data/push_token_api.dart';

import '../../../helpers/stub_backend.dart';

void main() {
  test('registrar hace PUT y borrar DELETE con el token', () async {
    final backend = StubBackend((_) => const StubResponse(204));
    final api = PushTokenApi(stubDio(backend));

    await api.register('tok-1', 'ios');
    await api.unregister('tok-1');

    final [put, delete] = backend.requests;
    expect(put.method, 'PUT');
    expect(put.path, '/v1/devices/push-token');
    expect(jsonDecode(put.data as String), {
      'token': 'tok-1',
      'platform': 'ios',
    });
    expect(delete.method, 'DELETE');
    expect(jsonDecode(delete.data as String), {'token': 'tok-1'});
  });
}
