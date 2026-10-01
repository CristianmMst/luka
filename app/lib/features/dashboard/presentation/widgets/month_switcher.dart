import 'package:flutter/material.dart';
import 'package:luka/core/time/colombia_month.dart';

/// Cambia [child] al cambiar [month] con una transición que entra por el
/// lado del mes elegido: el siguiente desde la derecha, el anterior desde la
/// izquierda (24 px y fundido, 220 ms, ease-out). Con "reducir movimiento"
/// el cambio es inmediato.
class MonthSwitcher extends StatefulWidget {
  const MonthSwitcher({required this.month, required this.child, super.key});

  final ColombiaMonth month;
  final Widget child;

  static const duration = Duration(milliseconds: 220);

  @override
  State<MonthSwitcher> createState() => _MonthSwitcherState();
}

class _MonthSwitcherState extends State<MonthSwitcher> {
  /// 1 si se avanzó de mes, -1 si se retrocedió.
  var _direction = 1;

  @override
  void didUpdateWidget(MonthSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month != widget.month) {
      _direction = widget.month.isAfter(oldWidget.month) ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final instant = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: instant ? Duration.zero : MonthSwitcher.duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        // El que entra viene del lado del mes elegido; el que sale se va
        // por el contrario.
        final incoming = child.key == ValueKey(widget.month);
        final from = (incoming ? 24 : -24) * _direction.toDouble();
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Opacity(
            opacity: animation.value,
            child: Transform.translate(
              offset: Offset(from * (1 - animation.value), 0),
              child: child,
            ),
          ),
          child: child,
        );
      },
      child: KeyedSubtree(key: ValueKey(widget.month), child: widget.child),
    );
  }
}
