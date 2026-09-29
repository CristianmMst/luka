import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/features/nfc/domain/nfc_ports.dart';
import 'package:finanzia/features/nfc/domain/quick_add_link.dart';
import 'package:finanzia/features/transactions/application/transaction_actions.dart';
import 'package:finanzia/features/transactions/domain/manual_draft.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:uuid/uuid.dart';

/// Puertos de NFC; se sobrescriben en `lib/app/composition.dart`.
final nfcTagStoreProvider = Provider<NfcTagStore>(
  (ref) => throw UnimplementedError(
    'nfcTagStoreProvider se sobrescribe en la composición',
  ),
);
final nfcServiceProvider = Provider<NfcService>(
  (ref) => throw UnimplementedError(
    'nfcServiceProvider se sobrescribe en la composición',
  ),
);

/// Escribir tags solo en Android (iOS lee en primer plano, spec 006 §5).
final nfcWriteSupportedProvider = Provider<bool>(
  (ref) => defaultTargetPlatform == TargetPlatform.android,
);

/// Botón "Leer tag NFC" en Registrar: en iOS no hay lectura con la app
/// cerrada, así que la sesión la abre el usuario (spec 006 §5).
final nfcManualReadProvider = Provider<bool>(
  (ref) => defaultTargetPlatform == TargetPlatform.iOS,
);

/// Reloj del registro rápido (la fecha del movimiento es la de guardar).
final nfcClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Las plantillas de tags de este teléfono.
final StreamProvider<List<NfcTagTemplate>> nfcTagsProvider =
    StreamProvider.autoDispose<List<NfcTagTemplate>>(
      (ref) => ref.watch(nfcTagStoreProvider).watchAll(),
    );

/// La plantilla de un tag leído; `null` si este teléfono no la conoce.
final FutureProviderFamily<NfcTagTemplate?, String> nfcTemplateProvider =
    FutureProvider.autoDispose.family<NfcTagTemplate?, String>(
      (ref, id) => ref.watch(nfcTagStoreProvider).get(id),
    );

/// Estado del NFC del teléfono (se vuelve a leer al abrir cada pantalla).
final FutureProvider<NfcAvailability> nfcAvailabilityProvider =
    FutureProvider.autoDispose<NfcAvailability>(
      (ref) => ref.watch(nfcServiceProvider).availability(),
    );

/// Crear, editar, borrar y escribir plantillas de tags, y guardar el
/// registro rápido (spec 006 §5, AC-4.1 a AC-4.3).
class NfcActions {
  NfcActions({
    required NfcTagStore store,
    required NfcService service,
    required TransactionActions transactions,
    required DateTime Function() now,
    String Function()? newId,
  }) : _store = store,
       _service = service,
       _transactions = transactions,
       _now = now,
       _newId = newId ?? const Uuid().v4;

  final NfcTagStore _store;
  final NfcService _service;
  final TransactionActions _transactions;
  final DateTime Function() _now;
  final String Function() _newId;

  /// Guarda la plantilla; sin [NfcTagTemplate.id] (vacío) crea una nueva.
  /// Devuelve la guardada.
  Future<NfcTagTemplate> save(NfcTagTemplate template) async {
    final name = template.name.trim();
    final note = template.note?.trim();
    final saved = template.copyWith(
      id: template.id.isEmpty ? _newId() : template.id,
      name: name,
      note: note == null || note.isEmpty ? null : note,
    );
    await _store.upsert(saved);
    return saved;
  }

  Future<void> delete(String id) => _store.remove(id);

  /// Espera un tag y le escribe el enlace de [template]. Un tag ya escrito
  /// se reescribe.
  Future<void> writeTag(NfcTagTemplate template) =>
      _service.write(quickAddUri(template.id));

  /// Registra el gasto del tag [tagId] por el outbox (funciona sin red) y,
  /// si [rememberAs] trae un nombre, guarda la plantilla para la próxima.
  /// Devuelve el id local del movimiento.
  Future<String> saveQuickAdd({
    required String tagId,
    required Cop amount,
    String? categoryId,
    String? accountId,
    String? note,
    String? rememberAs,
  }) async {
    final localId = await _transactions.create(
      ManualDraft(
        occurredAt: _now().toUtc(),
        amount: amount,
        categoryId: categoryId,
        accountId: accountId,
        notes: note,
        nfcTagId: tagId,
      ),
    );
    if (rememberAs != null) {
      await save(
        NfcTagTemplate(
          id: tagId,
          name: rememberAs,
          categoryId: categoryId,
          accountId: accountId,
          note: note,
        ),
      );
    }
    return localId;
  }
}

final nfcActionsProvider = Provider<NfcActions>(
  (ref) => NfcActions(
    store: ref.watch(nfcTagStoreProvider),
    service: ref.watch(nfcServiceProvider),
    transactions: ref.watch(transactionActionsProvider),
    now: ref.watch(nfcClockProvider),
  ),
);
