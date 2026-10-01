import 'package:flutter/material.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';

/// Grupo de filas de Ajustes (diseño AF): un título de sección y las filas
/// en una tarjeta con borde fino, separadas por una línea. Las filas no
/// traen fondo propio.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final brand = context.lukaColors;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Space.xs,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Space.xxs),
          child: Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Material(
          color: brand.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: brand.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, child) in children.indexed) ...[
                if (i > 0)
                  Divider(height: 1, thickness: 1, color: brand.hairline),
                child,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Ícono de una fila de Ajustes: cuadro neutro con el ícono en `primary`.
class SettingsIcon extends StatelessWidget {
  const SettingsIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.lukaColors.neutralChip,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        size: 20,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
