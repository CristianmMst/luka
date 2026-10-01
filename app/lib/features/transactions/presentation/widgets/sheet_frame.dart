import 'package:flutter/material.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';

/// Abre una hoja inferior con el marco de los diseños "Filtros" y
/// "Categoria": fondo de tarjeta, radio 24 arriba y el asa de 36×4.
///
/// Va en el navegador raíz: desde una pestaña del shell la hoja quedaría
/// debajo de la barra de navegación, que taparía sus últimas filas.
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
    builder: builder,
  );
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
