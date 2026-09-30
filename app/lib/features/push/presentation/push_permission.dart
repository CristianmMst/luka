import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/push/application/push_registrar.dart';
import 'package:luka/features/push/domain/push_ports.dart';
import 'package:luka/features/transactions/presentation/widgets/sheet_frame.dart';

/// Tras guardar el primer gasto fijo: explica el aviso y, si el usuario
/// acepta, pide el permiso del sistema (P6, spec 008 §3.8). No hace nada si
/// ya se preguntó, ya está concedido o no hay Firebase.
Future<void> maybeAskPushPermission(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final registrar = container.read(pushRegistrarProvider.notifier);
  if (!await registrar.shouldExplainPermission() || !context.mounted) return;
  final accepted = await showLukaSheet<bool>(
    context,
    builder: (_) => const PushPermissionSheet(),
  );
  if (accepted ?? false) {
    await registrar.requestPermission();
  } else {
    // "Ahora no" también cuenta como preguntado: no se insiste en cada gasto.
    await container.read(pushPrefsProvider).markPermissionAsked();
  }
}

/// "¿Te avisamos antes de cada pago?" con un ejemplo del aviso.
class PushPermissionSheet extends StatelessWidget {
  const PushPermissionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, 10, Space.lg, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Space.sm,
          children: [
            const SheetHandle(),
            Semantics(
              header: true,
              child: Text(
                l10n.pushAskTitle,
                style: textTheme.headlineSmall?.copyWith(fontSize: 22),
              ),
            ),
            Text(
              l10n.pushAskBody,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            // Ejemplo del aviso (el mismo texto que envía el backend).
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.lukaColors.tile,
                borderRadius: Radii.noticeAll,
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Space.sm,
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: scheme.primary,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(
                            l10n.pushAskExampleTitle,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            l10n.pushAskExampleBody,
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(l10n.pushAskAllow),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(minTouchTarget),
              ),
              child: Text(l10n.pushAskLater),
            ),
          ],
        ),
      ),
    );
  }
}

/// Franja "Los avisos están apagados · Activar" (AC-12.6). Solo aparece con
/// Firebase y el permiso negado; se relee al volver a primer plano.
class PushOffBanner extends ConsumerStatefulWidget {
  const PushOffBanner({super.key});

  @override
  ConsumerState<PushOffBanner> createState() => _PushOffBannerState();
}

class _PushOffBannerState extends ConsumerState<PushOffBanner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(pushRegistrarProvider.notifier).refreshPermission());
    }
  }

  Future<void> _activate() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final permission = await ref
        .read(pushRegistrarProvider.notifier)
        .requestPermission();
    // Android e iOS no vuelven a mostrar el diálogo si ya se negó: se
    // explica dónde activarlo.
    if (permission != PushPermission.granted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.pushOffSettingsHint)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;
    final available = ref.watch(pushServiceProvider).isAvailable;
    final permission = ref.watch(
      pushRegistrarProvider.select((s) => s.permission),
    );
    if (!available || permission != PushPermission.denied) {
      return const SizedBox.shrink();
    }
    return Material(
      color: brand.warningContainer,
      borderRadius: Radii.rowAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(_activate()),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: Space.xs,
            ),
            child: Row(
              spacing: Space.sm,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  color: brand.onWarningContainer,
                ),
                Expanded(
                  child: Text(
                    '${l10n.pushOffBanner} · ${l10n.pushOffAction} ›',
                    style: textTheme.labelLarge?.copyWith(
                      color: brand.onWarningContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
