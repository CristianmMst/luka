/// Enlace que va escrito en un tag NFC (spec 006 §5): lleva solo el id de
/// la plantilla, `finanzia://quick-add?tag=<uuid>`. Categoría, cuenta y
/// nota viven en el teléfono que configuró el tag.
const quickAddScheme = 'finanzia';
const quickAddHost = 'quick-add';

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

/// El enlace de la plantilla [tagId].
Uri quickAddUri(String tagId) => Uri(
  scheme: quickAddScheme,
  host: quickAddHost,
  queryParameters: {'tag': tagId},
);

/// El id de la plantilla si [uri] es un enlace de registro rápido válido;
/// `null` en cualquier otro caso (otro esquema, sin tag, id que no es uuid).
String? tagIdFromQuickAddUri(Uri uri) {
  if (uri.scheme.toLowerCase() != quickAddScheme) return null;
  if (uri.host.toLowerCase() != quickAddHost) return null;
  final tag = uri.queryParameters['tag']?.trim().toLowerCase();
  if (tag == null || !_uuid.hasMatch(tag)) return null;
  return tag;
}
