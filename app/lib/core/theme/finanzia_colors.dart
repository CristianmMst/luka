import 'package:finanzia/core/theme/tokens/color_tokens.dart';
import 'package:flutter/material.dart';

/// Colores semánticos que Material 3 no modela: montos, avisos y el bloque
/// hero de la marca.
@immutable
class FinanziaColors extends ThemeExtension<FinanziaColors> {
  const FinanziaColors({
    required this.expense,
    required this.income,
    required this.transfer,
    required this.gold,
    required this.onGold,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.hero,
    required this.onHero,
    required this.heroCard,
    required this.heroChip,
  });

  static const light = FinanziaColors(
    expense: LightTokens.expense,
    income: LightTokens.income,
    transfer: LightTokens.transfer,
    gold: brandGold,
    onGold: onBrandGold,
    warningContainer: LightTokens.warningContainer,
    onWarningContainer: LightTokens.onWarningContainer,
    hero: LightTokens.hero,
    onHero: LightTokens.onHero,
    heroCard: LightTokens.heroCard,
    heroChip: LightTokens.heroChip,
  );

  static const dark = FinanziaColors(
    expense: DarkTokens.expense,
    income: DarkTokens.income,
    transfer: DarkTokens.transfer,
    gold: brandGold,
    onGold: onBrandGold,
    warningContainer: DarkTokens.warningContainer,
    onWarningContainer: DarkTokens.onWarningContainer,
    hero: DarkTokens.hero,
    onHero: DarkTokens.onHero,
    heroCard: DarkTokens.heroCard,
    heroChip: DarkTokens.heroChip,
  );

  final Color expense;
  final Color income;
  final Color transfer;
  final Color gold;
  final Color onGold;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color hero;
  final Color onHero;
  final Color heroCard;
  final Color heroChip;

  @override
  FinanziaColors copyWith({
    Color? expense,
    Color? income,
    Color? transfer,
    Color? gold,
    Color? onGold,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? hero,
    Color? onHero,
    Color? heroCard,
    Color? heroChip,
  }) {
    return FinanziaColors(
      expense: expense ?? this.expense,
      income: income ?? this.income,
      transfer: transfer ?? this.transfer,
      gold: gold ?? this.gold,
      onGold: onGold ?? this.onGold,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      hero: hero ?? this.hero,
      onHero: onHero ?? this.onHero,
      heroCard: heroCard ?? this.heroCard,
      heroChip: heroChip ?? this.heroChip,
    );
  }

  @override
  FinanziaColors lerp(FinanziaColors? other, double t) {
    if (other == null) return this;
    return FinanziaColors(
      expense: Color.lerp(expense, other.expense, t)!,
      income: Color.lerp(income, other.income, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
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
    );
  }
}

extension FinanziaThemeX on BuildContext {
  FinanziaColors get finanziaColors =>
      Theme.of(this).extension<FinanziaColors>() ?? FinanziaColors.light;
}
