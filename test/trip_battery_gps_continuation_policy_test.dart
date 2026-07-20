import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_battery_gps_continuation_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_policy.dart';

void main() {
  test('low battery prompt pauses GPS but keeps trip and text log alive', () {
    final decision = TripBatteryGpsContinuationPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.activeTracking,
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
    expect(safe['gpsPauseCanConfirmMileage'], isFalse);
    expect(safe['gpsPauseCanSetGlobalTruth'], isFalse);
    expect(safe['gpsPauseCanChangeOfficialMileage'], isFalse);
    expect(safe['lowBatteryPauseIsGpsOnly'], isTrue);
    expect(safe['lowBatteryPauseRequiresLocalCheckpoint'], isTrue);
    expect(safe['backgroundGpsCanResumeAfterUserOverride'], isTrue);
    expect(safe['backgroundGpsRequiresPlatformGrant'], isTrue);
    expect(safe['foregroundLocationDoesNotGrantBackgroundGps'], isTrue);
    expect(safe['backgroundPermissionCanBeAssumed'], isFalse);
    expect(safe['lowBatteryChoiceRequiresLocalSettings'], isTrue);
    expect(safe['lowBatteryPromptMustBeReversible'], isTrue);
    expect(safe['batteryPauseCannotUploadBackupByItself'], isTrue);
    expect(safe['batteryPauseCannotPurgeLocalDataAfterBackup'], isTrue);
    expect(safe['gpsContinuationRequiresActiveLocalTrip'], isTrue);
    expect(safe['manualOdometerEntryStillAllowed'], isTrue);
    expect(
      TripBatteryGpsContinuationSummaryValidation.fromSummary(
        safe,
      ).isRenderable,
      isTrue,
    );
  });

  test('saved cancel choice pauses GPS without stopping trip records', () {
    final decision = TripBatteryGpsContinuationPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.signalDegraded,
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
      // A driver override may continue below the configured 20% safeguard,
      // but never below the hard emergency reserve.
      batteryDecision: battery(percent: 15, override: true),
    );

    expect(decision.status, TripBatteryGpsContinuationStatus.continueGps);
    expect(decision.shouldContinueGpsSampling, isTrue);
    expect(decision.shouldWriteLocalCheckpoint, isTrue);
    expect(decision.reasonCode, 'user_override_low_battery');
  });

  test('background GPS pauses when platform permission is missing', () {
    final decision = TripBatteryGpsContinuationPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.activeTracking,
      localSessionAvailable: true,
      appInBackground: true,
      foregroundServiceAvailable: true,
      backgroundTrackingPermissionGranted: false,
      batteryDecision: battery(percent: 80),
    );
    final safe = decision.toSafeDashboardMap();

    expect(
      decision.status,
      TripBatteryGpsContinuationStatus.pauseForBackgroundPermission,
    );
    expect(
      decision.reasonCode,
      'background_permission_required_for_background_gps',
    );
    expect(decision.shouldContinueGpsSampling, isFalse);
    expect(decision.shouldPromptUser, isFalse);
    expect(decision.shouldKeepTripSessionAlive, isTrue);
    expect(decision.shouldKeepTextTripLogWritable, isTrue);
    expect(decision.shouldWriteLocalCheckpoint, isTrue);
    expect(decision.requiresBackgroundPermission, isTrue);
    expect(decision.canRetryWhenForeground, isTrue);
    expect(safe['backgroundPermissionCanBeProvidedByFirestore'], isFalse);
    expect(safe['backgroundPermissionCanBeProvidedByMapbox'], isFalse);
    expect(safe['gpsPauseCanEndTripAutomatically'], isFalse);
    expect(safe['gpsPauseCanDeleteTripRecords'], isFalse);
    expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
    expect(safe['physicalOdometerRequiredForOfficialMileage'], isTrue);
    expect(safe['externalMileageCannotBecomeGlobalTruth'], isTrue);
    expect(safe['gpsDistanceCanOnlyAdviseMileageReview'], isTrue);
    expect(safe['mapMatchingCanOnlyAdviseMileageReview'], isTrue);
    expect(safe['optimizationCannotChangeOfficialMileage'], isTrue);
  });

  test('background GPS pauses when foreground service is unavailable', () {
    final decision = TripBatteryGpsContinuationPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.recovering,
      localSessionAvailable: true,
      appInBackground: true,
      foregroundServiceAvailable: false,
      backgroundTrackingPermissionGranted: true,
      batteryDecision: battery(percent: 80),
    );

    expect(
      decision.status,
      TripBatteryGpsContinuationStatus.pauseForBackgroundPermission,
    );
    expect(
      decision.reasonCode,
      'foreground_service_required_for_background_gps',
    );
    expect(decision.shouldKeepTripSessionAlive, isTrue);
    expect(decision.requiresForegroundService, isTrue);
    expect(decision.canRetryWhenForeground, isTrue);
  });

  test('malformed battery decision prompts instead of continuing GPS', () {
    final decision = TripBatteryGpsContinuationPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.activeTracking,
      localSessionAvailable: true,
      batteryDecision: const TripGpsBatteryDecision(
        status: TripGpsBatteryDecisionStatus.allowed,
        reasonCode: 'token=sk.secret battery 12%',
        batteryBucket: '12%',
        safetyCutoffPercent: 20,
        promptTitle: 'unsafe',
        promptBody: 'unsafe',
      ),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripBatteryGpsContinuationStatus.promptUser);
    expect(decision.reasonCode, 'battery_unknown');
    expect(decision.shouldContinueGpsSampling, isFalse);
    expect(decision.shouldPromptUser, isTrue);
    expect(decision.shouldKeepTripSessionAlive, isTrue);
    expect(decision.shouldKeepTextTripLogWritable, isTrue);
    expect(safe['rawBatteryPayloadIncluded'], isFalse);
    expect(safe['preciseBatteryIncluded'], isFalse);
    expect(safe.toString(), isNot(contains('sk.secret')));
    expect(
      TripBatteryGpsContinuationSummaryValidation.fromSummary(
        safe,
      ).isRenderable,
      isTrue,
    );
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
      lifecycle: TripTrackingSessionLifecycleState.activeTracking,
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
        lifecycle: TripTrackingSessionLifecycleState.activeTracking,
        localSessionAvailable: true,
        batteryDecision: battery(percent: 12, warningDismissed: true),
      ).toSafeDashboardMap();

      expect(safe['preciseBatteryIncluded'], isFalse);
      expect(safe['rawBatteryPayloadIncluded'], isFalse);
      expect(safe['firebaseCanOverrideBatteryChoice'], isFalse);
      expect(safe['cloudFunctionCanOverrideBatteryChoice'], isFalse);
      expect(safe['mapboxCanOverrideBatteryChoice'], isFalse);
      expect(safe['backgroundPermissionCanBeProvidedByFirestore'], isFalse);
      expect(safe['backgroundPermissionCanBeProvidedByMapbox'], isFalse);
      expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
      expect(safe['confirmedOdometerOverridesExternalMileage'], isTrue);
      expect(safe['externalMileageCannotBecomeGlobalTruth'], isTrue);
      expect(safe['gpsDistanceCanOnlyAdviseMileageReview'], isTrue);
      expect(safe['mapMatchingCanOnlyAdviseMileageReview'], isTrue);
      expect(safe['optimizationCannotChangeOfficialMileage'], isTrue);
      expect(safe.toString(), isNot(contains('12')));
      expect(safe.toString(), isNot(contains('pk.')));
      expect(safe.toString(), isNot(contains('sk.')));
      expect(
        TripBatteryGpsContinuationSummaryValidation.fromSummary(
          safe,
        ).isRenderable,
        isTrue,
      );
    },
  );

  test('battery continuation summary rejects forged trip authority', () {
    final safe = TripBatteryGpsContinuationPolicy.evaluate(
      lifecycle: TripTrackingSessionLifecycleState.activeTracking,
      localSessionAvailable: true,
      batteryDecision: battery(percent: 12, warningDismissed: true),
    ).toSafeDashboardMap();

    expect(
      TripBatteryGpsContinuationSummaryValidation.fromSummary({
        ...safe,
        'gpsPauseCanConfirmMileage': true,
        'gpsPauseCanSetGlobalTruth': true,
        'gpsPauseCanChangeOfficialMileage': true,
      }).reasons,
      contains('battery_pause_claims_trip_truth'),
    );
    expect(
      TripBatteryGpsContinuationSummaryValidation.fromSummary({
        ...safe,
        'lowBatteryPromptMustBeReversible': false,
      }).reasons,
      contains('battery_local_trip_boundary_missing'),
    );
    expect(
      TripBatteryGpsContinuationSummaryValidation.fromSummary({
        ...safe,
        'backgroundPermissionCanBeAssumed': true,
      }).reasons,
      contains('background_permission_boundary_missing'),
    );
    expect(
      TripBatteryGpsContinuationSummaryValidation.fromSummary({
        ...safe,
        'firebaseCanOverrideBatteryChoice': true,
      }).reasons,
      contains('remote_can_override_battery_choice'),
    );
    expect(
      TripBatteryGpsContinuationSummaryValidation.fromSummary({
        ...safe,
        'debug': 'battery 12% token=sk.secret',
      }).reasons,
      contains('summary_contains_sensitive_battery_material'),
    );
  });
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
