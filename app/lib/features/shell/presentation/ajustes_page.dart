import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/color_tokens.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/widgets/settings_group.dart';
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
import 'package:luka/features/recurring/presentation/recurring_settings_tile.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/sync/presentation/sync_sheet.dart';

/// "Ajustes" (diseño AF "Tarjeta de miembro", spec 008 §3.7): fondo blanco,
/// la tarjeta con el perfil, el trazo del logo y la línea de sync (abre la
/// hoja de sincronización), y debajo las filas agrupadas: captura
/// automática, tus datos y privacidad. Al final, cerrar sesión.
class AjustesPage extends ConsumerWidget {
  const AjustesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = switch (ref.watch(authControllerProvider)) {
      AsyncData(value: Authenticated(:final user)) => user,
      _ => null,
    };

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        bottom: false,
        child: ListView(
          // La barra translúcida va encima: su alto entra en el margen.
          padding: EdgeInsets.fromLTRB(
            Space.md,
            18,
            Space.md,
            Space.lg + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.settingsTitle,
                style: textTheme.headlineLarge?.copyWith(
                  fontSize: 34,
                  letterSpacing: -1.2,
                ),
              ),
            ),
            const SizedBox(height: Space.md),
            _MemberCard(user: user),
            const SizedBox(height: 22),
            SettingsGroup(
              title: l10n.settingsGroupCapture,
              children: [
                const GmailSettingsTile(),
                if (ref.watch(notificationCaptureSupportedProvider))
                  const NotificationCaptureTile(),
                if (ref.watch(walletCaptureSupportedProvider))
                  const ApplePaySettingsTile(),
                if (ref.watch(nfcWriteSupportedProvider))
                  const NfcTagsSettingsTile(),
              ],
            ),
            const SizedBox(height: 22),
            SettingsGroup(
              title: l10n.settingsGroupData,
              children: const [
                RecurringSettingsTile(),
                CategoriesSettingsTile(),
                AccountsSettingsTile(),
              ],
            ),
            const SizedBox(height: 22),
            SettingsGroup(
              title: l10n.settingsGroupPrivacy,
              children: const [_PrivacyTile()],
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: () => unawaited(
                ref.read(authControllerProvider.notifier).signOut(),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(l10n.homeSignOut),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
                foregroundColor: scheme.primary,
                side: BorderSide(color: context.lukaColors.hairline),
                textStyle: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
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

/// Tarjeta de miembro (diseño AF): "Tu cuenta luka", nombre, correo y la
/// línea de sync en una píldora, con el trazo del logo cruzándola.
class _MemberCard extends ConsumerWidget {
  const _MemberCard({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sync = ref.watch(syncCoordinatorProvider);
    final name = user?.displayName?.trim();
    final email = user?.email ?? '';
    // Al día en verde; sin red o con cambios rechazados, en ámbar; sin
    // ningún ciclo todavía, neutro.
    final (pillBg, pillFg) = switch (sync) {
      SyncStatus(offline: true) || SyncStatus(rejected: > 0) => (
        brand.warningContainer,
        brand.onWarningContainer,
      ),
      SyncStatus(lastSyncedAt: null) => (
        brand.neutralChip,
        scheme.onSurfaceVariant,
      ),
      _ => (brand.income.withValues(alpha: 0.12), brand.income),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: brand.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x335C1A10),
            blurRadius: 34,
            spreadRadius: -18,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          painter: const _TracePainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsMemberLabel.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (name != null && name.isNotEmpty)
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.headlineMedium?.copyWith(
                            letterSpacing: -0.8,
                          ),
                        ),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                // Ancho tope: el trazo ocupa la esquina derecha.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Semantics(
                    button: true,
                    label: '${syncLine(l10n, sync)}. ${l10n.settingsSyncOpen}',
                    excludeSemantics: true,
                    child: Material(
                      color: pillBg,
                      shape: const StadiumBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => unawaited(SyncSheet.show(context)),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: minTouchTarget,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 6,
                              children: [
                                Icon(
                                  Icons.sync_rounded,
                                  size: 16,
                                  color: pillFg,
                                ),
                                Flexible(
                                  child: Text(
                                    syncLine(l10n, sync),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: pillFg,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

/// El trazo del logo en la esquina de la tarjeta: tomate con su sombra
/// amarilla, anclado abajo a la derecha.
class _TracePainter extends CustomPainter {
  const _TracePainter();

  static final _line = Path()
    ..moveTo(150, 176)
    ..cubicTo(190, 176, 196, 70, 246, 70)
    ..cubicTo(280, 70, 286, 120, 308, 102)
    ..lineTo(346, 60);

  static final _head = Path()
    ..moveTo(310, 52)
    ..lineTo(352, 52)
    ..lineTo(352, 94);

  /// El trazo ocupa la esquina: su caja va de x 150 a 360 y de y 44 a 196.
  static const _box = Rect.fromLTRB(150, 44, 360, 196);
  static const _scale = 0.62;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate(
        size.width - 12 - _box.right * _scale,
        size.height - 10 - _box.bottom * _scale,
      )
      ..scale(_scale);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(
        _line.shift(const Offset(0, 12)),
        stroke..color = brandYellow,
      )
      ..drawPath(_line, stroke..color = const Color(0xFFE23D28))
      ..drawPath(_head, stroke..color = const Color(0xFFE23D28))
      ..restore();
  }

  @override
  bool shouldRepaint(_TracePainter oldDelegate) => false;
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
      color: Colors.transparent,
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
              const ExcludeSemantics(
                child: SettingsIcon(Icons.shield_outlined),
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
