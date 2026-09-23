import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Marcador de "Movimientos"; F4.3 construye la lista real (tarjetas por
/// día, spec 008 §7).
class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(appBar: AppBar(title: Text(l10n.navTransactionsLabel)));
  }
}
