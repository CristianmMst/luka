import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';

/// Deslizar hacia abajo sincroniza (spec 008 §5): push del outbox y pull,
/// el mismo ciclo que corre al abrir la app. El indicador se queda hasta que
/// el ciclo termina; sin red, el aviso de "sin conexión" de la pantalla ya
/// lo dice.
///
/// [child] debe ser desplazable. Un estado que no lo es (vacío, error) va
/// con [SyncRefresh.fill], que lo pone en un área desplazable del alto de
/// la pantalla para poder tirar de él.
class SyncRefresh extends ConsumerWidget {
  const SyncRefresh({required this.child, super.key}) : _fill = false;

  const SyncRefresh.fill({required this.child, super.key}) : _fill = true;

  final Widget child;
  final bool _fill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(syncCoordinatorProvider.notifier).sync(),
      child: _fill
          // Alto exacto de la pantalla (no intrínseco: algunos estados usan
          // LayoutBuilder, que no lo admite).
          ? LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(height: constraints.maxHeight, child: child),
              ),
            )
          : child,
    );
  }
}
