/// Pasos del onboarding tras el Google Sign-In (spec 008 §2, §3.1), en
/// orden.
enum OnboardingStep {
  /// Conectar Gmail (opcional).
  gmail,

  /// Acceso a notificaciones (solo Android, opcional).
  notifications,

  /// Guía del Atajo de pagos con Apple Pay (solo iOS, opcional).
  applePay,

  /// Cuentas propias (repetible, opcional).
  accounts,
}

/// Los pasos que aplican en esta plataforma: el de notificaciones solo con
/// listener (Android) y el de Apple Pay solo con su cola (iOS).
List<OnboardingStep> onboardingSteps({
  required bool notificationsSupported,
  bool applePaySupported = false,
}) => [
  OnboardingStep.gmail,
  if (notificationsSupported) OnboardingStep.notifications,
  if (applePaySupported) OnboardingStep.applePay,
  OnboardingStep.accounts,
];

/// El primer paso desde [from] (incluido) que falta resolver: se salta
/// Gmail si ya está activo y notificaciones si ya hay acceso o no aplica.
/// Apple Pay se muestra siempre que aplique: no hay forma de saber si el
/// Atajo ya existe. Cuentas siempre se muestra (lista las que haya) y
/// cierra el onboarding.
OnboardingStep firstPendingStep({
  required OnboardingStep from,
  required bool gmailActive,
  required bool notificationsPending,
  bool applePayPending = false,
}) {
  for (final step in OnboardingStep.values.skip(from.index)) {
    final pending = switch (step) {
      OnboardingStep.gmail => !gmailActive,
      OnboardingStep.notifications => notificationsPending,
      OnboardingStep.applePay => applePayPending,
      OnboardingStep.accounts => true,
    };
    if (pending) return step;
  }
  return OnboardingStep.accounts;
}
