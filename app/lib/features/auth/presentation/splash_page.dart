import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/widgets/brand_mark.dart';

/// Session gate: se muestra mientras se restaura la sesión guardada.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = context.lukaColors;
    final label = AppLocalizations.of(context).splashRestoring;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: brand.hero,
        body: Stack(
          children: [
            Center(
              child: BrandMark(
                onDark: true,
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
                    backgroundColor: brand.onHero.withValues(alpha: 0.2),
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
