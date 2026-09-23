import 'package:flutter/material.dart';

/// Ícono Material de cada categoría del sistema, por slug
/// (`SYSTEM_CATEGORIES` del backend). Las del usuario usan el genérico.
const _systemIcons = <String, IconData>{
  'sin_categoria': Icons.help_outline_rounded,
  'mercado': Icons.shopping_cart_outlined,
  'restaurantes': Icons.restaurant_rounded,
  'transporte': Icons.directions_bus_outlined,
  'servicios_publicos': Icons.bolt_rounded,
  'arriendo': Icons.home_outlined,
  'compras': Icons.shopping_bag_outlined,
  'entretenimiento': Icons.movie_outlined,
  'salud': Icons.local_pharmacy_outlined,
  'educacion': Icons.school_outlined,
  'impuestos_comisiones': Icons.account_balance_outlined,
  'efectivo': Icons.payments_outlined,
  'medicina_prepagada': Icons.health_and_safety_outlined,
  'credito_vivienda': Icons.real_estate_agent_outlined,
  'pension_voluntaria': Icons.savings_outlined,
  'afc': Icons.account_balance_wallet_outlined,
  'seguridad_social': Icons.medical_services_outlined,
  'donaciones': Icons.volunteer_activism_outlined,
  'nomina': Icons.work_outline_rounded,
  'honorarios': Icons.badge_outlined,
  'rendimientos': Icons.trending_up_rounded,
  'pension_recibida': Icons.elderly_rounded,
  'otros_ingresos': Icons.attach_money_rounded,
  'transferencias': Icons.swap_horiz_rounded,
};

/// Genérico para las categorías propias del usuario y slugs desconocidos.
const IconData genericCategoryIcon = Icons.label_outline_rounded;

/// Ícono de una transferencia, sea cual sea su categoría.
const IconData transferIcon = Icons.swap_horiz_rounded;

IconData categoryIcon(String? slug) =>
    _systemIcons[slug] ?? genericCategoryIcon;
