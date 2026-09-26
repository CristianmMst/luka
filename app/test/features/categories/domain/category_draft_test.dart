import 'package:finanzia/features/categories/domain/category_catalog.dart';
import 'package:finanzia/features/categories/domain/category_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryDraft', () {
    test('por defecto: gasto personal, primer ícono y primer color', () {
      const draft = CategoryDraft(name: 'Mascotas');
      expect(draft.fiscalTag, 'no_deducible');
      expect(draft.icon, categoryIconKeys.first);
      expect(draft.color, categoryColors.first);
    });

    test('recorta el nombre y lo valida', () {
      expect(const CategoryDraft(name: '  Mascotas  ').cleanName, 'Mascotas');
      expect(const CategoryDraft(name: 'Mascotas').validate(), isEmpty);
      expect(const CategoryDraft(name: '   ').validate(), {
        CategoryDraftError.nameRequired,
      });
      expect(CategoryDraft(name: 'x' * 81).validate(), {
        CategoryDraftError.nameTooLong,
      });
      expect(CategoryDraft(name: ' ${'x' * 80} ').validate(), isEmpty);
    });

    test('rechaza etiqueta, ícono o color fuera del catálogo', () {
      expect(
        const CategoryDraft(name: 'A', fiscalTag: 'transferencia').validate(),
        {CategoryDraftError.invalidFiscalTag},
      );
      expect(const CategoryDraft(name: 'A', icon: 'rocket').validate(), {
        CategoryDraftError.invalidIcon,
      });
      expect(const CategoryDraft(name: 'A', color: '#FF0000').validate(), {
        CategoryDraftError.invalidColor,
      });
    });

    test('desde una categoría existente conserva lo válido', () {
      final draft = CategoryDraft.fromExisting(
        name: 'Gimnasio',
        fiscalTag: 'deducible_salud',
        icon: 'fitness',
        color: '#45617A',
      );
      expect(draft.icon, 'fitness');
      expect(draft.color, '#45617A');
      expect(draft.fiscalTag, 'deducible_salud');
    });

    test('ícono o color desconocido vuelve al default', () {
      final draft = CategoryDraft.fromExisting(
        name: 'Vieja',
        fiscalTag: 'no_deducible',
        icon: null,
        color: '#123456',
      );
      expect(draft.icon, categoryIconKeys.first);
      expect(draft.color, categoryColors.first);
    });
  });

  group('catálogo', () {
    test('16 íconos y 8 colores únicos', () {
      expect(categoryIconKeys.toSet(), hasLength(16));
      expect(categoryColors.toSet(), hasLength(8));
      for (final color in categoryColors) {
        expect(color, matches(RegExp(r'^#[0-9A-F]{6}$')));
      }
    });

    test('las 12 etiquetas de usuario, agrupadas y sin transferencia', () {
      final tags = [for (final g in userFiscalTagGroups) ...g.tags];
      expect(tags, hasLength(12));
      expect(tags.toSet(), hasLength(12));
      expect(tags, isNot(contains('transferencia')));
      expect(tags.first, 'no_deducible');
      expect(
        [for (final g in userFiscalTagGroups) g.group],
        [
          FiscalGroup.expenses,
          FiscalGroup.contributions,
          FiscalGroup.income,
        ],
      );
      expect(isUserFiscalTag('ingreso_laboral'), isTrue);
      expect(isUserFiscalTag('transferencia'), isFalse);
    });
  });
}
