import 'package:flutter/material.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/color_tokens.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/theme/tokens/type_tokens.dart';

/// Temas claro y oscuro de la app (Material 3, spec 008 §7).
///
/// El `ColorScheme` es explícito y no usa `fromSeed`, para que los tonos
/// sean exactamente los verificados en el sistema de diseño.
abstract final class AppTheme {
  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: LightTokens.primary,
    onPrimary: LightTokens.onPrimary,
    primaryContainer: LightTokens.primaryContainer,
    onPrimaryContainer: LightTokens.onPrimaryContainer,
    secondary: LightTokens.secondary,
    onSecondary: LightTokens.onSecondary,
    secondaryContainer: LightTokens.secondaryContainer,
    onSecondaryContainer: LightTokens.onSecondaryContainer,
    tertiary: LightTokens.tertiary,
    onTertiary: LightTokens.onTertiary,
    tertiaryContainer: LightTokens.tertiaryContainer,
    onTertiaryContainer: LightTokens.onTertiaryContainer,
    error: LightTokens.error,
    onError: LightTokens.onError,
    errorContainer: LightTokens.errorContainer,
    onErrorContainer: LightTokens.onErrorContainer,
    surface: LightTokens.surface,
    onSurface: LightTokens.onSurface,
    onSurfaceVariant: LightTokens.onSurfaceVariant,
    surfaceContainerLowest: LightTokens.surfaceContainerLowest,
    surfaceContainerLow: LightTokens.surfaceContainerLow,
    surfaceContainer: LightTokens.surfaceContainer,
    surfaceContainerHigh: LightTokens.surfaceContainerHigh,
    surfaceContainerHighest: LightTokens.surfaceContainerHighest,
    outline: LightTokens.outline,
    outlineVariant: LightTokens.outlineVariant,
    inverseSurface: LightTokens.inverseSurface,
    onInverseSurface: LightTokens.onInverseSurface,
    inversePrimary: LightTokens.inversePrimary,
  );

  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: DarkTokens.primary,
    onPrimary: DarkTokens.onPrimary,
    primaryContainer: DarkTokens.primaryContainer,
    onPrimaryContainer: DarkTokens.onPrimaryContainer,
    secondary: DarkTokens.secondary,
    onSecondary: DarkTokens.onSecondary,
    secondaryContainer: DarkTokens.secondaryContainer,
    onSecondaryContainer: DarkTokens.onSecondaryContainer,
    tertiary: DarkTokens.tertiary,
    onTertiary: DarkTokens.onTertiary,
    tertiaryContainer: DarkTokens.tertiaryContainer,
    onTertiaryContainer: DarkTokens.onTertiaryContainer,
    error: DarkTokens.error,
    onError: DarkTokens.onError,
    errorContainer: DarkTokens.errorContainer,
    onErrorContainer: DarkTokens.onErrorContainer,
    surface: DarkTokens.surface,
    onSurface: DarkTokens.onSurface,
    onSurfaceVariant: DarkTokens.onSurfaceVariant,
    surfaceContainerLowest: DarkTokens.surfaceContainerLowest,
    surfaceContainerLow: DarkTokens.surfaceContainerLow,
    surfaceContainer: DarkTokens.surfaceContainer,
    surfaceContainerHigh: DarkTokens.surfaceContainerHigh,
    surfaceContainerHighest: DarkTokens.surfaceContainerHighest,
    outline: DarkTokens.outline,
    outlineVariant: DarkTokens.outlineVariant,
    inverseSurface: DarkTokens.inverseSurface,
    onInverseSurface: DarkTokens.onInverseSurface,
    inversePrimary: DarkTokens.inversePrimary,
  );

  static ThemeData get light => _build(lightScheme, LukaColors.light);

  static ThemeData get dark => _build(darkScheme, LukaColors.dark);

  static ThemeData _build(ColorScheme scheme, LukaColors brand) {
    final textTheme = buildTextTheme(scheme.onSurface);
    const pillShape = StadiumBorder();
    const buttonSize = Size(64, minTouchTarget);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: FontFamilies.body,
      textTheme: textTheme,
      extensions: [brand],
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: pillShape,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: pillShape,
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonSize,
          shape: pillShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: Radii.chipAll),
        side: BorderSide(color: scheme.outline),
        labelStyle: textTheme.titleSmall,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(borderRadius: Radii.cardAll),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: const RoundedRectangleBorder(borderRadius: Radii.rowAll),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
