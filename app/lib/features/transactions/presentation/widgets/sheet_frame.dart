import 'dart:async';

import 'package:flutter/material.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';

/// Abre una hoja inferior con el marco de los diseños "Filtros" y
/// "Categoria": fondo de tarjeta, radio 24 arriba y el asa de 36×4.
///
/// Va en el navegador raíz: desde una pestaña del shell la hoja quedaría
/// debajo de la barra de navegación, que taparía sus últimas filas.
///
/// Si el contenido no cabe (un formulario largo o el teclado abierto), su
/// scroll se queda con el arrastre y la hoja ya no se cierra deslizando:
/// [_PullToDismiss] la cierra al tirar hacia abajo estando arriba del todo.
Future<T?> showLukaSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final brand = context.lukaColors;
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: brand.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.card)),
    ),
    builder: (context) => _PullToDismiss(child: builder(context)),
  );
}

/// Cierra la hoja cuando su scroll, ya en el tope, se sigue arrastrando hacia
/// abajo más de `_dismissPull`.
class _PullToDismiss extends StatefulWidget {
  const _PullToDismiss({required this.child});

  final Widget child;

  @override
  State<_PullToDismiss> createState() => _PullToDismissState();
}

class _PullToDismissState extends State<_PullToDismiss> {
  static const _dismissPull = 64.0;

  var _pulled = 0.0;
  var _popping = false;

  bool _onScroll(ScrollNotification notification) {
    switch (notification) {
      case ScrollStartNotification() || ScrollEndNotification():
        _pulled = 0;
      case OverscrollNotification(:final overscroll, :final dragDetails)
          when notification.depth == 0 && overscroll < 0 && dragDetails != null:
        _pulled -= overscroll;
        if (_pulled >= _dismissPull && !_popping) {
          _popping = true;
          unawaited(Navigator.maybePop(context));
        }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      // Sin rebote en iOS: el tope emite overscroll igual que en Android.
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(physics: const ClampingScrollPhysics()),
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: widget.child,
      ),
    );
  }
}

/// Asa centrada de la hoja.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
