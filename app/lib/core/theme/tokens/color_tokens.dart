import 'dart:ui';

/// Paleta "Esmeralda andina" (spec 008 §7.1).
///
/// Cada par texto/fondo cumple WCAG AA (4.5:1). El oro se reserva para el
/// registro confirmado y la relevancia fiscal; nunca va como texto pequeño
/// sobre fondos claros.
abstract final class LightTokens {
  static const primary = Color(0xFF0E4D3F);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFCDE8DC);
  static const onPrimaryContainer = Color(0xFF06291F);
  static const secondary = Color(0xFF3F4F48);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFD9E5DE);
  static const onSecondaryContainer = Color(0xFF14231D);
  static const tertiary = Color(0xFF8A6A00);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFC9A227);
  static const onTertiaryContainer = Color(0xFF2A2000);
  static const error = Color(0xFFB3261E);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD5);
  static const onErrorContainer = Color(0xFF410E0B);
  static const surface = Color(0xFFEEF5F1);
  static const onSurface = Color(0xFF10201B);
  static const onSurfaceVariant = Color(0xFF3F4F48);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF6FBF8);
  static const surfaceContainer = Color(0xFFE3EDE7);
  static const surfaceContainerHigh = Color(0xFFD9E5DE);
  static const surfaceContainerHighest = Color(0xFFCFDCD5);
  static const outline = Color(0xFF6F7F78);
  static const outlineVariant = Color(0xFFBFCBC4);
  static const inverseSurface = Color(0xFF25332D);
  static const onInverseSurface = Color(0xFFEEF5F1);
  static const inversePrimary = Color(0xFF7FD1B4);

  static const expense = Color(0xFFB4432B);
  static const onExpense = Color(0xFFFFFFFF);
  static const income = Color(0xFF17774E);
  static const transfer = Color(0xFF45617A);
  static const warningContainer = Color(0xFFFFE9B8);
  static const onWarningContainer = Color(0xFF3A2600);
  static const hero = Color(0xFF0E4D3F);
  static const onHero = Color(0xFFEEF5F1);
  static const heroCard = Color(0xFFF6FBF8);
  static const heroChip = Color(0xFFCDE8DC);
}

abstract final class DarkTokens {
  static const primary = Color(0xFF7FD1B4);
  static const onPrimary = Color(0xFF00382B);
  static const primaryContainer = Color(0xFF0E4D3F);
  static const onPrimaryContainer = Color(0xFFBFEBD8);
  static const secondary = Color(0xFFA9B8B1);
  static const onSecondary = Color(0xFF14231D);
  static const secondaryContainer = Color(0xFF2A3833);
  static const onSecondaryContainer = Color(0xFFD9E5DE);
  static const tertiary = Color(0xFFE6C65C);
  static const onTertiary = Color(0xFF3A2E00);
  static const tertiaryContainer = Color(0xFFC9A227);
  static const onTertiaryContainer = Color(0xFF2A2000);
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);
  static const surface = Color(0xFF0C1512);
  static const onSurface = Color(0xFFDCE7E1);
  static const onSurfaceVariant = Color(0xFFA9B8B1);
  static const surfaceContainerLowest = Color(0xFF08100D);
  static const surfaceContainerLow = Color(0xFF121D19);
  static const surfaceContainer = Color(0xFF17231F);
  static const surfaceContainerHigh = Color(0xFF1E2B26);
  static const surfaceContainerHighest = Color(0xFF263530);
  static const outline = Color(0xFF7A8A83);
  static const outlineVariant = Color(0xFF34433D);
  static const inverseSurface = Color(0xFFDCE7E1);
  static const onInverseSurface = Color(0xFF25332D);
  static const inversePrimary = Color(0xFF0E4D3F);

  static const expense = Color(0xFFFF9A80);
  static const onExpense = Color(0xFF3A0B00);
  static const income = Color(0xFF7BD8A6);
  static const transfer = Color(0xFF9DB8D3);
  static const warningContainer = Color(0xFF5C3D00);
  static const onWarningContainer = Color(0xFFFFE9B8);
  static const hero = Color(0xFF0E3D32);
  static const onHero = Color(0xFFEEF5F1);
  static const heroCard = Color(0xFF17231F);
  static const heroChip = Color(0xFF0E4D3F);
}

/// Oro de marca: rellenos, bordes y sellos (no texto pequeño).
const brandGold = Color(0xFFC9A227);
const onBrandGold = Color(0xFF2A2000);
