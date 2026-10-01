import 'dart:ui';

/// Paleta "Rojo tomate" (spec 008 §7.1).
///
/// Cada par texto/fondo cumple WCAG AA (4.5:1) y cada borde 3:1. El tomate
/// puro (`#E23D28`) vive en el logo; en botones y texto va oscurecido
/// ([LightTokens.primary]) para pasar AA con blanco. El amarillo de marca
/// se reserva para el registro confirmado y la relevancia fiscal; nunca va
/// como texto ni como borde sobre fondos claros.
abstract final class LightTokens {
  static const primary = Color(0xFFC8331F);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFFFDAD3);
  static const onPrimaryContainer = Color(0xFF410A02);
  static const secondary = Color(0xFF775650);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFFFE0DA);
  static const onSecondaryContainer = Color(0xFF2C1510);
  static const tertiary = Color(0xFF9A6400);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFFFD27A);
  static const onTertiaryContainer = Color(0xFF3A2600);
  static const error = Color(0xFFB3261E);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD5);
  static const onErrorContainer = Color(0xFF410E0B);
  static const surface = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF2A1210);
  static const onSurfaceVariant = Color(0xFF5C403B);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFFAF7F6);
  static const surfaceContainer = Color(0xFFF5F1F0);
  static const surfaceContainerHigh = Color(0xFFEFEAE8);
  static const surfaceContainerHighest = Color(0xFFE7E1DF);
  static const outline = Color(0xFF8A716B);
  static const outlineVariant = Color(0xFFE2D8D4);
  static const inverseSurface = Color(0xFF3E2C28);
  static const onInverseSurface = Color(0xFFFFEDE8);
  static const inversePrimary = Color(0xFFFFB4A6);

  static const expense = Color(0xFF5C1A10);
  static const onExpense = Color(0xFFFFFFFF);
  static const income = Color(0xFF17774E);
  static const transfer = Color(0xFF45617A);
  static const warningContainer = Color(0xFFFFE9B8);
  static const onWarningContainer = Color(0xFF3A2600);

  /// Cabecera de marca del onboarding, el splash y NFC: blanca en claro
  /// (rediseño sobre blanco), con tinta oscura.
  static const hero = Color(0xFFFFFFFF);
  static const onHero = Color(0xFF2A1210);
  static const band = Color(0xFFC8331F);
  static const onBand = Color(0xFFFFF6F0);
  static const hairline = Color(0xFFECE6E4);
  static const neutralChip = Color(0xFFF2EFEE);
  static const heroCard = Color(0xFFF7F4F3);
  static const heroChip = Color(0xFFFFD27A);
  static const card = Color(0xFFFFFFFF);
  static const tile = Color(0xFFF5F1F0);
  static const goldContainer = Color(0xFFFFF3D6);
}

abstract final class DarkTokens {
  static const primary = Color(0xFFFFB4A6);
  static const onPrimary = Color(0xFF5F1509);
  static const primaryContainer = Color(0xFF8C2415);
  static const onPrimaryContainer = Color(0xFFFFDAD3);
  static const secondary = Color(0xFFE7BDB5);
  static const onSecondary = Color(0xFF442A24);
  static const secondaryContainer = Color(0xFF5D3F3A);
  static const onSecondaryContainer = Color(0xFFFFDAD3);
  static const tertiary = Color(0xFFFFD27A);
  static const onTertiary = Color(0xFF3F2E00);
  static const tertiaryContainer = Color(0xFF5C4300);
  static const onTertiaryContainer = Color(0xFFFFE9B8);
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);
  static const surface = Color(0xFF1C0F0C);
  static const onSurface = Color(0xFFF5DED9);
  static const onSurfaceVariant = Color(0xFFD8C2BD);
  static const surfaceContainerLowest = Color(0xFF150906);
  static const surfaceContainerLow = Color(0xFF24130F);
  static const surfaceContainer = Color(0xFF2B1814);
  static const surfaceContainerHigh = Color(0xFF361F1A);
  static const surfaceContainerHighest = Color(0xFF412923);
  static const outline = Color(0xFFA08C87);
  static const outlineVariant = Color(0xFF534340);
  static const inverseSurface = Color(0xFFF5DED9);
  static const onInverseSurface = Color(0xFF3E2C28);
  static const inversePrimary = Color(0xFFA82A19);

  static const expense = Color(0xFFE8C4B0);
  static const onExpense = Color(0xFF3A0B00);
  static const income = Color(0xFF7BD8A6);
  static const transfer = Color(0xFF9DB8D3);
  static const warningContainer = Color(0xFF5C3D00);
  static const onWarningContainer = Color(0xFFFFE9B8);

  /// Igual al fondo: como en claro, la cabecera de marca no es una banda.
  static const hero = Color(0xFF1C0F0C);
  static const onHero = Color(0xFFFFF6F0);
  static const band = Color(0xFF8C2415);
  static const onBand = Color(0xFFFFF6F0);
  static const hairline = Color(0xFF3A2824);
  static const neutralChip = Color(0xFF2E201D);
  static const heroCard = Color(0xFF2B1814);
  static const heroChip = Color(0xFF5C1A10);
  static const card = Color(0xFF2B1814);
  static const tile = Color(0xFF361F1A);
  static const goldContainer = Color(0xFF2E2410);
}

/// Amarillo de marca: rellenos y sellos (no texto). Sobre fondos claros el
/// borde del sello va en `tertiary`, porque el amarillo no llega a 3:1.
const brandYellow = Color(0xFFFFD27A);
const onBrandYellow = Color(0xFF5C1A10);

/// Crema de marca: texto sobre fondos oscuros fijos (el chip de la compra
/// deduplicada del login).
const brandCream = Color(0xFFFFF6F0);
