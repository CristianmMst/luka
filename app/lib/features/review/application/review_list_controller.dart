import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/review/application/review_providers.dart';
import 'package:finanzia/features/review/domain/review_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lista de mensajes en revisión (spec 008 §3.5), en vivo sobre la base
/// local: convertir o descartar quita la fila al instante (optimista) y
/// cada pull la reemplaza por la del servidor.
///
/// Al cerrar sesión o entrar con otra cuenta se vuelve a suscribir.
class ReviewListController extends StreamNotifier<List<ReviewItem>> {
  @override
  Stream<List<ReviewItem>> build() {
    ref.watch(authControllerProvider.select(_sessionUserId));
    return ref.watch(reviewRepositoryProvider).watchOpen();
  }

  static String? _sessionUserId(AsyncValue<AuthState> auth) =>
      switch (auth.value) {
        Authenticated(:final user) => user.id,
        _ => null,
      };
}

final reviewListControllerProvider =
    StreamNotifierProvider<ReviewListController, List<ReviewItem>>(
      ReviewListController.new,
    );
