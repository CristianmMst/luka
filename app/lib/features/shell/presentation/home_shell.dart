import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/finanzia_colors.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Shell de la app autenticada: un `IndexedStack` de 5 ramas con una barra
/// de navegación inferior fija (diseño "ListaB", spec 008 §7).
class HomeShell extends ConsumerWidget {
  const HomeShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewCount = ref.watch(openReviewCountProvider).value ?? 0;

    return Scaffold(
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

/// Barra inferior de 80 dp con indicador `primaryContainer`, el botón
/// circular de "Registrar" y el badge de "Revisión".
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
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
    final brand = context.finanziaColors;
    final textTheme = Theme.of(context).textTheme;
    final iconColor = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    final labelColor = selected ? scheme.onSurface : scheme.onSurfaceVariant;

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
                  Container(
                    width: 56,
                    height: 30,
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 22, color: iconColor),
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
                            color: brand.expense,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: ExcludeSemantics(
                            child: Text(
                              '$badgeCount',
                              style: textTheme.labelSmall?.copyWith(
                                color: brand.onExpense,
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
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: labelColor,
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

/// "Registrar": botón circular `primary` de 52 dp, sin indicador de
/// selección (siempre el mismo estilo, como una acción).
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
              ),
              child: Icon(Icons.add, color: scheme.onPrimary, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
