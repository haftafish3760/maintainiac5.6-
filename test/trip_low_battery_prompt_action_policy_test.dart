import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_low_battery_prompt_action_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_policy.dart';

void main() {
  test('continue GPS requires explicit prompt choice and enables override', () {
    final decision = TripLowBatteryPromptActionPolicy.evaluate(
      currentDecision: promptDecision(),
      action: TripLowBatteryPromptAction.continueGps,
    );

    expect(decision.status, TripLowBatteryPromptActionStatus.allowed);
    expect(decision.allowsGps, isTrue);
    expect(decision.nextOverrideEnabled, isTrue);
    expect(decision.nextWarningDismissed, isFalse);
  });

  test('cancel GPS pauses GPS without disabling future prompts', () {
    final decision = TripLowBatteryPromptActionPolicy.evaluate(
      currentDecision: promptDecision(),
      action: TripLowBatteryPromptAction.cancelGps,
    );
    final safe = decision.toSafeSummary();

    expect(decision.allowsGps, isFalse);
    expect(decision.nextOverrideEnabled, isFalse);
    expect(decision.nextWarningDismissed, isFalse);
    expect(safe['lowBatteryCanStopTextTripLog'], isFalse);
  });

  test('do not show again is reversible from dashboard settings', () {
    final continueRemember = TripLowBatteryPromptActionPolicy.evaluate(
      currentDecision: promptDecision(),
      action: TripLowBatteryPromptAction.continueGpsDoNotShowAgain,
    );
    final cancelRemember = TripLowBatteryPromptActionPolicy.evaluate(
      currentDecision: promptDecision(),
      action: TripLowBatteryPromptAction.cancelGpsDoNotShowAgain,
    );
    final restore = TripLowBatteryPromptActionPolicy.evaluate(
      currentDecision: blockedDecision(),
      action: TripLowBatteryPromptAction.restorePromptInSettings,
    );

    expect(continueRemember.nextWarningDismissed, isTrue);
    expect(continueRemember.nextOverrideEnabled, isTrue);
    expect(cancelRemember.nextWarningDismissed, isTrue);
    expect(cancelRemember.nextOverrideEnabled, isFalse);
    expect(restore.nextWarningDismissed, isFalse);
    expect(restore.nextOverrideEnabled, isFalse);
    expect(restore.settingsReversalAvailable, isTrue);
  });

  test('actions are blocked when there is no active low battery prompt', () {
    final decision = TripLowBatteryPromptActionPolicy.evaluate(
      currentDecision: allowedDecision(),
      action: TripLowBatteryPromptAction.continueGps,
    );

    expect(decision.status, TripLowBatteryPromptActionStatus.blocked);
    expect(decision.reasonCode, 'active_battery_prompt_required');
    expect(decision.allowsGps, isFalse);
  });

  test(
    'safe summary never grants remote authority or logs battery details',
    () {
      final safe = TripLowBatteryPromptActionPolicy.evaluate(
        currentDecision: promptDecision(),
        action: TripLowBatteryPromptAction.continueGpsDoNotShowAgain,
      ).toSafeSummary();

      expect(safe['dashboardSettingsCanRestorePrompt'], isTrue);
      expect(safe['continueGpsDoesNotConfirmMileage'], isTrue);
      expect(safe['cancelGpsOnlyPausesGpsSampling'], isTrue);
      expect(safe['doNotShowAgainDoesNotRemoveSettingsReversal'], isTrue);
      expect(safe['batteryActionCanDeleteTripRecords'], isFalse);
      expect(safe['batteryActionCanConfirmMileage'], isFalse);
      expect(safe['firebaseCanOverrideBatteryChoice'], isFalse);
      expect(safe['mapboxCanOverrideBatteryChoice'], isFalse);
      expect(safe['hiveRemainsOperationalSourceOfTruth'], isTrue);
      expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
      expect(safe['preciseBatteryIncluded'], isFalse);
      expect(safe['rawBatteryPayloadIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
      expect(safe.toString(), isNot(contains('19')));
      expect(safe.toString(), isNot(contains('pk.')));
      expect(safe.toString(), isNot(contains('sk.')));
    },
  );
}

TripGpsBatteryDecision promptDecision() {
  return const TripTrackingPolicy().gpsBatteryDecision(
    batteryPercent: 19,
    isCharging: false,
    lowBatteryProtectionEnabled: true,
    lowBatteryOverrideEnabled: false,
    lowBatteryWarningDismissed: false,
  );
}

TripGpsBatteryDecision blockedDecision() {
  return const TripTrackingPolicy().gpsBatteryDecision(
    batteryPercent: 19,
    isCharging: false,
    lowBatteryProtectionEnabled: true,
    lowBatteryOverrideEnabled: false,
    lowBatteryWarningDismissed: true,
  );
}

TripGpsBatteryDecision allowedDecision() {
  return const TripTrackingPolicy().gpsBatteryDecision(
    batteryPercent: 80,
    isCharging: false,
    lowBatteryProtectionEnabled: true,
    lowBatteryOverrideEnabled: false,
    lowBatteryWarningDismissed: false,
  );
}
