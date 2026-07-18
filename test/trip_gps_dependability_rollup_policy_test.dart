import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_gps_dependability_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_gps_dependability_rollup_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_signal_quality.dart';

void main() {
  test('empty rollup waits without creating mileage truth', () {
    final rollup = TripGpsDependabilityRollupPolicy.evaluate(windows: const []);
    final safe = rollup.toSafeDashboardMap();

    expect(rollup.status, TripGpsDependabilityRollupStatus.noWindows);
    expect(rollup.canUseForLiveAssist, isFalse);
    expect(rollup.canUseForCalibrationEvidence, isFalse);
    expect(safe['odometerIsGlobalTruth'], isTrue);
    expect(safe['gpsRollupCanReplaceOdometer'], isFalse);
    expect(safe['gpsRollupCanCreateOfficialStop'], isFalse);
  });

  test('sustained ready windows become calibration-eligible evidence', () {
    final rollup = TripGpsDependabilityRollupPolicy.evaluate(
      windows: List.generate(
        6,
        (_) => window(TripGpsDependabilityStatus.readyForAssist),
      ),
      minimumReadyWindowsForCalibration: 5,
      minimumReadyRateForCalibration: .75,
    );
    final safe = rollup.toSafeDashboardMap();

    expect(rollup.status, TripGpsDependabilityRollupStatus.reliable);
    expect(rollup.readyWindowCount, 6);
    expect(rollup.canUseForLiveAssist, isTrue);
    expect(rollup.canUseForCalibrationEvidence, isTrue);
    expect(safe['calibrationRequiresSustainedDailyGpsQuality'], isTrue);
    expect(safe['calibrationRequiresReviewedOdometerTruth'], isTrue);
  });

  test('one paused poor GPS window excludes the day from calibration', () {
    final rollup = TripGpsDependabilityRollupPolicy.evaluate(
      windows: [
        for (var index = 0; index < 7; index += 1)
          window(TripGpsDependabilityStatus.readyForAssist),
        window(
          TripGpsDependabilityStatus.projectionPaused,
          signalQuality: TripTrackingSignalQuality.poor,
          requiresUserReview: true,
        ),
      ],
    );
    final safe = rollup.toSafeDashboardMap();

    expect(
      rollup.status,
      TripGpsDependabilityRollupStatus.excludedFromCalibration,
    );
    expect(rollup.readyWindowCount, 7);
    expect(rollup.pausedWindowCount, 1);
    expect(rollup.canUseForLiveAssist, isTrue);
    expect(rollup.canUseForCalibrationEvidence, isFalse);
    expect(rollup.requiresUserReview, isTrue);
    expect(safe['oneGoodWindowCannotClearBadDay'], isTrue);
    expect(safe['poorWindowExcludesCalibrationDay'], isTrue);
  });

  test('review-only windows keep live assist but not calibration proof', () {
    final rollup = TripGpsDependabilityRollupPolicy.evaluate(
      windows: [
        window(TripGpsDependabilityStatus.readyForAssist),
        window(
          TripGpsDependabilityStatus.reviewOnly,
          signalQuality: TripTrackingSignalQuality.reduced,
        ),
      ],
    );

    expect(rollup.status, TripGpsDependabilityRollupStatus.reviewOnly);
    expect(rollup.canUseForLiveAssist, isTrue);
    expect(rollup.canUseForCalibrationEvidence, isFalse);
  });

  test('rideshare rollups require stronger sustained GPS evidence', () {
    final borderline = TripGpsDependabilityRollupPolicy.evaluate(
      profile: TripTrackingProfile.rideshareVehicle,
      windows: [
        for (var index = 0; index < 7; index += 1)
          window(TripGpsDependabilityStatus.readyForAssist),
      ],
    );
    final strong = TripGpsDependabilityRollupPolicy.evaluate(
      profile: TripTrackingProfile.rideshareVehicle,
      windows: [
        for (var index = 0; index < 8; index += 1)
          window(TripGpsDependabilityStatus.readyForAssist),
      ],
    );

    expect(borderline.status, TripGpsDependabilityRollupStatus.reviewOnly);
    expect(borderline.reasonCode, 'gps_rollup_needs_more_ready_windows');
    expect(borderline.canUseForLiveAssist, isTrue);
    expect(borderline.canUseForCalibrationEvidence, isFalse);
    expect(strong.status, TripGpsDependabilityRollupStatus.reliable);
    expect(strong.canUseForCalibrationEvidence, isTrue);
  });

  test(
    'delivery and contractor profiles accept practical reviewed evidence',
    () {
      for (final profile in const [
        TripTrackingProfile.deliveryVehicle,
        TripTrackingProfile.contractorVehicle,
      ]) {
        final rollup = TripGpsDependabilityRollupPolicy.evaluate(
          profile: profile,
          windows: [
            for (var index = 0; index < 6; index += 1)
              window(TripGpsDependabilityStatus.readyForAssist),
          ],
        );

        expect(rollup.status, TripGpsDependabilityRollupStatus.reliable);
        expect(rollup.canUseForCalibrationEvidence, isTrue);
      }
    },
  );

  test('unsafe windows fail closed and do not leak route data', () {
    final rollup = TripGpsDependabilityRollupPolicy.evaluate(
      windows: [
        window(TripGpsDependabilityStatus.readyForAssist),
        window(
          TripGpsDependabilityStatus.unsafeBlocked,
          signalQuality: TripTrackingSignalQuality.unsafe,
          requiresUserReview: true,
        ),
      ],
    );
    final safe = rollup.toSafeDashboardMap();

    expect(rollup.status, TripGpsDependabilityRollupStatus.unsafe);
    expect(rollup.canUseForLiveAssist, isFalse);
    expect(rollup.canUseForCalibrationEvidence, isFalse);
    expect(rollup.requiresUserReview, isTrue);
    expect(safe['unsafeWindowExcludesCalibrationDay'], isTrue);
    expect(safe['mapboxCanOverrideGpsRollup'], isFalse);
    expect(safe['firestoreCanOverrideGpsRollup'], isFalse);
    expect(safe['cloudFunctionCanOverrideGpsRollup'], isFalse);
    expect(safe['coordinatesIncluded'], isFalse);
    expect(safe.toString(), isNot(contains('-80')));
  });
}

TripGpsDependabilityDecision window(
  TripGpsDependabilityStatus status, {
  TripTrackingSignalQuality signalQuality = TripTrackingSignalQuality.healthy,
  bool requiresUserReview = false,
}) {
  return TripGpsDependabilityDecision(
    status: status,
    reasonCode: status == TripGpsDependabilityStatus.readyForAssist
        ? 'gps_dependability_ready'
        : 'gps_rollup_test_window',
    profile: TripTrackingProfile.deliveryVehicle,
    confidence: status == TripGpsDependabilityStatus.readyForAssist
        ? TripTrackingConfidence.high
        : TripTrackingConfidence.low,
    signalQuality: signalQuality,
    canFeedLiveOdometerProjection:
        status == TripGpsDependabilityStatus.readyForAssist ||
        status == TripGpsDependabilityStatus.reviewOnly,
    canPersistCompactRoutePoint:
        status == TripGpsDependabilityStatus.readyForAssist,
    canOpenStopReview: status == TripGpsDependabilityStatus.readyForAssist,
    canContributeToCalibration:
        status == TripGpsDependabilityStatus.readyForAssist,
    shouldContinueSampling: status != TripGpsDependabilityStatus.unsafeBlocked,
    requiresUserReview: requiresUserReview,
  );
}
