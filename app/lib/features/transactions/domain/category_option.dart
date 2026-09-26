import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_option.freezed.dart';

/// Categoría para los selectores de filtro y edición.
@freezed
abstract class CategoryOption with _$CategoryOption {
  const factory CategoryOption({
    required String id,
    required String name,
    required bool isSystem,
    String? slug,

    /// Clave del ícono y color `#RRGGBB` de una categoría propia.
    String? icon,
    String? color,
    String? fiscalTag,
  }) = _CategoryOption;
}
