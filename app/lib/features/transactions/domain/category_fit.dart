import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/domain/category_option.dart';
import 'package:luka/features/transactions/domain/search.dart';

/// Si [category] sirve para registrar un movimiento en [direction]: las de
/// etiqueta `ingreso_*` son de ingreso y el resto de gasto. "Sin categoría"
/// y las que no tienen etiqueta van con ambos. Las transferencias no: el
/// tipo transferencia se marca después, en el detalle (spec 008 §3.4).
bool fitsDirection(CategoryOption category, TxDirection direction) {
  final tag = category.fiscalTag;
  if (category.slug == 'transferencias' || tag == 'transferencia') {
    return false;
  }
  if (category.slug == 'sin_categoria' || tag == null) return true;
  final income = tag.startsWith('ingreso_');
  return income == (direction == TxDirection.credit);
}

/// Las [categories] que sirven para [direction], en su orden, y que
/// contienen [query] en el nombre (sin tildes ni mayúsculas).
List<CategoryOption> categoriesFor(
  List<CategoryOption> categories,
  TxDirection direction, {
  String query = '',
}) {
  final needle = normalizeForSearch(query.trim());
  return [
    for (final category in categories)
      if (fitsDirection(category, direction) &&
          (needle.isEmpty ||
              normalizeForSearch(category.name).contains(needle)))
        category,
  ];
}
