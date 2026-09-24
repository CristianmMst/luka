import 'dart:async';

import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/gmail/application/gmail_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Qué necesita saber el session gate sobre Gmail al salir del splash o del
/// login (spec 008 §2).
enum GmailGate {
  /// Todavía se lee el estado: el gate espera en el splash.
  pending,

  /// Toca invitar a conectar Gmail (`/onboarding/gmail`).
  prompt,

  /// Ya conectado, descartado o sin poder saberlo: directo a Inicio.
  skip,
}

/// Deriva [GmailGate] de [gmailControllerProvider].
///
/// - Cargando → [GmailGate.pending], salvo que:
///   - el "Ahora no" ya se leyó de local: [GmailGate.skip] sin esperar el
///     estado del backend;
///   - pasó [timeout] desde que la sesión es [Authenticated] (no desde la
///     primera lectura, que puede caer mientras se restaura la sesión): sin
///     red o con una red lenta la app no se queda en el splash (P4) y sigue
///     a Inicio.
/// - Error al leer el estado → [GmailGate.skip]: Gmail es opcional y se
///   conecta después desde Ajustes (AC-1.3).
/// - Con datos → [GmailState.shouldPrompt].
class GmailGateController extends Notifier<GmailGate> {
  /// Espera máxima del splash por el estado de Gmail.
  static const timeout = Duration(seconds: 4);

  @override
  GmailGate build() {
    final timedOut = ref.watch(_gateTimedOutProvider);
    final dismissed = ref.watch(gmailPromptDismissedProvider);
    final gmail = ref.watch(gmailControllerProvider);
    if (gmail.isLoading) {
      // Durante una recarga (p. ej. tras un login) el valor previo es de la
      // sesión anterior: no vale para decidir.
      if (!dismissed.isLoading && (dismissed.value ?? false)) {
        return GmailGate.skip;
      }
      return timedOut ? GmailGate.skip : GmailGate.pending;
    }
    if (gmail.hasError) return GmailGate.skip;
    return gmail.requireValue.shouldPrompt ? GmailGate.prompt : GmailGate.skip;
  }
}

/// `true` cuando pasaron [GmailGateController.timeout] desde que la sesión
/// es [Authenticated] sin que llegara el estado de Gmail; vuelve a `false`
/// y se rearma con cada sesión nueva. El timer solo corre mientras el estado
/// carga: al llegar se cancela.
final _gateTimedOutProvider = NotifierProvider<_GateTimeout, bool>(
  _GateTimeout.new,
);

class _GateTimeout extends Notifier<bool> {
  @override
  bool build() {
    final userId = ref.watch(
      authControllerProvider.select(
        (auth) => switch (auth.value) {
          Authenticated(:final user) => user.id,
          _ => null,
        },
      ),
    );
    final loading = ref.watch(
      gmailControllerProvider.select((gmail) => gmail.isLoading),
    );
    if (userId == null || !loading) return false;
    final timer = Timer(GmailGateController.timeout, () {
      if (ref.mounted) state = true;
    });
    ref.onDispose(timer.cancel);
    return false;
  }
}

final gmailGateProvider = NotifierProvider<GmailGateController, GmailGate>(
  GmailGateController.new,
);
