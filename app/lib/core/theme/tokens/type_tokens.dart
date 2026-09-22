import 'package:flutter/material.dart';

/// Familias empaquetadas en `assets/fonts` (sin descarga en runtime, P4).
abstract final class FontFamilies {
  /// Display: marca, titulares y saldos. Úsese con moderación.
  static const display = 'BricolageGrotesque';

  /// Texto de interfaz.
  static const body = 'Manrope';

  /// Montos: cifras tabulares, alineadas en listas.
  static const mono = 'IBMPlexMono';

  /// Solo para el botón "Continuar con Google" (guía de marca de Google).
  static const googleButton = 'Roboto';
}

/// Escala tipográfica M3 mapeada a las familias de la marca.
TextTheme buildTextTheme(Color onSurface) {
  const display = FontFamilies.display;
  const body = FontFamilies.body;
  return const TextTheme(
    displayLarge: TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 52,
      height: 56 / 52,
      letterSpacing: -1.2,
    ),
    displayMedium: TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 44,
      height: 46 / 44,
      letterSpacing: -1,
    ),
    displaySmall: TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 34,
      height: 36 / 34,
      letterSpacing: -0.8,
    ),
    headlineLarge: TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 32,
      height: 36 / 32,
      letterSpacing: -0.6,
    ),
    headlineMedium: TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 28,
      height: 32 / 28,
    ),
    headlineSmall: TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 24,
      height: 30 / 24,
    ),
    titleLarge: TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w700,
      fontSize: 20,
      height: 26 / 20,
    ),
    titleMedium: TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w700,
      fontSize: 16,
      height: 22 / 16,
    ),
    titleSmall: TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 20 / 14,
    ),
    bodyLarge: TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: 24 / 16,
    ),
    bodyMedium: TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w400,
      fontSize: 15,
      height: 22 / 15,
    ),
    bodySmall: TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w400,
      fontSize: 12,
      height: 18 / 12,
    ),
    labelLarge: TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w700,
      fontSize: 15,
      height: 20 / 15,
    ),
    labelMedium: TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w600,
      fontSize: 13,
      height: 18 / 13,
    ),
    labelSmall: TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w700,
      fontSize: 11,
      height: 16 / 11,
      letterSpacing: 0.8,
    ),
  ).apply(bodyColor: onSurface, displayColor: onSurface);
}

/// Estilo base de montos; el color lo pone quien lo usa (gasto/ingreso).
const amountTextStyle = TextStyle(
  fontFamily: FontFamilies.mono,
  fontWeight: FontWeight.w600,
  fontFeatures: [FontFeature.tabularFigures()],
);
