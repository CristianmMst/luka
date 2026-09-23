import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Marcador de "Registrar"; F4.5 construye el flujo de captura manual.
class RegistrarPage extends StatelessWidget {
  const RegistrarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navRegisterLabel)),
      body: Center(child: Text(l10n.shellComingSoonBody)),
    );
  }
}
