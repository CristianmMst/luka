import 'package:finanzia/features/transactions/domain/transactions_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puerto de lectura de movimientos; se sobrescribe en
/// `lib/app/composition.dart`.
final transactionsRepositoryProvider = Provider<TransactionsRepository>(
  (ref) => throw UnimplementedError(
    'transactionsRepositoryProvider se sobrescribe en la composición',
  ),
);

/// Reloj para las etiquetas "Hoy"/"Ayer" de la lista (los tests lo fijan).
final transactionsClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
