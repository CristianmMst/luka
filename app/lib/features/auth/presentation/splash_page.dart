import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/finanzia_colors.dart';
import 'package:finanzia/core/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Session gate: se muestra mientras se restaura la sesión guardada.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = context.finanziaColors;
    final label = AppLocalizations.of(context).splashRestoring;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: brand.hero,
        body: Stack(
          children: [
            Center(
              child: BrandMark(
                gemColor: const Color(0xFF1F6B55),
                textColor: brand.onHero,
                size: 36,
                direction: Axis.vertical,
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.78),
              child: SizedBox(
                width: 96,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: brand.gold,
                    backgroundColor: const Color(0xFF1F6B55),
                    semanticsLabel: label,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
