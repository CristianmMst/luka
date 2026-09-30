import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Contratos de capas (spec 003 §3), el equivalente a los contratos de
/// import-linter del backend:
///
/// - `domain` es Dart puro: sin Flutter, red, persistencia ni Riverpod.
/// - `application` no conoce `data` ni `presentation`.
/// - `presentation` no conoce `data`.
/// - `core` no conoce ninguna feature.
///
/// La única pieza que junta `application` con `data` es
/// `lib/app/composition.dart`.
void main() {
  final libDir = Directory('lib');

  Iterable<(String, List<String>)> dartFiles(String under) sync* {
    final dir = Directory('${libDir.path}/$under');
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync(recursive: true)) {
      final path = entity.path.replaceAll(r'\', '/');
      if (entity is! File ||
          !path.endsWith('.dart') ||
          path.endsWith('.g.dart') ||
          path.endsWith('.freezed.dart')) {
        continue;
      }
      final imports = entity
          .readAsLinesSync()
          .where((l) => l.startsWith('import '))
          .toList();
      yield (path, imports);
    }
  }

  List<String> violations(
    String under,
    bool Function(String path, String import) forbidden,
  ) => [
    for (final (path, imports) in dartFiles(under))
      for (final import in imports)
        if (forbidden(path, import)) '$path → $import',
  ];

  test('domain es Dart puro', () {
    const banned = [
      'package:flutter/',
      'package:flutter_riverpod',
      'package:dio',
      'package:drift',
      'package:flutter_secure_storage',
      'package:google_sign_in',
    ];
    final found = violations(
      'features',
      (path, import) =>
          path.contains('/domain/') && banned.any(import.contains),
    );
    expect(found, isEmpty);
  });

  test('domain no importa capas externas', () {
    final found = violations(
      'features',
      (path, import) =>
          path.contains('/domain/') &&
          RegExp('/(data|application|presentation)/').hasMatch(import),
    );
    expect(found, isEmpty);
  });

  test('application no importa data ni presentation', () {
    final found = violations(
      'features',
      (path, import) =>
          path.contains('/application/') &&
          RegExp('/(data|presentation)/').hasMatch(import),
    );
    expect(found, isEmpty);
  });

  test('presentation no importa data', () {
    final found = violations(
      'features',
      (path, import) =>
          path.contains('/presentation/') && import.contains('/data/'),
    );
    expect(found, isEmpty);
  });

  test('core no depende de features ni de app', () {
    final found = violations(
      'core',
      (path, import) =>
          import.contains('package:luka/features/') ||
          import.contains('package:luka/app/'),
    );
    expect(found, isEmpty);
  });
}
