import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/nfc/domain/quick_add_link.dart';

const _id = '3f2b8c1e-5a4d-4e6f-9b7a-1c2d3e4f5a6b';

void main() {
  test('el enlace lleva solo el id de la plantilla', () {
    expect(
      quickAddUri(_id).toString(),
      'luka://quick-add?tag=$_id',
    );
  });

  test('ida y vuelta', () {
    expect(tagIdFromQuickAddUri(quickAddUri(_id)), _id);
  });

  test('acepta mayúsculas y espacios en el id', () {
    expect(
      tagIdFromQuickAddUri(
        Uri.parse('LUKA://Quick-Add?tag=${_id.toUpperCase()}'),
      ),
      _id,
    );
  });

  test('rechaza otros enlaces', () {
    for (final raw in [
      'https://quick-add?tag=$_id',
      'luka://otra-cosa?tag=$_id',
      'luka://quick-add',
      'luka://quick-add?tag=no-es-un-uuid',
      'luka://quick-add?tag=',
    ]) {
      expect(tagIdFromQuickAddUri(Uri.parse(raw)), isNull, reason: raw);
    }
  });
}
