import 'package:freezed_annotation/freezed_annotation.dart';

part 'nfc_ports.freezed.dart';

/// Plantilla de un tag NFC (spec 006 §5): lo que el registro rápido deja
/// listo al acercar el tag. Vive solo en el teléfono que la creó.
@freezed
abstract class NfcTagTemplate with _$NfcTagTemplate {
  const factory NfcTagTemplate({
    required String id,
    required String name,
    String? categoryId,
    String? accountId,
    String? note,
  }) = _NfcTagTemplate;

  const NfcTagTemplate._();

  /// El límite del nombre en el formulario.
  static const maxNameLength = 60;
}

/// Estado del lector NFC del teléfono.
enum NfcAvailability {
  /// Encendido y listo.
  enabled,

  /// El teléfono tiene NFC pero está apagado en los ajustes.
  disabled,

  /// El teléfono no tiene NFC.
  unsupported,
}

/// Por qué no se pudo leer o escribir un tag.
sealed class NfcFailure implements Exception {
  const NfcFailure();
}

/// NFC apagado o inexistente.
final class NfcUnavailable extends NfcFailure {
  const NfcUnavailable(this.availability);

  final NfcAvailability availability;
}

/// El tag no admite NDEF o es de solo lectura.
final class NfcTagNotWritable extends NfcFailure {
  const NfcTagNotWritable();
}

/// El enlace no cabe en el tag.
final class NfcTagTooSmall extends NfcFailure {
  const NfcTagTooSmall();
}

/// El usuario canceló, o el tag se alejó antes de terminar.
final class NfcCancelled extends NfcFailure {
  const NfcCancelled();
}

/// Cualquier otro error de lectura o escritura.
final class NfcIoError extends NfcFailure {
  const NfcIoError();
}

/// Lector y escritor de tags. Una operación a la vez: la sesión termina al
/// primer tag, con éxito o con [NfcFailure].
abstract interface class NfcService {
  Future<NfcAvailability> availability();

  /// Espera un tag y le escribe [uri] (solo Android).
  Future<void> write(Uri uri);

  /// Espera un tag y devuelve el primer enlace que trae (`null` si no trae
  /// ninguno). En iOS abre la hoja de lectura del sistema.
  Future<Uri?> readUri();

  /// Corta la sesión en curso, si hay.
  Future<void> cancel();
}

/// Copia local de las plantillas de tags.
abstract interface class NfcTagStore {
  /// Todas, por nombre.
  Stream<List<NfcTagTemplate>> watchAll();

  Future<NfcTagTemplate?> get(String id);

  Future<void> upsert(NfcTagTemplate template);

  Future<void> remove(String id);
}
