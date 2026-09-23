import 'package:finanzia/features/transactions/domain/transaction_view.dart';

/// Mapa de vocales acentuadas y demás diacríticos frecuentes en español a su
/// equivalente sin tilde, para buscar sin depender de un paquete externo.
const Map<String, String> _diacritics = {
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'â': 'a',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'ê': 'e',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'î': 'i',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ô': 'o',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'û': 'u',
  'ñ': 'n',
};

/// Normaliza para buscar: minúsculas y sin tildes (`"Éxito" → "exito"`).
String normalizeForSearch(String s) {
  final buffer = StringBuffer();
  for (final rune in s.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_diacritics[char] ?? char);
  }
  return buffer.toString();
}

/// `true` si [query] aparece (normalizada) en el comercio, la categoría o
/// las notas de [t]. El banco no se busca aquí: tiene su propio filtro.
/// Una búsqueda vacía siempre coincide.
bool matchesText(TransactionView t, String query) {
  final needle = normalizeForSearch(query.trim());
  if (needle.isEmpty) return true;
  final haystack = normalizeForSearch(
    [t.merchant, t.categoryName, t.notes].whereType<String>().join(' '),
  );
  return haystack.contains(needle);
}
