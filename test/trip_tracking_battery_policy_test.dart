import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test('low battery GPS decision requires explicit user choice by default', () {
    const policy = TripTrackingPolicy();
    const settings = TripTrackingSettings();

    final decision = policy.gpsBatteryDecision(
      batteryPercent: 19,
      isCharging: false,
      lowBatteryProtectionEnabled: settings.lowBatteryGpsProtectionEnabled,
      lowBatteryOverrideEnabled: settings.lowBatteryGpsOverrideEnabled,
      lowBatteryWarningDismissed: settings.lowBatteryGpsWarningDismissed,
    );

    expect(decision.status, TripGpsBatteryDecisionStatus.userPromptRequired);
    expect(decision.allowsGps, isFalse);
    expect(decision.requiresUserChoice, isTrue);
    expect(decision.reasonCode, 'low_battery_requires_user_choice');
    expect(decision.batteryBucket, 'below_20');
    expect(decision.promptTitle, 'Battery below 20%');
    expect(
      decision.promptBody,
      contains('paused by default below the safety threshold'),
    );
  });

  test('malformed low battery GPS cutoff uses the safe default', () {
    const policy = TripTrackingPolicy(lowBatteryGpsCutoffPercent: -1);

    final decision = policy.gpsBatteryDecision(
      batteryPercent: 19,
      isCharging: false,
      lowBatteryProtectionEnabled: true,
      lowBatteryOverrideEnabled: false,
      lowBatteryWarningDismissed: false,
    );

    expect(decision.status, TripGpsBatteryDecisionStatus.userPromptRequired);
    expect(decision.reasonCode, 'low_battery_requires_user_choice');
  });

  test('critical battery blocks GPS even after a prior user override', () {
    const policy = TripTrackingPolicy();
    final settings = const TripTrackingSettings().copyWith(
      gpsAssistedTrackingEnabled: true,
      lowBatteryGpsOverrideEnabled: true,
      lowBatteryGpsWarningDismissed: true,
    );

    final decision = policy.gpsBatteryDecision(
      batteryPercent: 5,
      isCharging: false,
      lowBatteryProtectionEnabled: settings.lowBatteryGpsProtectionEnabled,
      lowBatteryOverrideEnabled: settings.lowBatteryGpsOverrideEnabled,
      lowBatteryWarningDismissed: settings.lowBatteryGpsWarningDismissed,
    );

    expect(decision.status, TripGpsBatteryDecisionStatus.blocked);
    expect(decision.reasonCode, 'battery_critical_gps_blocked');
    expect(decision.batteryBucket, 'below_20');
    final summary = decision.toSafeSummary();
    expect(summary['allowsGps'], isFalse);
    expect(summary['requiresUserChoice'], isFalse);
    expect(summary['hardGpsShutdownPercent'], 10);
  });

  test('critical battery cannot be bypassed by charging or disabled guard', () {
    const policy = TripTrackingPolicy();

    for (final decision in [
      policy.gpsBatteryDecision(
        batteryPercent: 9,
        isCharging: true,
        lowBatteryProtectionEnabled: true,
        lowBatteryOverrideEnabled: true,
        lowBatteryWarningDismissed: true,
      ),
      policy.gpsBatteryDecision(
        batteryPercent: 9,
        isCharging: false,
        lowBatteryProtectionEnabled: false,
        lowBatteryOverrideEnabled: true,
        lowBatteryWarningDismissed: true,
      ),
    ]) {
      expect(decision.status, TripGpsBatteryDecisionStatus.blocked);
      expect(decision.reasonCode, 'battery_critical_gps_blocked');
      expect(
        decision.toSafeSummary()['reasonCode'],
        'battery_critical_gps_blocked',
      );
    }
  });

  test('low power mode asks before GPS unless the user overrides it', () {
    const policy = TripTrackingPolicy();
    const settings = TripTrackingSettings();

    final prompt = policy.gpsBatteryDecision(
      batteryPercent: 80,
      isCharging: false,
      lowPowerModeEnabled: true,
      lowBatteryProtectionEnabled: settings.lowBatteryGpsProtectionEnabled,
      lowBatteryOverrideEnabled: settings.lowBatteryGpsOverrideEnabled,
      lowBatteryWarningDismissed: settings.lowBatteryGpsWarningDismissed,
    );
    final override = policy.gpsBatteryDecision(
      batteryPercent: 80,
      isCharging: false,
      lowPowerModeEnabled: true,
      lowBatteryProtectionEnabled: settings.lowBatteryGpsProtectionEnabled,
      lowBatteryOverrideEnabled: true,
      lowBatteryWarningDismissed: false,
    );

    expect(prompt.status, TripGpsBatteryDecisionStatus.userPromptRequired);
    expect(prompt.reasonCode, 'low_power_mode_requires_user_choice');
    expect(prompt.batteryBucket, '50_plus');
    expect(prompt.promptTitle, 'Battery saver is active');
    expect(override.status, TripGpsBatteryDecisionStatus.allowed);
    expect(override.reasonCode, 'user_override_low_power_mode');
  });

  test('cancel and do-not-show-again keeps low battery GPS blocked', () {
    const policy = TripTrackingPolicy();
    final settings = const TripTrackingSettings().copyWith(
      gpsAssistedTrackingEnabled: true,
      lowBatteryGpsOverrideEnabled: false,
      lowBatteryGpsWarningDismissed: true,
    );

    final decision = policy.gpsBatteryDecision(
      batteryPercent: 19,
      isCharging: false,
      lowBatteryProtectionEnabled: settings.lowBatteryGpsProtectionEnabled,
      lowBatteryOverrideEnabled: settings.lowBatteryGpsOverrideEnabled,
      lowBatteryWarningDismissed: settings.lowBatteryGpsWarningDismissed,
    );

    expect(decision.status, TripGpsBatteryDecisionStatus.blocked);
    expect(decision.reasonCode, 'low_battery_gps_blocked_by_saved_choice');
    expect(decision.isSavedBlock, isTrue);
    expect(decision.promptBody, contains('dashboard settings'));
    expect(
      decision.toSafeSummary()['batteryDataCanDeleteTripRecords'],
      isFalse,
    );
    expect(decision.toSafeSummary()['lowBatteryCanStopTextTripLog'], isFalse);
  });

  test('unknown battery does not block GPS, but critical battery does', () {
    const policy = TripTrackingPolicy();

    final charging = policy.gpsBatteryDecision(
      batteryPercent: 1,
      isCharging: true,
      lowBatteryProtectionEnabled: true,
      lowBatteryOverrideEnabled: false,
      lowBatteryWarningDismissed: false,
    );
    final unknown = policy.gpsBatteryDecision(
      batteryPercent: null,
      isCharging: false,
      lowBatteryProtectionEnabled: true,
      lowBatteryOverrideEnabled: false,
      lowBatteryWarningDismissed: false,
    );

    expect(charging.status, TripGpsBatteryDecisionStatus.blocked);
    expect(charging.reasonCode, 'battery_critical_gps_blocked');
    expect(unknown.status, TripGpsBatteryDecisionStatus.allowed);
    expect(unknown.reasonCode, 'battery_unknown');
    expect(unknown.batteryBucket, 'unknown');
  });

  test('GPS battery decision safe summary never exposes exact battery', () {
    const policy = TripTrackingPolicy();

    for (final percent in const [0, 5, 19, 20, 49, 50, 100, 150, -1]) {
      final decision = policy.gpsBatteryDecision(
        batteryPercent: percent,
        isCharging: false,
        lowBatteryProtectionEnabled: true,
        lowBatteryOverrideEnabled: false,
        lowBatteryWarningDismissed: false,
      );
      final summary = decision.toSafeSummary();

      expect(summary['preciseBatteryIncluded'], isFalse);
      expect(summary['rawBatteryPayloadIncluded'], isFalse);
      expect(summary['settingsReversalAvailable'], isTrue);
      expect(summary['defaultGpsPausesBelowCutoff'], isTrue);
      expect(summary['userOverrideRequiresExplicitChoice'], isTrue);
      expect(summary['batteryGuardCanBeChangedInSettings'], isTrue);
      expect(summary['batteryDataTrustedAfterValidationOnly'], isTrue);
      expect(summary['firebaseBatteryStateCanOverrideGpsDecision'], isFalse);
      expect(summary['mapboxCanOverrideBatteryDecision'], isFalse);
      expect(summary['malformedBatteryPayloadFailsSafe'], isTrue);
      expect(summary['mapsRequiredForGps'], isFalse);
      expect(summary['tripDataDeletionAllowed'], isFalse);
      expect(summary['odometerRemainsCanonical'], isTrue);
      expect(summary.toString(), isNot(contains('batteryPercent')));
      expect(
        summary['batteryBucket'],
        isIn(const ['below_20', '20_to_49', '50_plus', 'unknown']),
      );
    }
  });

  test('GPS battery summary sanitizes malformed public fields', () {
    const decision = TripGpsBatteryDecision(
      status: TripGpsBatteryDecisionStatus.userPromptRequired,
      reasonCode: 'sk.secret at 35.12,-80.12',
      batteryBucket: '18 percent',
      safetyCutoffPercent: 999,
      promptTitle: 'raw pk.public token',
      promptBody: 'driver stopped at 35.12,-80.12',
    );

    final summary = decision.toSafeSummary();

    expect(summary['reasonCode'], 'battery_unknown');
    expect(summary['batteryBucket'], 'unknown');
    expect(summary['safetyCutoffPercent'], 20);
    expect(summary['promptTitle'], 'GPS battery guard');
    expect(summary['promptBody'], 'GPS battery guard did not block tracking.');
    expect(summary['batteryDataTrustedAfterValidationOnly'], isTrue);
    expect(summary['firebaseBatteryStateCanOverrideGpsDecision'], isFalse);
    expect(summary['mapboxCanOverrideBatteryDecision'], isFalse);
    expect(summary['malformedBatteryPayloadFailsSafe'], isTrue);
    expect(summary.toString(), isNot(contains('35.12')));
    expect(summary.toString(), isNot(contains('sk.secret')));
    expect(summary.toString(), isNot(contains('pk.public')));
  });
}
