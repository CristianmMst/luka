import 'package:finanzia/features/capture/domain/captured_notification.dart';
import 'package:finanzia/features/capture/domain/wallet_payment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 14:05 en Bogotá (UTC-5).
  final postedAt = DateTime.utc(2026, 9, 29, 19, 5, 30);
  const bogota = Duration(hours: -5);

  CapturedNotification payment({
    String card = 'Mastercard Bancolombia 1234',
    String merchant = 'JUAN VALDEZ CAFE',
    String amount = r'$12.500,00',
  }) => walletPaymentNotification(
    id: 7,
    card: card,
    merchant: merchant,
    amount: amount,
    postedAt: postedAt,
    utcOffset: bogota,
  );

  test('arma el texto que parsea la plantilla apple_wallet del backend', () {
    // Mismo contrato que backend/tests/unit/parsing/
    // test_templates_apple_wallet.py.
    final item = payment();

    expect(item.id, 7);
    expect(item.package, applePayPackage);
    expect(item.channel, CaptureChannel.notification);
    expect(item.title, 'Mastercard Bancolombia 1234');
    expect(
      item.text,
      r'Apple Pay: Compraste $12.500,00 con Mastercard Bancolombia 1234 '
      'en JUAN VALDEZ CAFE el 29/09/2026 a las 14:05',
    );
    expect(item.postedAt, postedAt);
    expect(item.utcOffset, bogota);
  });

  test('el monto conserva solo cifras y separadores', () {
    expect(
      payment(amount: 'COP 8.000').text,
      contains(r'Compraste $8.000 con'),
    );
    expect(payment(amount: '8000.5').text, contains(r'Compraste $8000.5 con'));
  });

  test(
    'sin cifras en el monto va tal cual y el backend lo manda a Revisión',
    () {
      expect(
        payment(amount: ' gratis ').text,
        contains(r'Compraste $gratis con'),
      );
    },
  );

  test(
    'tarjeta y comercio vacíos o con saltos de línea no rompen el texto',
    () {
      final item = payment(card: '  ', merchant: 'Tienda\nD1 ');

      expect(item.title, isNull);
      expect(item.text, contains('con Tarjeta en Tienda D1 el'));
    },
  );

  test('la fecha y la hora son las del teléfono al pagar', () {
    final item = walletPaymentNotification(
      id: 1,
      card: 'Visa',
      merchant: 'Oxxo',
      amount: '1',
      postedAt: DateTime.utc(2026, 1, 1, 3, 9),
      utcOffset: bogota,
    );

    expect(item.text, endsWith('el 31/12/2025 a las 22:09'));
  });
}
