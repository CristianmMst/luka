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

/// Modo oscuro "Noche" (D2): azul noche neutro, sin cafés ni vino; el
/// tomate claro para texto e íconos y el de marca para la banda y los
/// botones.
abstract final class DarkTokens {
  static const primary = Color(0xFFFF7A63);
  static const onPrimary = Color(0xFF1A0A07);
  static const primaryContainer = Color(0xFF432827);
  static const onPrimaryContainer = Color(0xFFFFDAD3);
  static const secondary = Color(0xFFB8C2CF);
  static const onSecondary = Color(0xFF1F242C);
  static const secondaryContainer = Color(0xFF262C35);
  static const onSecondaryContainer = Color(0xFFE3E8EF);
  static const tertiary = Color(0xFFFFD27A);
  static const onTertiary = Color(0xFF3F2E00);
  static const tertiaryContainer = Color(0xFF454034);
  static const onTertiaryContainer = Color(0xFFFFE9B8);
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);
  static const surface = Color(0xFF0E1116);
  static const onSurface = Color(0xFFEEF1F5);
  static const onSurfaceVariant = Color(0xFF9AA4B2);

  /// Igual al fondo, como en claro: las tarjetas van en [card].
  static const surfaceContainerLowest = Color(0xFF0E1116);
  static const surfaceContainerLow = Color(0xFF13171D);
  static const surfaceContainer = Color(0xFF171B22);
  static const surfaceContainerHigh = Color(0xFF1F242C);
  static const surfaceContainerHighest = Color(0xFF262C35);
  static const outline = Color(0xFF7A8494);
  static const outlineVariant = Color(0xFF343B46);
  static const inverseSurface = Color(0xFFEEF1F5);
  static const onInverseSurface = Color(0xFF1F242C);
  static const inversePrimary = Color(0xFFC8331F);

  static const expense = Color(0xFFFF8F7A);
  static const onExpense = Color(0xFF1A0A07);
  static const income = Color(0xFF5FD39A);
  static const transfer = Color(0xFF8FB3D9);
  static const warningContainer = Color(0xFF454034);
  static const onWarningContainer = Color(0xFFFFE9B8);

  /// Igual al fondo: como en claro, la cabecera de marca no es una banda.
  static const hero = Color(0xFF0E1116);
  static const onHero = Color(0xFFEEF1F5);

  /// Banda de Inicio en tomate de marca: blanco encima da 4.6:1.
  static const band = Color(0xFFD93A25);
  static const onBand = Color(0xFFFFFFFF);
  static const hairline = Color(0xFF262C35);
  static const neutralChip = Color(0xFF1F242C);
  static const heroCard = Color(0xFF171B22);
  static const heroChip = Color(0xFF432827);
  static const card = Color(0xFF171B22);
  static const tile = Color(0xFF1F242C);
  static const goldContainer = Color(0xFF37352E);
}

/// Amarillo de marca: rellenos y sellos (no texto). Sobre fondos claros el
/// borde del sello va en `tertiary`, porque el amarillo no llega a 3:1.
const brandYellow = Color(0xFFFFD27A);
const onBrandYellow = Color(0xFF5C1A10);

/// Crema de marca: texto sobre fondos oscuros fijos (el chip de la compra
/// deduplicada del login).
const brandCream = Color(0xFFFFF6F0);
