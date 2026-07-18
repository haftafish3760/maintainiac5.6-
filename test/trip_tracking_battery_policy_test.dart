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

  test('low battery override allows GPS only after user opt-in', () {
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

    expect(decision.status, TripGpsBatteryDecisionStatus.allowed);
    expect(decision.reasonCode, 'user_override_low_battery');
    expect(decision.batteryBucket, 'below_20');
    expect(decision.toSafeSummary(), {
      'status': 'allowed',
      'reasonCode': 'user_override_low_battery',
      'batteryBucket': 'below_20',
      'safetyCutoffPercent': 20,
      'promptTitle': 'GPS battery guard',
      'promptBody':
          'GPS is continuing because you opted in to bypass the battery guard.',
      'allowsGps': true,
      'requiresUserChoice': false,
      'userCanOverride': false,
      'continueGpsActionLabel': 'Continue with GPS',
      'cancelGpsActionLabel': 'Cancel GPS',
      'doNotShowAgainAvailable': false,
      'settingsReversalAvailable': true,
      'defaultGpsPausesBelowCutoff': true,
      'userOverrideRequiresExplicitChoice': true,
      'batteryGuardCanBeChangedInSettings': true,
      'gpsTrackingCanRetryWhenCharging': true,
      'mapsRequiredForGps': false,
      'tripDataDeletionAllowed': false,
      'odometerRemainsCanonical': true,
      'preciseBatteryIncluded': false,
      'rawBatteryPayloadIncluded': false,
    });
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
  });

  test('charging device or unknown battery reading does not block GPS', () {
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

    expect(charging.status, TripGpsBatteryDecisionStatus.allowed);
    expect(charging.reasonCode, 'device_charging');
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
}
