import 'package:finanzia/core/routing/routes.dart';
import 'package:finanzia/features/onboarding/application/onboarding_gate.dart';
import 'package:finanzia/features/onboarding/domain/onboarding_step.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Ruta de cada paso del onboarding.
String onboardingRoute(OnboardingStep step) => switch (step) {
  OnboardingStep.gmail => Routes.onboardingGmail,
  OnboardingStep.notifications => Routes.onboardingNotifications,
  OnboardingStep.applePay => Routes.onboardingApplePay,
  OnboardingStep.accounts => Routes.onboardingAccounts,
};

/// Va al paso que sigue a [current] (saltando los ya resueltos) o, tras el
/// último, termina el onboarding y va a Inicio.
Future<void> advanceOnboarding(
  BuildContext context,
  WidgetRef ref,
  OnboardingStep current,
) async {
  final flow = ref.read(onboardingFlowProvider);
  final next = flow.next(current);
  if (next != null) {
    context.go(onboardingRoute(next));
    return;
  }
  await finishOnboarding(context, ref);
}

/// Guarda que el usuario terminó el onboarding y va a Inicio.
Future<void> finishOnboarding(BuildContext context, WidgetRef ref) async {
  await ref.read(onboardingFlowProvider).finish();
  if (context.mounted) context.go(Routes.home);
}
