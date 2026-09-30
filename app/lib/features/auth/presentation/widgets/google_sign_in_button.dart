import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/theme/tokens/type_tokens.dart';

/// Botón "Continuar con Google" según la guía de marca de Google: variantes
/// clara y oscura, Roboto Medium y la "G" a color sobre su fondo.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;

  /// `null` deshabilita el botón.
  final VoidCallback? onPressed;

  /// Muestra un indicador en lugar de la "G" y bloquea el botón.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? const Color(0xFF131314) : const Color(0xFFFFFFFF);
    final stroke = dark ? const Color(0xFF8E918F) : const Color(0xFF747775);
    final text = dark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F);
    final enabled = onPressed != null && !loading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: fill,
            foregroundColor: text,
            disabledBackgroundColor: fill,
            disabledForegroundColor: text.withValues(alpha: 0.6),
            side: BorderSide(color: stroke),
            shape: const StadiumBorder(),
            minimumSize: const Size.fromHeight(minTouchTarget),
            textStyle: const TextStyle(
              fontFamily: FontFamilies.googleButton,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: Space.sm,
            children: [
              if (loading)
                SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              else
                SvgPicture.asset(
                  'assets/brand/google_g.svg',
                  width: 20,
                  height: 20,
                  excludeFromSemantics: true,
                ),
              Flexible(
                child: Text(label, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
