import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luka/features/categories/domain/category_catalog.dart';

part 'category_draft.freezed.dart';

enum CategoryDraftError {
  nameRequired,

  /// Más de [CategoryDraft.maxNameLength] caracteres.
  nameTooLong,
  invalidFiscalTag,
  invalidIcon,
  invalidColor,
}

/// Formulario de crear o editar una categoría propia (spec 005 §7).
@freezed
abstract class CategoryDraft with _$CategoryDraft {
  const factory CategoryDraft({
    required String name,
    @Default(defaultFiscalTag) String fiscalTag,
    @Default('label') String icon,
    @Default('#0E4D3F') String color,
  }) = _CategoryDraft;

  const CategoryDraft._();

  /// Para editar: un ícono o color que ya no está en el catálogo (o que la
  /// categoría no tenía) vuelve al de por defecto.
  factory CategoryDraft.fromExisting({
    required String name,
    required String fiscalTag,
    required String? icon,
    required String? color,
  }) => CategoryDraft(
    name: name,
    fiscalTag: fiscalTag,
    icon: categoryIconKeys.contains(icon) ? icon! : categoryIconKeys.first,
    color: categoryColors.contains(color) ? color! : categoryColors.first,
  );

  /// El límite de `CreateCategoryRequest.name` en el backend.
  static const maxNameLength = 80;

  String get cleanName => name.trim();

  Set<CategoryDraftError> validate() => {
    if (cleanName.isEmpty) CategoryDraftError.nameRequired,
    if (cleanName.length > maxNameLength) CategoryDraftError.nameTooLong,
    if (!isUserFiscalTag(fiscalTag)) CategoryDraftError.invalidFiscalTag,
    if (!categoryIconKeys.contains(icon)) CategoryDraftError.invalidIcon,
    if (!categoryColors.contains(color)) CategoryDraftError.invalidColor,
  };

  bool get isValid => validate().isEmpty;
}
