import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_battery_gps_continuation_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_policy.dart';

void main() {
  test('low battery prompt pauses GPS but keeps trip and text log alive', () {
    final decision = TripBatteryGpsContinuationPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.active,
      localSessionAvailable: true,
      batteryDecision: battery(
        percent: 19,
        override: false,
        warningDismissed: false,
      ),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripBatteryGpsContinuationStatus.promptUser);
    expect(decision.shouldContinueGpsSampling, isFalse);
    expect(decision.shouldPromptUser, isTrue);
    expect(decision.shouldKeepTripSessionAlive, isTrue);
    expect(decision.shouldKeepTextTripLogWritable, isTrue);
    expect(decision.shouldWriteLocalCheckpoint, isTrue);
    expect(safe['gpsPauseCanEndTripAutomatically'], isFalse);
    expect(safe['gpsPauseCanDeleteTripRecords'], isFalse);
    expect(safe['manualOdometerEntryStillAllowed'], isTrue);
  });

  test('saved cancel choice pauses GPS without stopping trip records', () {
    final decision = TripBatteryGpsContinuationPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.degraded,
      localSessionAvailable: true,
      batteryDecision: battery(
        percent: 19,
        override: false,
        warningDismissed: true,
      ),
    );

    expect(
      decision.status,
      TripBatteryGpsContinuationStatus.pauseGpsKeepTripAlive,
    );
    expect(decision.shouldContinueGpsSampling, isFalse);
    expect(decision.shouldPromptUser, isFalse);
    expect(decision.shouldKeepTripSessionAlive, isTrue);
    expect(decision.shouldKeepTextTripLogWritable, isTrue);
  });

  test('explicit user override allows GPS and still checkpoints locally', () {
    final decision = TripBatteryGpsContinuationPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.recovering,
      localSessionAvailable: true,
      batteryDecision: battery(percent: 5, override: true),
    );

    expect(decision.status, TripBatteryGpsContinuationStatus.continueGps);
    expect(decision.shouldContinueGpsSampling, isTrue);
    expect(decision.shouldWriteLocalCheckpoint, isTrue);
    expect(decision.reasonCode, 'user_override_low_battery');
  });

  test('invalid trip state blocks battery GPS continuation boundary', () {
    final decision = TripBatteryGpsContinuationPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.completed,
      localSessionAvailable: true,
      batteryDecision: battery(percent: 80),
    );

    expect(
      decision.status,
      TripBatteryGpsContinuationStatus.blockedInvalidTrip,
    );
    expect(decision.shouldKeepTripSessionAlive, isFalse);
    expect(decision.shouldKeepTextTripLogWritable, isFalse);
  });

  test('missing local session blocks remote-only battery decisions', () {
    final decision = TripBatteryGpsContinuationPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.active,
      localSessionAvailable: false,
      batteryDecision: battery(percent: 19),
    );

    expect(
      decision.status,
      TripBatteryGpsContinuationStatus.blockedInvalidTrip,
    );
    expect(
      decision.toSafeDashboardMap()['firebaseCanOverrideBatteryChoice'],
      isFalse,
    );
    expect(
      decision.toSafeDashboardMap()['mapboxCanOverrideBatteryChoice'],
      isFalse,
    );
  });

  test(
    'safe summary never exposes exact battery or grants remote authority',
    () {
      final safe = TripBatteryGpsContinuationPolicy.evaluate(
        lifecycle: TripTrackingSessionLifecycleState.active,
        localSessionAvailable: true,
        batteryDecision: battery(percent: 12, warningDismissed: true),
      ).toSafeDashboardMap();

      expect(safe['preciseBatteryIncluded'], isFalse);
      expect(safe['rawBatteryPayloadIncluded'], isFalse);
      expect(safe['firebaseCanOverrideBatteryChoice'], isFalse);
      expect(safe['cloudFunctionCanOverrideBatteryChoice'], isFalse);
      expect(safe['mapboxCanOverrideBatteryChoice'], isFalse);
      expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
      expect(safe.toString(), isNot(contains('12')));
      expect(safe.toString(), isNot(contains('pk.')));
      expect(safe.toString(), isNot(contains('sk.')));
    },
  );
}

TripGpsBatteryDecision battery({
  required int? percent,
  bool override = false,
  bool warningDismissed = false,
}) {
  return const TripTrackingPolicy().gpsBatteryDecision(
    batteryPercent: percent,
    isCharging: false,
    lowBatteryProtectionEnabled: true,
    lowBatteryOverrideEnabled: override,
    lowBatteryWarningDismissed: warningDismissed,
  );
}
