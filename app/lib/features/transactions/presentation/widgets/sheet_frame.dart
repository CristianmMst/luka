import 'package:finanzia/core/theme/finanzia_colors.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:flutter/material.dart';

/// Abre una hoja inferior con el marco de los diseños "Filtros" y
/// "Categoria": fondo de tarjeta, radio 24 arriba y el asa de 36×4.
Future<T?> showFinanziaSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final brand = context.finanziaColors;
  return showModalBottomSheet<T>(
    context: context,
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
