import 'dart:async';

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
/// - Cargando → [GmailGate.pending], pero como mucho [timeout]: sin red o con
///   una red lenta la app no se queda en el splash (P4) y sigue a Inicio.
/// - Error al leer el estado → [GmailGate.skip]: Gmail es opcional y se
///   conecta después desde Ajustes (AC-1.3).
/// - Con datos → [GmailState.shouldPrompt].
class GmailGateController extends Notifier<GmailGate> {
  /// Espera máxima del splash por el estado de Gmail.
  static const timeout = Duration(seconds: 4);

  @override
  GmailGate build() {
    final gmail = ref.watch(gmailControllerProvider);
    if (gmail.isLoading) {
      final timer = Timer(timeout, () {
        if (ref.mounted) state = GmailGate.skip;
      });
      ref.onDispose(timer.cancel);
      return GmailGate.pending;
    }
    if (gmail.hasError) return GmailGate.skip;
    return gmail.requireValue.shouldPrompt ? GmailGate.prompt : GmailGate.skip;
  }
}

final gmailGateProvider = NotifierProvider<GmailGateController, GmailGate>(
  GmailGateController.new,
);
