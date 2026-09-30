import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/nfc/presentation/nfc_format.dart';

void main() {
  const id = '3f2b8c1e-5a4d-4e6f-9b7a-1c2d3e4f5a6b';

  test('el enlace del tag se vuelve la ruta del registro rápido', () {
    expect(
      quickAddLocation(Uri.parse('luka://quick-add?tag=$id')),
      '/rapido?tag=$id',
    );
  });

  test('las rutas internas y otros enlaces no se tocan', () {
    expect(quickAddLocation(Uri.parse('/rapido?tag=$id')), isNull);
    expect(quickAddLocation(Uri.parse('/movimientos')), isNull);
    expect(quickAddLocation(Uri.parse('luka://otra?tag=$id')), isNull);
  });
}
