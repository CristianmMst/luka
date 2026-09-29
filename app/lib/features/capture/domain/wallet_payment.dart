import 'package:finanzia/features/capture/domain/captured_notification.dart';

/// Paquete sintético de los pagos con Apple Pay (spec 006 §3.3): el backend
/// lo acepta sin banco y lo busca en el nombre de la tarjeta.
const applePayPackage = 'com.apple.wallet';

final _amount = RegExp(r'\d[\d.,]*');
final _spaces = RegExp(r'\s+');

/// El pago que la automatización "Transacción" de Atajos entregó a la App
/// Intent, como el ítem de captura que parsea la plantilla `apple_wallet`
/// del backend (F4.3b). El texto es un contrato, con la hora del teléfono:
///
/// `Apple Pay: Compraste $<monto> con <tarjeta> en <comercio> el dd/MM/aaaa a las HH:mm`
///
/// Del monto quedan las cifras y separadores; si no trae
/// ninguna va tal cual, y el backend lo manda a Revisión.
CapturedNotification walletPaymentNotification({
  required int id,
  required String card,
  required String merchant,
  required String amount,
  required DateTime postedAt,
  required Duration utcOffset,
}) {
  final cardName = _oneLine(card);
  final local = postedAt.toUtc().add(utcOffset);
  String two(int value) => value.toString().padLeft(2, '0');
  final date = '${two(local.day)}/${two(local.month)}/${local.year}';
  final time = '${two(local.hour)}:${two(local.minute)}';
  final number = _amount.firstMatch(amount)?.group(0) ?? amount.trim();
  final merchantName = _oneLine(merchant);

  return CapturedNotification(
    id: id,
    package: applePayPackage,
    channel: CaptureChannel.notification,
    postedAt: postedAt.toUtc(),
    utcOffset: utcOffset,
    title: cardName.isEmpty ? null : cardName,
    text:
        'Apple Pay: Compraste \$$number '
        'con ${cardName.isEmpty ? 'Tarjeta' : cardName} '
        'en ${merchantName.isEmpty ? 'Comercio' : merchantName} '
        'el $date a las $time',
  );
}

String _oneLine(String value) => value.trim().replaceAll(_spaces, ' ');
