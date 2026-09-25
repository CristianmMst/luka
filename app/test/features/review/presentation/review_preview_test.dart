import 'package:finanzia/features/review/presentation/widgets/review_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reviewPreview', () {
    test('salta el logo y los enlaces y empieza cerca del monto', () {
      const body =
          'Logo Bancolombia [http://example.com/templates/img/header-logo.png]\n'
          '\n'
          '¡Listo! Todo salió bien con tus movimientos Bancolombia: ANA, '
          'recibiste una\ntransferencia de JUAN PEREZ por \$482,500.00 en tu '
          'cuenta *9081 el 01/05/26 a las 16:28.';

      final preview = reviewPreview(body);

      expect(
        preview,
        r'…ANA, recibiste una transferencia de JUAN PEREZ por $482,500.00 '
        'en tu cuenta *9081 el 01/05/26 a las 16:28.',
      );
      expect(preview, isNot(contains('http')));
      expect(preview, isNot(contains('[')));
    });

    test('una frase corta se muestra desde su inicio', () {
      expect(
        reviewPreview(r'Logo [http://x.co/a.png] Hola. Pagaste $45.900 hoy'),
        r'Pagaste $45.900 hoy',
      );
    });

    test('recorta con puntos suspensivos si la frase es muy larga', () {
      final body = '${'palabra ' * 30}pagaste \$45.900 en TIENDA';

      final preview = reviewPreview(body);

      expect(preview, startsWith('…'));
      expect(preview, contains(r'$45.900'));
      expect(preview.indexOf(r'$45.900'), lessThanOrEqualTo(62));
    });

    test('sin montos devuelve el texto limpio completo', () {
      expect(
        reviewPreview('Hola  www.example.com\nmundo'),
        'Hola mundo',
      );
    });
  });
}
