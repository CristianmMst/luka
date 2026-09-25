import 'package:finanzia/core/time/colombia_month.dart';
import 'package:finanzia/features/dashboard/domain/monthly_summary.dart';

/// Puerto de lectura del Inicio. Las cifras se calculan en local sobre
/// Drift (F4.6): funciona sin red y reemite cuando cambian los movimientos o
/// las categorías.
// Puerto de un solo método a propósito: se sobrescribe en la composición y
// se dobla con mocktail, igual que los demás repositorios.
// ignore: one_member_abstracts
abstract interface class InsightsRepository {
  /// Resumen de [month] con la comparación contra el mes anterior.
  Stream<MonthlySummary> watchMonth(ColombiaMonth month);
}
