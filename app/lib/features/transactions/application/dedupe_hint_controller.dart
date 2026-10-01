import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/features/transactions/domain/dedupe_hint_store.dart';

/// Puerto de la marca del aviso "Sin duplicados"; se sobrescribe en
/// `lib/app/composition.dart`.
final dedupeHintStoreProvider = Provider<DedupeHintStore>(
  (ref) => throw UnimplementedError(
    'dedupeHintStoreProvider se sobrescribe en la composición',
  ),
);

/// Si Movimientos muestra el aviso "Sin duplicados": hasta que se descarte
/// una vez. Si la base local falla, no se muestra (es solo una ayuda).
class DedupeHintController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      return !await ref.read(dedupeHintStoreProvider).wasDismissed();
    } on Object {
      return false;
    }
  }

  /// Lo oculta al instante y guarda la marca.
  Future<void> dismiss() async {
    state = const AsyncData(false);
    await ref.read(dedupeHintStoreProvider).dismiss();
  }
}

final dedupeHintControllerProvider =
    AsyncNotifierProvider<DedupeHintController, bool>(DedupeHintController.new);
