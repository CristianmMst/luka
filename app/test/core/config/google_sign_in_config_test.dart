import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/config/app_config.dart';

/// En iOS el plugin de Google Sign-In lee los client IDs de `Info.plist`
/// (vía `GoogleSignIn.xcconfig`) e ignora el `serverClientId` de Dart. Estos
/// tests evitan que las dos fuentes se separen sin que nadie lo note.
void main() {
  final xcconfig = _readXcconfig('ios/Flutter/GoogleSignIn.xcconfig');
  final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

  test('el cliente web de iOS es el mismo que usa Dart', () {
    expect(
      xcconfig['GOOGLE_SERVER_CLIENT_ID'],
      AppConfig.devGoogleServerClientId,
    );
  });

  test('el esquema de URL es el client ID de iOS invertido', () {
    final clientId = xcconfig['GOOGLE_IOS_CLIENT_ID']!;
    const suffix = '.apps.googleusercontent.com';
    expect(clientId, endsWith(suffix));
    expect(
      xcconfig['GOOGLE_IOS_REVERSED_CLIENT_ID'],
      'com.googleusercontent.apps.'
      '${clientId.substring(0, clientId.length - suffix.length)}',
    );
  });

  test('Info.plist toma los tres valores del xcconfig', () {
    for (final (key, variable) in [
      ('GIDClientID', 'GOOGLE_IOS_CLIENT_ID'),
      ('GIDServerClientID', 'GOOGLE_SERVER_CLIENT_ID'),
    ]) {
      expect(
        infoPlist,
        matches(
          RegExp(
            '<key>$key</key>'
            r'\s*<string>\$\('
            '$variable'
            r'\)</string>',
          ),
        ),
        reason: key,
      );
    }
    expect(infoPlist, contains(r'$(GOOGLE_IOS_REVERSED_CLIENT_ID)'));
  });
}

Map<String, String> _readXcconfig(String path) => {
  for (final line in File(path).readAsLinesSync())
    if (RegExp(r'^\s*([A-Z_]+)\s*=\s*(.+?)\s*$').firstMatch(line)
        case final match?)
      match.group(1)!: match.group(2)!,
};
