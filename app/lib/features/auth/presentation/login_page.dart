import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/widgets/brand_mark.dart';
import 'package:luka/core/widgets/inline_notice.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/auth/application/sign_in_controller.dart';
import 'package:luka/features/auth/domain/auth_failure.dart';
import 'package:luka/features/auth/presentation/widgets/capture_trace.dart';
import 'package:luka/features/auth/presentation/widgets/google_sign_in_button.dart';

/// Login "Trazo" (spec 008 §7.1): fondo blanco (el más oscuro de la
/// superficie en tema oscuro), la flecha del logo que se dibuja con tres
/// compras capturadas, titular y botón de Google. La entrada dura ~1,85 s y
/// nunca bloquea el botón.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  static const _wordmarkRed = Color(0xFFAA2E1E);

  /// Segundos que faltan para poder reintentar tras un 429.
  int? _secondsLeft;
  Timer? _countdown;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1850),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Con "reducir movimiento" la pantalla aparece quieta en su estado final.
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (!_entrance.isAnimating && _entrance.value == 0) {
      unawaited(_entrance.forward());
    }
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _entrance.dispose();
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

  Animation<double> _step(double begin, double end) => CurvedAnimation(
    parent: _entrance,
    curve: Interval(begin, end, curve: CaptureTrace.entranceCurve),
  );

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

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dark = scheme.brightness == Brightness.dark;
    const gutter = EdgeInsets.symmetric(horizontal: Space.screen);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: Space.md, bottom: Space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: gutter,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: BrandMark(
                      // Wordmark de marca en claro (spec 008 §7.1).
                      textColor: dark ? scheme.primary : _wordmarkRed,
                    ),
                  ),
                ),
                const SizedBox(height: Space.md),
                // El trazo toma el alto que sobra y se encoge en pantallas
                // bajas o con letra grande: el botón siempre queda a la vista.
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: CaptureTrace(progress: _entrance),
                    ),
                  ),
                ),
                const SizedBox(height: Space.lg),
                _Rise(
                  animation: _step(0.73, 0.99),
                  child: Padding(
                    padding: gutter,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          label: l10n.loginHeadline,
                          excludeSemantics: true,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: l10n.loginHeadlineLead),
                                TextSpan(
                                  text: l10n.loginHeadlineAccent,
                                  style: TextStyle(color: scheme.primary),
                                ),
                              ],
                            ),
                            style: textTheme.displayMedium?.copyWith(
                              color: scheme.onSurface,
                              height: 1,
                              letterSpacing: -1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: Space.sm),
                        Text(
                          l10n.loginBody,
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
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
                                    .read(
                                      signInControllerProvider.notifier,
                                    )
                                    .signIn(),
                        ),
                        const SizedBox(height: Space.sm),
                        const _LegalText(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      return InlineNotice(
        tone: NoticeTone.warning,
        message: l10n.errorRateLimited(_formatCountdown(remaining)),
      );
    }
    return switch (failure) {
      AuthNetworkFailure() => InlineNotice(
        tone: NoticeTone.error,
        icon: Icons.wifi_off_rounded,
        message: l10n.errorNetwork,
      ),
      AuthRateLimited() => InlineNotice(
        tone: NoticeTone.warning,
        message: l10n.errorRateLimitedNoWait,
      ),
      AuthRejected() => InlineNotice(
        tone: NoticeTone.error,
        message: l10n.errorRejected,
      ),
      AuthMisconfigured(:final detail) => InlineNotice(
        tone: NoticeTone.error,
        // En debug se añade la causa técnica para diagnosticar el setup.
        message: kDebugMode
            ? '${l10n.errorMisconfigured}\n($detail)'
            : l10n.errorMisconfigured,
      ),
      AuthUnexpected() || AuthCancelled() => InlineNotice(
        tone: NoticeTone.error,
        message: l10n.errorUnexpected,
      ),
      _ when sessionExpired => InlineNotice(
        tone: NoticeTone.info,
        message: l10n.sessionExpiredNotice,
      ),
      _ => null,
    };
  }

  static String _formatCountdown(int seconds) {
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

/// Sube 12 px mientras aparece.
class _Rise extends AnimatedWidget {
  const _Rise({required Animation<double> animation, required this.child})
    : super(listenable: animation);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    return Opacity(
      opacity: t.clamp(0, 1),
      child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
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
      fontWeight: FontWeight.w700,
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
