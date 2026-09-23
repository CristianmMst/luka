import 'package:finanzia/features/transactions/domain/transaction_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TxChannel <-> wire', () {
    const wires = {
      'email': TxChannel.email,
      'notification': TxChannel.notification,
      'sms_notification': TxChannel.smsNotification,
      'manual': TxChannel.manual,
      'nfc': TxChannel.nfc,
    };

    test('fromWire reconoce cada valor del cable', () {
      for (final entry in wires.entries) {
        expect(TxChannel.fromWire(entry.key), entry.value);
      }
    });

    test('toWire produce el string del cable', () {
      for (final entry in wires.entries) {
        expect(entry.value.toWire(), entry.key);
      }
    });

    test('ida y vuelta es estable para todos los valores', () {
      for (final channel in TxChannel.values) {
        expect(TxChannel.fromWire(channel.toWire()), channel);
      }
    });

    test('fromWire con un string desconocido devuelve null', () {
      expect(TxChannel.fromWire('carrier_pigeon'), isNull);
    });
  });
}
