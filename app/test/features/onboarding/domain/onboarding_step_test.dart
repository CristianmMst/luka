import 'package:finanzia/features/onboarding/domain/onboarding_step.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('onboardingSteps', () {
    test('en Android: Gmail, notificaciones y cuentas', () {
      expect(onboardingSteps(notificationsSupported: true), [
        OnboardingStep.gmail,
        OnboardingStep.notifications,
        OnboardingStep.accounts,
      ]);
    });

    test('en iOS no hay paso de notificaciones', () {
      expect(onboardingSteps(notificationsSupported: false), [
        OnboardingStep.gmail,
        OnboardingStep.accounts,
      ]);
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

    test('desde Cuentas siempre Cuentas', () {
      expect(first(from: OnboardingStep.accounts), OnboardingStep.accounts);
    });
  });
}
