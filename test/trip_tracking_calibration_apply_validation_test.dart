import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_calibration_apply_guard.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_calibration.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18, 12);

  TripOdometerCalibrationSignal signal({int excludedPoorGpsDayCount = 0}) =>
      TripOdometerCalibrationSignal(
        status: TripOdometerCalibrationStatus.reviewRecommended,
        eligibleSampleCount: 7,
        trustedGpsWindowCount: 7,
        excludedPoorGpsDayCount: excludedPoorGpsDayCount,
        averageGpsToOdometerRatio: .94,
        averageDifferencePercent: 6,
        reasonCode: 'persistent_gps_odometer_drift',
      );

  Map<String, Object?> summary({int excludedPoorGpsDayCount = 0}) {
    return TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(excludedPoorGpsDayCount: excludedPoorGpsDayCount),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
    ).toSafeDashboardMap();
  }

  test('safe calibration apply summary validates as renderable', () {
    final validation =
        TripTrackingCalibrationApplySummaryValidation.fromSummary(summary());

    expect(validation.isRenderable, isTrue);
    expect(
      validation.status,
      TripTrackingCalibrationApplyStatus.readyForFutureProjection,
    );
    expect(validation.reasons, isEmpty);
  });

  test(
    'calibration summary rejects mutation, remote, and sensitive claims',
    () {
      final validation =
          TripTrackingCalibrationApplySummaryValidation.fromSummary(
            summary()..addAll({
              'appliesToPastTrips': true,
              'calibrationCanSetGlobalTruth': true,
              'calibrationCanChangeGlobalTruth': true,
              'calibrationCanConfirmOfficialMileage': true,
              'canRewriteConfirmedOdometer': true,
              'canApplySilently': true,
              'calibrationCanChangeDisplayedConfirmedMiles': true,
              'calibrationCanMutateTripLog': true,
              'calibrationCanPurgeLocalDataAfterBackup': true,
              'calibrationCanBypassVehicleProfile': true,
              'calibrationCanApplyAcrossVehicles': true,
              'calibrationRequiresSingleVehicleHistory': false,
              'calibrationRequiresLocalReviewedOdometerHistory': false,
              'continuousCalibrationAverageRequired': false,
              'poorGpsDaysExcludedFromCalibration': false,
              'calibrationRequiresTrustedGpsWindow': false,
              'singleDayCalibrationRejected': false,
              'calibrationAverageVehicleScoped': false,
              'calibrationRequiresOwnershipOrExplicitAccess': false,
              'settingsCanDisableCalibrationAssist': false,
              'settingsCanResetCalibrationPrompt': false,
              'fleetObserverCanApplyCalibration': true,
              'calibrationVehicleIdIncluded': true,
              'rawVehicleIdsIncluded': true,
              'remoteCalibrationCanRewritePastTrips': true,
              'mapboxRouteDistanceCanBecomeOfficial': true,
              'firestoreCanApplyCalibration': true,
              'mapboxCanApplyCalibration': true,
              'cloudFunctionCanApplyCalibration': true,
              'importedFileCanApplyCalibration': true,
              'dashboardCacheCanApplyCalibration': true,
              'remoteCalibrationCanOverrideLocalState': true,
              'remoteCalibrationCanEnableSetting': true,
              'remoteCalibrationCanResetPrompt': true,
              'mapboxCanTriggerTirePrompt': true,
              'gpsCanAutoApplyCalibration': true,
              'odometerIsGlobalTruth': false,
              'physicalOdometerIsCanonical': false,
              'gpsCanOverrideOdometer': true,
              'mapboxCanOverrideOdometer': true,
              'firebaseMirrorCanOverrideOdometer': true,
              'cloudFunctionCanOverrideOdometer': true,
              'importedFileCanOverrideOdometer': true,
              'localCacheCanOverrideOdometer': true,
              'sensorFusionCanOverrideOdometer': true,
              'calibrationAppliesToFutureGpsProjectionOnly': false,
              'tireChangeDoesNotCreateMaintenanceEntry': false,
              'calibrationCanLowerConfirmedOdometer': true,
              'calibrationCanCreateMaintenanceRecord': true,
              'rawReviewedTripsIncluded': true,
              'rawGpsIncluded': true,
              'preciseLocationIncluded': true,
              'tokensIncluded': true,
              'debug': 'sk.secret 35.123456,-80.123456',
            }),
          );

      expect(validation.isRenderable, isFalse);
      expect(validation.reasons, contains('calibration_can_mutate_trip_truth'));
      expect(
        validation.reasons,
        contains('remote_or_map_can_apply_calibration'),
      );
      expect(
        validation.reasons,
        contains('remote_or_sensor_can_control_prompt'),
      );
      expect(
        validation.reasons,
        contains('calibration_review_boundary_missing'),
      );
      expect(validation.reasons, contains('odometer_truth_boundary_missing'));
      expect(
        validation.reasons,
        contains('summary_contains_sensitive_calibration_material'),
      );
      expect(validation.reasons, contains('summary_contains_sensitive_text'));
    },
  );

  test('calibration summary rejects poor GPS apply authority mismatch', () {
    final validation =
        TripTrackingCalibrationApplySummaryValidation.fromSummary(
          summary(excludedPoorGpsDayCount: 1)..addAll({
            'status': TripTrackingCalibrationApplyStatus
                .readyForFutureProjection
                .name,
            'canApplyToFutureGpsProjection': true,
            'reasonCodes': const [
              'calibration_review_accepted_future_projection_only',
            ],
          }),
        );

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      contains('excluded_poor_gps_cannot_apply_calibration'),
    );
  });
}
