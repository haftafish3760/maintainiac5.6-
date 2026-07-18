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
    expect(
      TripGpsDependabilityRollupSummaryValidation.fromSummary(
        safe,
      ).isRenderable,
      isTrue,
    );
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

  test('duplicate GPS window keys are treated as replayed unsafe evidence', () {
    final replayKey = TripGpsDependabilityRollupPolicy.windowKey(
      sessionId: 'trip_1',
      windowStartedAt: DateTime.utc(2026, 7, 18, 12, 0, 4),
      windowEndedAt: DateTime.utc(2026, 7, 18, 12, 0, 58),
    );
    final rollup = TripGpsDependabilityRollupPolicy.evaluate(
      windows: [
        window(TripGpsDependabilityStatus.readyForAssist),
        window(TripGpsDependabilityStatus.readyForAssist),
      ],
      windowKeys: [replayKey, replayKey],
    );
    final safe = rollup.toSafeDashboardMap();

    expect(rollup.status, TripGpsDependabilityRollupStatus.unsafe);
    expect(rollup.reasonCode, 'gps_rollup_duplicate_window_rejected');
    expect(rollup.canUseForLiveAssist, isFalse);
    expect(rollup.canUseForCalibrationEvidence, isFalse);
    expect(safe['duplicateWindowExcludesCalibrationDay'], isTrue);
    expect(
      TripGpsDependabilityRollupSummaryValidation.fromSummary(
        safe,
      ).isRenderable,
      isTrue,
    );
  });

  test(
    'window keys are bucketed and sanitized without coordinates or tokens',
    () {
      final first = TripGpsDependabilityRollupPolicy.windowKey(
        sessionId: 'trip 1 pk.public',
        windowStartedAt: DateTime.utc(2026, 7, 18, 12, 0, 4),
        windowEndedAt: DateTime.utc(2026, 7, 18, 12, 1, 3),
      );
      final second = TripGpsDependabilityRollupPolicy.windowKey(
        sessionId: 'trip 1 pk.public',
        windowStartedAt: DateTime.utc(2026, 7, 18, 12, 0, 50),
        windowEndedAt: DateTime.utc(2026, 7, 18, 12, 1, 59),
      );

      expect(first, second);
      expect(first, isNot(contains(' ')));
      expect(first, isNot(contains('pk.')));
      expect(first, isNot(contains('-80.')));
    },
  );

  test(
    'blank GPS window keys are ignored instead of creating false replay',
    () {
      final rollup = TripGpsDependabilityRollupPolicy.evaluate(
        windows: [
          window(TripGpsDependabilityStatus.readyForAssist),
          window(TripGpsDependabilityStatus.readyForAssist),
          window(TripGpsDependabilityStatus.readyForAssist),
          window(TripGpsDependabilityStatus.readyForAssist),
          window(TripGpsDependabilityStatus.readyForAssist),
        ],
        windowKeys: const ['', '   '],
      );

      expect(rollup.status, TripGpsDependabilityRollupStatus.reliable);
      expect(rollup.canUseForCalibrationEvidence, isTrue);
    },
  );

  test('summary validation rejects forged remote truth and sensitive data', () {
    final summary =
        TripGpsDependabilityRollupPolicy.evaluate(
          windows: [window(TripGpsDependabilityStatus.readyForAssist)],
        ).toSafeDashboardMap()..addAll({
          'schemaVersion': 2,
          'status': 'godMode',
          'reasonCode': 'pk.secret -80.123456',
          'windowCount': -1,
          'oneGoodWindowCannotClearBadDay': false,
          'poorWindowExcludesCalibrationDay': false,
          'interruptedWindowExcludesCalibrationDay': false,
          'unsafeWindowExcludesCalibrationDay': false,
          'duplicateWindowExcludesCalibrationDay': false,
          'calibrationRequiresSustainedDailyGpsQuality': false,
          'calibrationRequiresReviewedOdometerTruth': false,
          'gpsRollupCanReplaceOdometer': true,
          'gpsRollupCanConfirmOfficialMileage': true,
          'gpsRollupCanCreateOfficialStop': true,
          'mapboxCanOverrideGpsRollup': true,
          'firestoreCanOverrideGpsRollup': true,
          'cloudFunctionCanOverrideGpsRollup': true,
          'hiveRemainsOperationalSourceOfTruth': false,
          'odometerIsGlobalTruth': false,
          'rawSamplesIncluded': true,
          'coordinatesIncluded': true,
          'routeGeometryIncluded': true,
          'tokensIncluded': true,
        });
    final validation = TripGpsDependabilityRollupSummaryValidation.fromSummary(
      summary,
    );

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      containsAll([
        'unsupported_schema',
        'invalid_gps_rollup_status',
        'invalid_gps_rollup_reason',
        'windowCount_invalid',
        'gps_rollup_calibration_boundary_missing',
        'gps_rollup_can_create_trip_truth',
        'remote_can_override_gps_rollup',
        'summary_contains_sensitive_trip_material',
        'summary_contains_sensitive_text',
      ]),
    );
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
