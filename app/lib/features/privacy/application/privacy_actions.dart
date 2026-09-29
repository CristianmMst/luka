import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/privacy/domain/privacy_ports.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puertos de privacidad; se sobrescriben en `lib/app/composition.dart`.
final privacyRemoteProvider = Provider<PrivacyRemote>(
  (ref) => throw UnimplementedError(
    'privacyRemoteProvider se sobrescribe en la composición',
  ),
);
final exportSaverProvider = Provider<ExportSaver>(
  (ref) => throw UnimplementedError(
    'exportSaverProvider se sobrescribe en la composición',
  ),
);

/// Nombre del archivo exportado: `finanzia-AAAA-MM-DD.json`.
String exportFileName(DateTime now) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'finanzia-${now.year}-${two(now.month)}-${two(now.day)}.json';
}

/// Exportar mis datos y borrar mi cuenta (RF-11.2/11.3, spec 008 §3.7).
class PrivacyActions {
  PrivacyActions({
    required PrivacyRemote remote,
    required ExportSaver saver,
    required Future<void> Function() signOut,
    DateTime Function()? now,
  }) : _remote = remote,
       _saver = saver,
       _signOut = signOut,
       _now = now ?? DateTime.now;

  final PrivacyRemote _remote;
  final ExportSaver _saver;
  final Future<void> Function() _signOut;
  final DateTime Function() _now;

  /// Descarga la exportación y la entrega al usuario para guardarla.
  Future<void> exportData() async {
    final json = await _remote.exportData();
    await _saver.save(json, fileName: exportFileName(_now()));
  }

  /// Borra la cuenta en el servidor y luego cierra la sesión, que borra la
  /// base local (P6). Si el servidor falla, no se toca nada local.
  Future<void> deleteAccount() async {
    await _remote.deleteAccount();
    await _signOut();
  }
}

final privacyActionsProvider = Provider<PrivacyActions>(
  (ref) => PrivacyActions(
    remote: ref.watch(privacyRemoteProvider),
    saver: ref.watch(exportSaverProvider),
    signOut: () => ref.read(authControllerProvider.notifier).signOut(),
  ),
);
