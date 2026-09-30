import 'package:flutter/material.dart';
import 'package:luka/core/theme/tokens/color_tokens.dart';

/// Colores semánticos que Material 3 no modela: montos, avisos y el bloque
/// hero de la marca.
@immutable
class LukaColors extends ThemeExtension<LukaColors> {
  const LukaColors({
    required this.expense,
    required this.onExpense,
    required this.income,
    required this.transfer,
    required this.gold,
    required this.onGold,
    required this.goldContainer,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.hero,
    required this.onHero,
    required this.heroCard,
    required this.heroChip,
    required this.card,
    required this.tile,
  });

  static const light = LukaColors(
    expense: LightTokens.expense,
    onExpense: LightTokens.onExpense,
    income: LightTokens.income,
    transfer: LightTokens.transfer,
    gold: brandYellow,
    onGold: onBrandYellow,
    goldContainer: LightTokens.goldContainer,
    warningContainer: LightTokens.warningContainer,
    onWarningContainer: LightTokens.onWarningContainer,
    hero: LightTokens.hero,
    onHero: LightTokens.onHero,
    heroCard: LightTokens.heroCard,
    heroChip: LightTokens.heroChip,
    card: LightTokens.card,
    tile: LightTokens.tile,
  );

  static const dark = LukaColors(
    expense: DarkTokens.expense,
    onExpense: DarkTokens.onExpense,
    income: DarkTokens.income,
    transfer: DarkTokens.transfer,
    gold: brandYellow,
    onGold: onBrandYellow,
    goldContainer: DarkTokens.goldContainer,
    warningContainer: DarkTokens.warningContainer,
    onWarningContainer: DarkTokens.onWarningContainer,
    hero: DarkTokens.hero,
    onHero: DarkTokens.onHero,
    heroCard: DarkTokens.heroCard,
    heroChip: DarkTokens.heroChip,
    card: DarkTokens.card,
    tile: DarkTokens.tile,
  );

  final Color expense;
  final Color onExpense;
  final Color income;
  final Color transfer;

  /// Amarillo de marca (spec 008 §7.1): relleno del sello y acentos.
  final Color gold;
  final Color onGold;

  /// Fondo del sello amarillo "1 registro" (con borde `tertiary`).
  final Color goldContainer;

  final Color warningContainer;
  final Color onWarningContainer;
  final Color hero;
  final Color onHero;
  final Color heroCard;
  final Color heroChip;

  /// Tarjetas de la lista (por día) y hojas modales.
  final Color card;

  /// Opciones en rejilla dentro de una hoja (p. ej. las categorías).
  final Color tile;

  @override
  LukaColors copyWith({
    Color? expense,
    Color? onExpense,
    Color? income,
    Color? transfer,
    Color? gold,
    Color? onGold,
    Color? goldContainer,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? hero,
    Color? onHero,
    Color? heroCard,
    Color? heroChip,
    Color? card,
    Color? tile,
  }) {
    return LukaColors(
      expense: expense ?? this.expense,
      onExpense: onExpense ?? this.onExpense,
      income: income ?? this.income,
      transfer: transfer ?? this.transfer,
      gold: gold ?? this.gold,
      onGold: onGold ?? this.onGold,
      goldContainer: goldContainer ?? this.goldContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      hero: hero ?? this.hero,
      onHero: onHero ?? this.onHero,
      heroCard: heroCard ?? this.heroCard,
      heroChip: heroChip ?? this.heroChip,
      card: card ?? this.card,
      tile: tile ?? this.tile,
    );
  }

  @override
  LukaColors lerp(LukaColors? other, double t) {
    if (other == null) return this;
    return LukaColors(
      expense: Color.lerp(expense, other.expense, t)!,
      onExpense: Color.lerp(onExpense, other.onExpense, t)!,
      income: Color.lerp(income, other.income, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
      goldContainer: Color.lerp(goldContainer, other.goldContainer, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      hero: Color.lerp(hero, other.hero, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      heroCard: Color.lerp(heroCard, other.heroCard, t)!,
      heroChip: Color.lerp(heroChip, other.heroChip, t)!,
      card: Color.lerp(card, other.card, t)!,
      tile: Color.lerp(tile, other.tile, t)!,
    );
  }
}

extension LukaThemeX on BuildContext {
  LukaColors get lukaColors =>
      Theme.of(this).extension<LukaColors>() ?? LukaColors.light;
}
