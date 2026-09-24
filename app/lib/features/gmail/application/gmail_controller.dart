import 'dart:async';

import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/gmail/domain/gmail_connection.dart';
import 'package:finanzia/features/gmail/domain/gmail_failure.dart';
import 'package:finanzia/features/gmail/domain/gmail_prompt_store.dart';
import 'package:finanzia/features/gmail/domain/gmail_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'gmail_controller.freezed.dart';

/// Puertos de Gmail para la capa de aplicación; se sobrescriben en
/// `lib/app/composition.dart`.
final gmailRepositoryProvider = Provider<GmailRepository>(
  (ref) => throw UnimplementedError(
    'gmailRepositoryProvider se sobrescribe en la composición',
  ),
);

final gmailPromptStoreProvider = Provider<GmailPromptStore>(
  (ref) => throw UnimplementedError(
    'gmailPromptStoreProvider se sobrescribe en la composición',
  ),
);

/// Lo que las pantallas de Gmail necesitan saber.
@freezed
abstract class GmailState with _$GmailState {
  const factory GmailState({
    required GmailConnectionInfo info,

    /// El usuario eligió "Ahora no" (o no hay sesión a quién preguntarle).
    required bool promptDismissed,

    /// Hay un connect o disconnect en curso: la pantalla bloquea el botón.
    @Default(false) bool busy,

    /// Último fallo de una acción, para el aviso de la pantalla. `null` tras
    /// un éxito o una cancelación.
    GmailFailure? failure,
  }) = _GmailState;

  const GmailState._();

  /// Mostrar la invitación a conectar Gmail tras el login.
  bool get shouldPrompt =>
      !promptDismissed && info.status == GmailStatus.disconnected;
}

/// Conexión de Gmail del usuario en sesión.
///
/// `build` lee el "Ahora no" local y el estado del backend; si el backend no
/// responde queda en `AsyncError` con el `GmailFailure`. Las acciones nunca
/// lanzan: devuelven si salieron bien y dejan el fallo en
/// [GmailState.failure].
class GmailController extends AsyncNotifier<GmailState> {
  String? _userId;

  @override
  Future<GmailState> build() async {
    final auth = await ref.watch(authControllerProvider.future);
    if (auth is! Authenticated) {
      _userId = null;
      return const GmailState(
        info: GmailConnectionInfo.disconnected,
        promptDismissed: true,
      );
    }
    final userId = _userId = auth.user.id;
    final dismissed = await ref
        .read(gmailPromptStoreProvider)
        .isDismissed(userId);
    final info = await ref.read(gmailRepositoryProvider).status();
    return GmailState(info: info, promptDismissed: dismissed);
  }

  /// Abre el consentimiento de Google y conecta Gmail. Cancelar no deja
  /// fallo.
  Future<bool> connect() => _run((gmail) async {
    final info = await gmail.connect();
    _update((s) => s.copyWith(info: info));
  });

  /// Desconecta Gmail (spec 005 §3, AC-11.1).
  Future<bool> disconnect() => _run((gmail) async {
    await gmail.disconnect();
    _update((s) => s.copyWith(info: GmailConnectionInfo.disconnected));
  });

  /// "Ahora no": no volver a invitar a este usuario.
  Future<void> skip() async {
    final userId = _userId;
    if (userId == null) return;
    await ref.read(gmailPromptStoreProvider).dismiss(userId);
    _update((s) => s.copyWith(promptDismissed: true));
  }

  /// Vuelve a leer el estado del backend. Si falla, conserva el último
  /// estado conocido y deja el fallo; desde un `AsyncError` reconstruye.
  Future<void> refresh() async {
    if (state.value == null) {
      ref.invalidateSelf();
      try {
        await future;
      } on GmailFailure {
        // Queda en AsyncError; la pantalla lo muestra.
      }
      return;
    }
    if (_userId == null) return;
    try {
      final info = await ref.read(gmailRepositoryProvider).status();
      _update((s) => s.copyWith(info: info, failure: null));
    } on GmailFailure catch (failure) {
      _update((s) => s.copyWith(failure: failure));
    }
  }

  Future<bool> _run(Future<void> Function(GmailRepository) action) async {
    final current = state.value;
    if (current == null || current.busy || _userId == null) return false;
    state = AsyncData(current.copyWith(busy: true, failure: null));
    try {
      await action(ref.read(gmailRepositoryProvider));
      _update((s) => s.copyWith(busy: false));
      return true;
    } on GmailConsentCancelled {
      _update((s) => s.copyWith(busy: false));
    } on GmailFailure catch (failure) {
      _update((s) => s.copyWith(busy: false, failure: failure));
    }
    return false;
  }

  void _update(GmailState Function(GmailState) change) {
    if (!ref.mounted) return;
    final current = state.value;
    if (current != null) state = AsyncData(change(current));
  }
}

/// Sin reintento automático de Riverpod: un fallo de red queda en
/// `AsyncError` y la pantalla ofrece reintentar ([GmailController.refresh]).
final gmailControllerProvider =
    AsyncNotifierProvider<GmailController, GmailState>(
      GmailController.new,
      retry: (_, _) => null,
    );
