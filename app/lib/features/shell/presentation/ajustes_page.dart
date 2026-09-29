import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/features/accounts/presentation/accounts_settings_tile.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/capture/presentation/widgets/notification_capture_tile.dart';
import 'package:finanzia/features/categories/presentation/categories_settings_tile.dart';
import 'package:finanzia/features/gmail/presentation/widgets/gmail_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Ajustes": por ahora la conexión de Gmail (F3.6), el acceso a
/// notificaciones en Android (F4.3), "Mis categorías" (F4.8a), "Mis cuentas"
/// (F4.4) y el cierre de sesión que antes vivía en el dashboard (F4.2). El
/// resto llega en F4.8b.
class AjustesPage extends ConsumerWidget {
  const AjustesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettingsLabel)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GmailSettingsTile(),
              const SizedBox(height: Space.sm),
              const NotificationCaptureTile(),
              const SizedBox(height: Space.sm),
              const CategoriesSettingsTile(),
              const SizedBox(height: Space.sm),
              const AccountsSettingsTile(),
              const SizedBox(height: Space.lg),
              Text(
                l10n.shellComingSoonBody,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                child: Text(l10n.homeSignOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
