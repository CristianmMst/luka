import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/db/device_state.dart';

void main() {
  test('las claves del teléfono sobreviven al cerrar sesión', () {
    expect(isDeviceStateKey(deviceStateKey('onboarding_done:u-1')), isTrue);
    expect(deviceStateKey('onboarding_done:u-1'), 'device:onboarding_done:u-1');
  });

  test('los datos de sync y del usuario se borran', () {
    for (final key in [
      'owner_user_id',
      'transactions_cursor',
      'last_synced_at',
      'onboarding_done:u-1',
      'dedupe_hint_dismissed',
    ]) {
      expect(isDeviceStateKey(key), isFalse, reason: key);
    }
  });
}
