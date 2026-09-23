// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryDto _$CategoryDtoFromJson(Map<String, dynamic> json) => CategoryDto(
  id: json['id'] as String,
  name: json['name'] as String,
  fiscalTag: json['fiscal_tag'] as String,
  isSystem: json['is_system'] as bool,
  userId: json['user_id'] as String?,
  slug: json['slug'] as String?,
  icon: json['icon'] as String?,
  color: json['color'] as String?,
);

AccountDto _$AccountDtoFromJson(Map<String, dynamic> json) => AccountDto(
  id: json['id'] as String,
  bank: json['bank'] as String,
  kind: json['kind'] as String,
  last4: json['last4'] as String?,
  alias: json['alias'] as String?,
);
