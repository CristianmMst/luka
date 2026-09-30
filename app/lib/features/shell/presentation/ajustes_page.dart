import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/accounts/presentation/accounts_settings_tile.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/auth/domain/entities/user.dart';
import 'package:luka/features/capture/application/notification_access_controller.dart';
import 'package:luka/features/capture/presentation/widgets/apple_pay_settings_tile.dart';
import 'package:luka/features/capture/presentation/widgets/notification_capture_tile.dart';
import 'package:luka/features/categories/presentation/categories_settings_tile.dart';
import 'package:luka/features/dashboard/presentation/widgets/dashboard_format.dart';
import 'package:luka/features/gmail/presentation/widgets/gmail_settings_tile.dart';
import 'package:luka/features/nfc/application/nfc_actions.dart';
import 'package:luka/features/nfc/presentation/nfc_tags_settings_tile.dart';
import 'package:luka/features/privacy/presentation/privacy_sheet.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/sync/presentation/sync_sheet.dart';

/// "Ajustes" (diseño B "Perfil arriba + lista plana", F4.8b, spec 008 §3.7):
/// hero esmeralda con el perfil y la línea de sync (abre la hoja de
/// sincronización), y debajo las conexiones, mis datos, privacidad y cerrar
/// sesión.
class AjustesPage extends ConsumerWidget {
  const AjustesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = switch (ref.watch(authControllerProvider)) {
      AsyncData(value: Authenticated(:final user)) => user,
      _ => null,
    };

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        // El hero va detrás de la barra de estado en ambos temas.
        value: SystemUiOverlayStyle.light,
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.lg),
          children: [
            _Hero(user: user),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.md,
                Space.md,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Space.sm,
                children: [
                  const GmailSettingsTile(),
                  const NotificationCaptureTile(),
                  if (ref.watch(walletCaptureSupportedProvider))
                    const ApplePaySettingsTile(),
                  const CategoriesSettingsTile(),
                  const AccountsSettingsTile(),
                  if (ref.watch(nfcWriteSupportedProvider))
                    const NfcTagsSettingsTile(),
                  const _PrivacyTile(),
                  const SizedBox(height: Space.xs),
                  OutlinedButton(
                    onPressed: () => unawaited(
                      ref.read(authControllerProvider.notifier).signOut(),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(l10n.homeSignOut),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Iniciales para el avatar: "Cristian Mora" → "CM"; sin nombre, la primera
/// letra del correo.
String profileInitials(User? user) {
  final words = (user?.displayName ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isNotEmpty) {
    final first = words.first[0];
    final last = words.length > 1 ? words.last[0] : '';
    return (first + last).toUpperCase();
  }
  final email = user?.email ?? '';
  return email.isEmpty ? '?' : email[0].toUpperCase();
}

class _Hero extends ConsumerWidget {
  const _Hero({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sync = ref.watch(syncCoordinatorProvider);
    final top = MediaQuery.paddingOf(context).top;
    final name = user?.displayName?.trim();
    final email = user?.email ?? '';

    return Container(
      padding: EdgeInsets.fromLTRB(Space.md, top + Space.md, Space.md, 20),
      decoration: BoxDecoration(
        color: brand.hero,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Space.md,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.settingsTitle,
              style: textTheme.headlineMedium?.copyWith(color: brand.onHero),
            ),
          ),
          MergeSemantics(
            child: Row(
              spacing: Space.sm,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: brand.heroChip,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      profileInitials(user),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      if (name != null && name.isNotEmpty)
                        Text(
                          name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: brand.onHero,
                          ),
                        ),
                      Text(
                        email,
                        style: textTheme.bodySmall?.copyWith(
                          color: brand.onHero.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: '${syncLine(l10n, sync)}. ${l10n.settingsSyncOpen}',
            excludeSemantics: true,
            child: Material(
              color: brand.onHero.withValues(alpha: 0.12),
              borderRadius: Radii.rowAll,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => unawaited(SyncSheet.show(context)),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: minTouchTarget),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: Space.xs,
                    ),
                    child: Row(
                      spacing: 10,
                      children: [
                        Icon(Icons.sync_rounded, size: 18, color: brand.onHero),
                        Expanded(
                          child: Text(
                            syncLine(l10n, sync),
                            style: textTheme.bodySmall?.copyWith(
                              color: brand.onHero,
                              fontWeight: sync.rejected > 0
                                  ? FontWeight.w700
                                  : null,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: brand.onHero,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila "Privacidad y datos": abre la hoja de exportar y borrar cuenta.
class _PrivacyTile extends StatelessWidget {
  const _PrivacyTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: context.lukaColors.card,
      borderRadius: Radii.rowAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(PrivacySheet.show(context)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.md - 2,
            Space.sm,
            Space.sm,
            Space.sm,
          ),
          child: Row(
            spacing: Space.sm,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      l10n.settingsPrivacyTitle,
                      style: textTheme.titleSmall,
                    ),
                    Text(
                      l10n.settingsPrivacySubtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
