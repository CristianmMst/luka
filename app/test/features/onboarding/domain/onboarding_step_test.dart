import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/onboarding/domain/onboarding_step.dart';

void main() {
  group('onboardingSteps', () {
    test('en Android: Gmail, notificaciones y cuentas', () {
      expect(onboardingSteps(notificationsSupported: true), [
        OnboardingStep.gmail,
        OnboardingStep.notifications,
        OnboardingStep.accounts,
      ]);
    });

    test('sin captura nativa: Gmail y cuentas', () {
      expect(onboardingSteps(notificationsSupported: false), [
        OnboardingStep.gmail,
        OnboardingStep.accounts,
      ]);
    });

    test('en iOS: Gmail, Apple Pay y cuentas', () {
      expect(
        onboardingSteps(notificationsSupported: false, applePaySupported: true),
        [
          OnboardingStep.gmail,
          OnboardingStep.applePay,
          OnboardingStep.accounts,
        ],
      );
    });
  });

  group('firstPendingStep', () {
    OnboardingStep first({
      OnboardingStep from = OnboardingStep.gmail,
      bool gmailActive = false,
      bool notificationsPending = true,
    }) => firstPendingStep(
      from: from,
      gmailActive: gmailActive,
      notificationsPending: notificationsPending,
    );

    test('sin nada resuelto empieza en Gmail', () {
      expect(first(), OnboardingStep.gmail);
    });

    test('con Gmail activo salta a notificaciones', () {
      expect(first(gmailActive: true), OnboardingStep.notifications);
    });

    test('con todo resuelto queda Cuentas, que siempre se muestra', () {
      expect(
        first(gmailActive: true, notificationsPending: false),
        OnboardingStep.accounts,
      );
    });

    test('Gmail pendiente no importa si se parte después de Gmail', () {
      expect(
        first(from: OnboardingStep.notifications, notificationsPending: false),
        OnboardingStep.accounts,
      );
      expect(
        first(from: OnboardingStep.notifications),
        OnboardingStep.notifications,
      );
    });

    test('Apple Pay se muestra si aplica, después de notificaciones', () {
      expect(
        firstPendingStep(
          from: OnboardingStep.gmail,
          gmailActive: true,
          notificationsPending: false,
          applePayPending: true,
        ),
        OnboardingStep.applePay,
      );
      expect(
        first(from: OnboardingStep.applePay),
        OnboardingStep.accounts,
      );
    });

    test('desde Cuentas siempre Cuentas', () {
      expect(first(from: OnboardingStep.accounts), OnboardingStep.accounts);
    });
  });
}
