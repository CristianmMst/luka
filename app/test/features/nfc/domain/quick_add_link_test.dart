import 'package:finanzia/features/nfc/domain/quick_add_link.dart';
import 'package:flutter_test/flutter_test.dart';

const _id = '3f2b8c1e-5a4d-4e6f-9b7a-1c2d3e4f5a6b';

void main() {
  test('el enlace lleva solo el id de la plantilla', () {
    expect(
      quickAddUri(_id).toString(),
      'finanzia://quick-add?tag=$_id',
    );
  });

  test('ida y vuelta', () {
    expect(tagIdFromQuickAddUri(quickAddUri(_id)), _id);
  });

  test('acepta mayúsculas y espacios en el id', () {
    expect(
      tagIdFromQuickAddUri(
        Uri.parse('FINANZIA://Quick-Add?tag=${_id.toUpperCase()}'),
      ),
      _id,
    );
  });

  test('rechaza otros enlaces', () {
    for (final raw in [
      'https://quick-add?tag=$_id',
      'finanzia://otra-cosa?tag=$_id',
      'finanzia://quick-add',
      'finanzia://quick-add?tag=no-es-un-uuid',
      'finanzia://quick-add?tag=',
    ]) {
      expect(tagIdFromQuickAddUri(Uri.parse(raw)), isNull, reason: raw);
    }
  });
}
