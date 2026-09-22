import 'package:flutter/widgets.dart';

/// Escala de espaciado de base 4.
abstract final class Space {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const xxxl = 64.0;

  /// Margen lateral estándar de pantalla.
  static const double screen = lg;
}

/// Radios de esquina.
abstract final class Radii {
  static const chip = 8.0;
  static const row = 12.0;
  static const notice = 16.0;
  static const card = 24.0;
  static const hero = 32.0;

  /// Botones y campos en forma de píldora.
  static const pill = 999.0;

  static const chipAll = BorderRadius.all(Radius.circular(chip));
  static const rowAll = BorderRadius.all(Radius.circular(row));
  static const noticeAll = BorderRadius.all(Radius.circular(notice));
  static const cardAll = BorderRadius.all(Radius.circular(card));
  static const pillAll = BorderRadius.all(Radius.circular(pill));
}

/// Área táctil mínima (spec 008 §7: ≥48 dp).
const minTouchTarget = 48.0;
