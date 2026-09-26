import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/features/categories/domain/category_catalog.dart';
import 'package:flutter/material.dart';

/// Ícono Material de cada clave de `categoryIconKeys`.
const _icons = <String, IconData>{
  'label': Icons.label_outline_rounded,
  'pets': Icons.pets_rounded,
  'cart': Icons.shopping_cart_outlined,
  'home': Icons.home_outlined,
  'health': Icons.favorite_border_rounded,
  'car': Icons.directions_car_outlined,
  'coffee': Icons.local_cafe_outlined,
  'book': Icons.menu_book_outlined,
  'gift': Icons.card_giftcard_rounded,
  'flight': Icons.flight_rounded,
  'phone': Icons.smartphone_rounded,
  'bolt': Icons.bolt_rounded,
  'music': Icons.music_note_rounded,
  'fitness': Icons.fitness_center_rounded,
  'clothes': Icons.checkroom_rounded,
  'school': Icons.school_outlined,
};

/// Ícono de una categoría propia; el genérico si la clave no se conoce.
IconData ownCategoryIcon(String? key) =>
    _icons[key] ?? Icons.label_outline_rounded;

/// Color `#RRGGBB` de una categoría propia; el primero del catálogo si no
/// se entiende.
Color ownCategoryColor(String? hex) {
  final value = int.tryParse(
    (categoryColors.contains(hex) ? hex! : categoryColors.first).substring(1),
    radix: 16,
  );
  return Color(0xFF000000 | value!);
}

String categoryIconName(AppLocalizations l10n, String key) => switch (key) {
  'pets' => l10n.categoryIconPets,
  'cart' => l10n.categoryIconCart,
  'home' => l10n.categoryIconHome,
  'health' => l10n.categoryIconHealth,
  'car' => l10n.categoryIconCar,
  'coffee' => l10n.categoryIconCoffee,
  'book' => l10n.categoryIconBook,
  'gift' => l10n.categoryIconGift,
  'flight' => l10n.categoryIconFlight,
  'phone' => l10n.categoryIconPhone,
  'bolt' => l10n.categoryIconBolt,
  'music' => l10n.categoryIconMusic,
  'fitness' => l10n.categoryIconFitness,
  'clothes' => l10n.categoryIconClothes,
  'school' => l10n.categoryIconSchool,
  _ => l10n.categoryIconLabel,
};

String categoryColorName(AppLocalizations l10n, String hex) =>
    switch (categoryColors.indexOf(hex)) {
      1 => l10n.categoryColorGreen,
      2 => l10n.categoryColorSlate,
      3 => l10n.categoryColorTerracotta,
      4 => l10n.categoryColorOchre,
      5 => l10n.categoryColorPurple,
      6 => l10n.categoryColorRose,
      7 => l10n.categoryColorGraphite,
      _ => l10n.categoryColorEmerald,
    };

String fiscalGroupName(AppLocalizations l10n, FiscalGroup group) =>
    switch (group) {
      FiscalGroup.expenses => l10n.fiscalGroupExpenses,
      FiscalGroup.contributions => l10n.fiscalGroupContributions,
      FiscalGroup.income => l10n.fiscalGroupIncome,
    };

/// Nombre en lenguaje claro de una etiqueta fiscal (spec 007 §2).
String fiscalTagName(AppLocalizations l10n, String tag) => switch (tag) {
  'deducible_salud' => l10n.fiscalDeducibleSalud,
  'deducible_vivienda' => l10n.fiscalDeducibleVivienda,
  'donacion' => l10n.fiscalDonacion,
  'aporte_pension_voluntaria' => l10n.fiscalAportePensionVoluntaria,
  'aporte_afc' => l10n.fiscalAporteAfc,
  'aporte_obligatorio' => l10n.fiscalAporteObligatorio,
  'ingreso_laboral' => l10n.fiscalIngresoLaboral,
  'ingreso_honorarios' => l10n.fiscalIngresoHonorarios,
  'ingreso_capital' => l10n.fiscalIngresoCapital,
  'ingreso_pension' => l10n.fiscalIngresoPension,
  'ingreso_no_laboral' => l10n.fiscalIngresoNoLaboral,
  _ => l10n.fiscalNoDeducible,
};

String fiscalTagHint(AppLocalizations l10n, String tag) => switch (tag) {
  'deducible_salud' => l10n.fiscalDeducibleSaludHint,
  'deducible_vivienda' => l10n.fiscalDeducibleViviendaHint,
  'donacion' => l10n.fiscalDonacionHint,
  'aporte_pension_voluntaria' => l10n.fiscalAportePensionVoluntariaHint,
  'aporte_afc' => l10n.fiscalAporteAfcHint,
  'aporte_obligatorio' => l10n.fiscalAporteObligatorioHint,
  'ingreso_laboral' => l10n.fiscalIngresoLaboralHint,
  'ingreso_honorarios' => l10n.fiscalIngresoHonorariosHint,
  'ingreso_capital' => l10n.fiscalIngresoCapitalHint,
  'ingreso_pension' => l10n.fiscalIngresoPensionHint,
  'ingreso_no_laboral' => l10n.fiscalIngresoNoLaboralHint,
  _ => l10n.fiscalNoDeducibleHint,
};

/// Círculo de color con el ícono blanco de una categoría propia.
class OwnCategoryAvatar extends StatelessWidget {
  const OwnCategoryAvatar({
    required this.icon,
    required this.color,
    this.size = 40,
    super.key,
  });

  final String? icon;
  final String? color;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ownCategoryColor(color),
        shape: BoxShape.circle,
      ),
      child: Icon(ownCategoryIcon(icon), size: size / 2, color: Colors.white),
    ),
  );
}
