// Gate de cobertura de las capas domain y application de las features
// (equivalente al gate de dominio del backend).
//
// Uso: dart run tool/coverage_gate.dart [coverage/lcov.info] [minimo=90]
import 'dart:io';

void main(List<String> args) {
  final path = args.isNotEmpty ? args[0] : 'coverage/lcov.info';
  final minimum = args.length > 1 ? double.parse(args[1]) : 90.0;
  final layer = RegExp('features/[^/]+/(domain|application)/');
  final generated = RegExp(r'\.(g|freezed)\.dart$');

  var found = 0;
  var hit = 0;
  String? file;
  var keep = false;
  for (final line in File(path).readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      file = line.substring(3).replaceAll(r'\', '/');
      keep = layer.hasMatch(file) && !generated.hasMatch(file);
    } else if (keep && line.startsWith('LF:')) {
      found += int.parse(line.substring(3));
    } else if (keep && line.startsWith('LH:')) {
      final lines = int.parse(line.substring(3));
      hit += lines;
      stdout.writeln('  $file: $lines líneas cubiertas');
    }
  }

  if (found == 0) {
    stderr.writeln('No hay líneas de domain/application en $path');
    exit(1);
  }
  final percent = 100 * hit / found;
  stdout.writeln(
    'Cobertura domain+application: ${percent.toStringAsFixed(1)} % '
    '($hit/$found), mínimo $minimum %',
  );
  if (percent < minimum) exit(1);
}
