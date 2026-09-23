import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Marcador de "Revisión"; F4.6 construye la cola de revisión manual.
class RevisionPage extends StatelessWidget {
  const RevisionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navReviewLabel)),
      body: Center(child: Text(l10n.shellComingSoonBody)),
    );
  }
}
