import 'package:finanzia/features/dashboard/domain/insights_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puerto del resumen mensual; se sobrescribe en `lib/app/composition.dart`.
final insightsRepositoryProvider = Provider<InsightsRepository>(
  (ref) => throw UnimplementedError(
    'insightsRepositoryProvider se sobrescribe en la composición',
  ),
);

/// Reloj para el mes en curso del Inicio (los tests lo fijan).
final dashboardClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
