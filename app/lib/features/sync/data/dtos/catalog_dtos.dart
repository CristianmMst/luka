import 'package:json_annotation/json_annotation.dart';
import 'package:luka/features/sync/domain/synced_models.dart';

part 'catalog_dtos.g.dart';

/// `CategoryResponse` de `GET /categories` (spec 005 §7).
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class CategoryDto {
  const CategoryDto({
    required this.id,
    required this.name,
    required this.fiscalTag,
    required this.isSystem,
    this.userId,
    this.slug,
    this.icon,
    this.color,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryDtoFromJson(json);

  final String id;
  final String name;
  final String fiscalTag;
  final bool isSystem;
  final String? userId;
  final String? slug;
  final String? icon;
  final String? color;

  SyncedCategory toDomain() => SyncedCategory(
    id: id,
    name: name,
    fiscalTag: fiscalTag,
    isSystem: isSystem,
    userId: userId,
    slug: slug,
    icon: icon,
    color: color,
  );
}

/// `AccountResponse` de `GET /accounts` (spec 005 §7).
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class AccountDto {
  const AccountDto({
    required this.id,
    required this.bank,
    required this.kind,
    this.last4,
    this.alias,
  });

  factory AccountDto.fromJson(Map<String, dynamic> json) =>
      _$AccountDtoFromJson(json);

  final String id;
  final String bank;
  final String kind;
  final String? last4;
  final String? alias;

  SyncedAccount toDomain() =>
      SyncedAccount(id: id, bank: bank, kind: kind, last4: last4, alias: alias);
}
