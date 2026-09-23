import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Marcador del detalle de un movimiento; F4.4 construye la pantalla real.
///
/// [id] es el identificador de la transacción, un dato y no un texto de UI,
/// así que se muestra tal cual (como el email en el dashboard).
class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionDetailPlaceholderBody)),
      body: Center(child: Text(id)),
    );
  }
}
