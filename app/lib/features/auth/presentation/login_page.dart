import 'dart:async';

import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/finanzia_colors.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/core/widgets/brand_mark.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/application/sign_in_controller.dart';
import 'package:finanzia/features/auth/domain/auth_failure.dart';
import 'package:finanzia/features/auth/presentation/widgets/auth_notice.dart';
import 'package:finanzia/features/auth/presentation/widgets/capture_ticker.dart';
import 'package:finanzia/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Login "Veta esmeralda": bloque hero con el ticker de captura, titular y
/// botón de Google (canvas de diseño, spec 008 §7.1).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  /// Segundos que faltan para poder reintentar tras un 429.
  int? _secondsLeft;
  Timer? _countdown;

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _startCountdown(Duration wait) {
    _countdown?.cancel();
    final seconds = (wait.inMilliseconds / 1000).ceil();
    if (seconds <= 0) return;
    setState(() => _secondsLeft = seconds);
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      final left = (_secondsLeft ?? 1) - 1;
      if (left <= 0) timer.cancel();
      setState(() => _secondsLeft = left <= 0 ? null : left);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(signInControllerProvider, (_, next) {
      if (next case AsyncError(error: AuthRateLimited(:final retryAfter?))) {
        _startCountdown(retryAfter);
      }
    });

    final l10n = AppLocalizations.of(context);
    final signIn = ref.watch(signInControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final brand = context.finanziaColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final remaining = _secondsLeft;
    final notice = _noticeFor(
      l10n,
      failure: signIn.error,
      remaining: remaining,
      sessionExpired: switch (auth) {
        AsyncData(value: Unauthenticated(:final sessionExpired)) =>
          sessionExpired,
        _ => false,
      },
    );
    final isNetworkError = signIn.error is AuthNetworkFailure;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // El hero es oscuro en ambos temas: íconos de estado claros.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Hero(color: brand.hero, onColor: brand.onHero),
                  Expanded(
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Space.screen,
                          Space.xl - 4,
                          Space.screen,
                          Space.screen,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                l10n.loginHeadline,
                                style: textTheme.displaySmall,
                              ),
                            ),
                            const SizedBox(height: Space.sm),
                            Text(
                              l10n.loginBody,
                              style: textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: Space.lg),
                            if (notice != null) ...[
                              notice,
                              const SizedBox(height: Space.sm),
                            ],
                            GoogleSignInButton(
                              label: signIn.isLoading
                                  ? l10n.loginConnecting
                                  : isNetworkError
                                  ? l10n.loginRetryWithGoogle
                                  : l10n.loginContinueWithGoogle,
                              loading: signIn.isLoading,
                              onPressed: remaining != null
                                  ? null
                                  : () => ref
                                        .read(signInControllerProvider.notifier)
                                        .signIn(),
                            ),
                            const SizedBox(height: Space.sm),
                            const _LegalText(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _noticeFor(
    AppLocalizations l10n, {
    required Object? failure,
    required int? remaining,
    required bool sessionExpired,
  }) {
    if (remaining != null) {
      return AuthNotice(
        tone: AuthNoticeTone.warning,
        message: l10n.errorRateLimited(_formatCountdown(remaining)),
      );
    }
    return switch (failure) {
      AuthNetworkFailure() => AuthNotice(
        tone: AuthNoticeTone.error,
        icon: Icons.wifi_off_rounded,
        message: l10n.errorNetwork,
      ),
      AuthRateLimited() => AuthNotice(
        tone: AuthNoticeTone.warning,
        message: l10n.errorRateLimitedNoWait,
      ),
      AuthRejected() => AuthNotice(
        tone: AuthNoticeTone.error,
        message: l10n.errorRejected,
      ),
      AuthMisconfigured(:final detail) => AuthNotice(
        tone: AuthNoticeTone.error,
        // En debug se añade la causa técnica para diagnosticar el setup.
        message: kDebugMode
            ? '${l10n.errorMisconfigured}\n($detail)'
            : l10n.errorMisconfigured,
      ),
      AuthUnexpected() || AuthCancelled() => AuthNotice(
        tone: AuthNoticeTone.error,
        message: l10n.errorUnexpected,
      ),
      _ when sessionExpired => AuthNotice(
        tone: AuthNoticeTone.info,
        message: l10n.sessionExpiredNotice,
      ),
      _ => null,
    };
  }

  static String _formatCountdown(int seconds) {
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.color, required this.onColor});

  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(Radii.hero),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.md,
            Space.screen,
            Space.xl - 4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Space.xl - 4,
            children: [
              BrandMark(gemColor: const Color(0xFF1F6B55), textColor: onColor),
              const CaptureTicker(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalText extends StatelessWidget {
  const _LegalText();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final base = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final strong = base?.copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.w600,
    );

    // TODO(F6): enlazar Términos y Política cuando existan sus URLs públicas.
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: l10n.loginLegalPrefix),
          TextSpan(text: l10n.loginLegalTerms, style: strong),
          TextSpan(text: l10n.loginLegalJoin),
          TextSpan(text: l10n.loginLegalPrivacy, style: strong),
          TextSpan(text: l10n.loginLegalSuffix),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
