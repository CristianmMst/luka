import 'dart:io';

import 'package:finanzia/features/privacy/domain/privacy_ports.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// [ExportSaver] con la hoja de compartir del sistema: el JSON se escribe en
/// un archivo temporal y el usuario elige dónde guardarlo o a quién
/// mandarlo.
///
/// El archivo no se borra al volver de la hoja: la app de destino puede
/// seguir leyéndolo. Se borran las exportaciones viejas antes de escribir
/// una nueva, y el sistema limpia el directorio temporal.
class ShareExportSaver implements ExportSaver {
  const ShareExportSaver();

  static final _exportName = RegExp(r'^finanzia-\d{4}-\d{2}-\d{2}\.json$');

  @override
  Future<void> save(String json, {required String fileName}) async {
    final dir = await getTemporaryDirectory();
    for (final old in dir.listSync().whereType<File>()) {
      final name = old.uri.pathSegments.last;
      if (_exportName.hasMatch(name)) await old.delete();
    }
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(json, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        fileNameOverrides: [fileName],
      ),
    );
  }
}
