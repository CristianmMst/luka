import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/nfc/data/ndef_uri.dart';
import 'package:ndef_record/ndef_record.dart';

void main() {
  final uri = Uri.parse(
    'luka://quick-add?tag=3f2b8c1e-5a4d-4e6f-9b7a-1c2d3e4f5a6b',
  );

  test('el registro URI va sin prefijo abreviado', () {
    final record = uriRecord(uri);

    expect(record.typeNameFormat, TypeNameFormat.wellKnown);
    expect(record.type, [0x55]);
    expect(record.payload.first, 0x00);
    expect(utf8.decode(record.payload.sublist(1)), uri.toString());
  });

  test('ida y vuelta por un mensaje NDEF', () {
    expect(firstUri(NdefMessage(records: [uriRecord(uri)])), uri);
  });

  test('lee prefijos abreviados y URI absoluto', () {
    final https = NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x55]),
      identifier: Uint8List(0),
      payload: Uint8List.fromList([0x04, ...utf8.encode('luka.co')]),
    );
    expect(
      firstUri(NdefMessage(records: [https])),
      Uri.parse('https://luka.co'),
    );

    final absolute = NdefRecord(
      typeNameFormat: TypeNameFormat.absoluteUri,
      type: Uint8List.fromList(utf8.encode(uri.toString())),
      identifier: Uint8List(0),
      payload: Uint8List(0),
    );
    expect(firstUri(NdefMessage(records: [absolute])), uri);
  });

  test('sin URI o sin mensaje devuelve null', () {
    final text = NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x54]),
      identifier: Uint8List(0),
      payload: Uint8List.fromList([0x02, ...utf8.encode('eshola')]),
    );
    expect(firstUri(NdefMessage(records: [text])), isNull);
    expect(firstUri(null), isNull);
  });
}
