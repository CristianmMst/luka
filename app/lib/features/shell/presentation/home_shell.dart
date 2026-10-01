import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';

/// Shell de la app autenticada: un `IndexedStack` de 5 ramas con la barra
/// de navegación inferior translúcida (spec 008 §7.1): el contenido pasa por
/// debajo (`extendBody`), así que cada pestaña suma
/// `MediaQuery.paddingOf(context).bottom` a su margen inferior.
class HomeShell extends ConsumerWidget {
  const HomeShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewCount = ref.watch(openReviewCountProvider).value ?? 0;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _MainNavigationBar(
        currentIndex: navigationShell.currentIndex,
        reviewCount: reviewCount,
        onSelect: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// Barra inferior de 80 dp: material blanco translúcido con blur y una línea
/// fina arriba; el destino activo en `primary`, "Registrar" como botón
/// circular y el badge de "Revisión". Con alto contraste es opaca.
class _MainNavigationBar extends StatelessWidget {
  const _MainNavigationBar({
    required this.currentIndex,
    required this.reviewCount,
    required this.onSelect,
  });

  static const _height = 80.0;

  final int currentIndex;
  final int reviewCount;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final opaque = MediaQuery.highContrastOf(context);
    final material = scheme.surfaceContainerLowest;

    return ClipRect(
      child: BackdropFilter(
        filter: opaque
            ? ImageFilter.blur()
            : ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: opaque ? material : material.withValues(alpha: 0.84),
            border: Border(
              top: BorderSide(color: scheme.onSurface.withValues(alpha: 0.08)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: _height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Destination(
                    icon: Icons.home_outlined,
                    label: l10n.navHomeLabel,
                    selected: currentIndex == 0,
                    onTap: () => onSelect(0),
                  ),
                  _Destination(
                    icon: Icons.receipt_long_outlined,
                    label: l10n.navTransactionsLabel,
                    selected: currentIndex == 1,
                    onTap: () => onSelect(1),
                  ),
                  _RegisterDestination(
                    label: l10n.navRegisterLabel,
                    selected: currentIndex == 2,
                    onTap: () => onSelect(2),
                  ),
                  _Destination(
                    icon: Icons.fact_check_outlined,
                    label: l10n.navReviewLabel,
                    selected: currentIndex == 3,
                    onTap: () => onSelect(3),
                    badgeCount: reviewCount,
                    badgeSemantics: l10n.reviewBadgeSemantics(reviewCount),
                  ),
                  _Destination(
                    icon: Icons.settings_outlined,
                    label: l10n.navSettingsLabel,
                    selected: currentIndex == 4,
                    onTap: () => onSelect(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
    this.badgeSemantics,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;
  final String? badgeSemantics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        label: label,
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 30,
                    child: Icon(icon, size: 24, color: color),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -6,
                      right: 4,
                      child: Semantics(
                        label: badgeSemantics,
                        container: true,
                        explicitChildNodes: true,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            border: Border.all(
                              color: scheme.surfaceContainerLowest,
                              width: 1.5,
                            ),
                            // Píldora: con 10 o más crece a lo ancho sin
                            // recortar los dígitos; con uno es un círculo.
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: ExcludeSemantics(
                            child: Text(
                              '$badgeCount',
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              ExcludeSemantics(
                child: Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Registrar": botón circular `primary` de 52 dp con su sombra; en esa
/// pestaña lleva un anillo amarillo de marca.
class _RegisterDestination extends StatelessWidget {
  const _RegisterDestination({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Semantics(
        label: label,
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary,
                border: selected
                    ? Border.all(color: context.lukaColors.gold, width: 4)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.45),
                    blurRadius: 14,
                    spreadRadius: -4,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(Icons.add, color: scheme.onPrimary, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
