/// Pasos del onboarding tras el Google Sign-In (spec 008 §2, §3.1), en
/// orden.
enum OnboardingStep {
  /// Conectar Gmail (opcional).
  gmail,

  /// Acceso a notificaciones (solo Android, opcional).
  notifications,

  /// Cuentas propias (repetible, opcional).
  accounts,
}

/// Los pasos que aplican en esta plataforma: sin listener de
/// notificaciones (iOS) no hay paso de notificaciones.
List<OnboardingStep> onboardingSteps({
  required bool notificationsSupported,
}) => [
  OnboardingStep.gmail,
  if (notificationsSupported) OnboardingStep.notifications,
  OnboardingStep.accounts,
];

/// El primer paso desde [from] (incluido) que falta resolver: se salta
/// Gmail si ya está activo y notificaciones si ya hay acceso o no aplica.
/// Cuentas siempre se muestra (lista las que haya) y cierra el onboarding.
OnboardingStep firstPendingStep({
  required OnboardingStep from,
  required bool gmailActive,
  required bool notificationsPending,
}) {
  for (final step in OnboardingStep.values.skip(from.index)) {
    final pending = switch (step) {
      OnboardingStep.gmail => !gmailActive,
      OnboardingStep.notifications => notificationsPending,
      OnboardingStep.accounts => true,
    };
    if (pending) return step;
  }
  return OnboardingStep.accounts;
}
