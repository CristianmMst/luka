import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef_record/ndef_record.dart';

/// Tipo del registro URI de NFC Forum ("U").
final _uriType = Uint8List.fromList([0x55]);

/// Prefijos abreviados del registro URI (NFC Forum RTD URI, tabla 3). Al
/// escribir se usa `0x00` (sin abreviar); al leer se aceptan los comunes.
const _prefixes = <int, String>{
  0x00: '',
  0x01: 'http://www.',
  0x02: 'https://www.',
  0x03: 'http://',
  0x04: 'https://',
};

/// Registro NDEF con [uri] completo, sin prefijo abreviado.
NdefRecord uriRecord(Uri uri) => NdefRecord(
  typeNameFormat: TypeNameFormat.wellKnown,
  type: _uriType,
  identifier: Uint8List(0),
  payload: Uint8List.fromList([0x00, ...utf8.encode(uri.toString())]),
);

/// El primer URI de [message] (registro "U" o de URI absoluto); `null` si no
/// trae ninguno legible.
Uri? firstUri(NdefMessage? message) {
  for (final record in message?.records ?? const <NdefRecord>[]) {
    final uri = switch (record.typeNameFormat) {
      TypeNameFormat.wellKnown when _isUriType(record.type) => _decodeUri(
        record.payload,
      ),
      TypeNameFormat.absoluteUri => Uri.tryParse(
        utf8.decode(record.type, allowMalformed: true),
      ),
      _ => null,
    };
    if (uri != null) return uri;
  }
  return null;
}

bool _isUriType(Uint8List type) => type.length == 1 && type[0] == 0x55;

Uri? _decodeUri(Uint8List payload) {
  if (payload.isEmpty) return null;
  final prefix = _prefixes[payload[0]];
  if (prefix == null) return null;
  final rest = utf8.decode(payload.sublist(1), allowMalformed: true);
  return Uri.tryParse('$prefix$rest');
}
