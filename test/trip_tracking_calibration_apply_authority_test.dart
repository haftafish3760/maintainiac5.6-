import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_calibration_apply_guard.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_calibration.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18, 12);

  test('remote calibration history cannot apply even when reviewed', () {
    final firestore = TripTrackingCalibrationApplyGuard.evaluate(
      signal: _signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      currentUserId: 'driver_1',
      calibrationOwnerUserId: 'driver_1',
      historySource: TripTrackingCalibrationHistorySource.firestoreMirror,
    );
    final mapbox = TripTrackingCalibrationApplyGuard.evaluate(
      signal: _signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      currentUserId: 'driver_1',
      calibrationOwnerUserId: 'driver_1',
      historySource: TripTrackingCalibrationHistorySource.mapbox,
    );

    expect(firestore.status, TripTrackingCalibrationApplyStatus.rejected);
    expect(
      firestore.reasonCodes,
      contains('local_reviewed_odometer_history_required'),
    );
    expect(mapbox.canApplyToFutureGpsProjection, isFalse);
    expect(
      mapbox.reasonCodes,
      contains('local_reviewed_odometer_history_required'),
    );
  });

  test('calibration owner mismatch and fleet observer mode fail closed', () {
    final mismatch = TripTrackingCalibrationApplyGuard.evaluate(
      signal: _signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      currentUserId: 'manager_1',
      calibrationOwnerUserId: 'driver_1',
    );
    final shared = TripTrackingCalibrationApplyGuard.evaluate(
      signal: _signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      currentUserId: 'manager_1',
      calibrationOwnerUserId: 'driver_1',
      explicitSharedVehicleAccess: true,
    );
    final observer = TripTrackingCalibrationApplyGuard.evaluate(
      signal: _signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      currentUserId: 'manager_1',
      calibrationOwnerUserId: 'driver_1',
      explicitSharedVehicleAccess: true,
      fleetObserverMode: true,
    );

    expect(mismatch.status, TripTrackingCalibrationApplyStatus.rejected);
    expect(
      mismatch.reasonCodes,
      contains('calibration_owner_or_explicit_access_required'),
    );
    expect(
      shared.status,
      TripTrackingCalibrationApplyStatus.readyForFutureProjection,
    );
    expect(observer.status, TripTrackingCalibrationApplyStatus.rejected);
    expect(observer.reasonCodes, contains('fleet_observer_read_only'));
  });

  test('unsafe user ids are rejected without leaking tokens', () {
    final guard = TripTrackingCalibrationApplyGuard.evaluate(
      signal: _signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      currentUserId: 'pk.public-token',
      calibrationOwnerUserId: 'driver_1',
    );

    expect(guard.status, TripTrackingCalibrationApplyStatus.rejected);
    expect(guard.reasonCodes, contains('unsafe_current_user_id'));
    expect(guard.toSafeDashboardMap().toString(), isNot(contains('pk.')));
  });

  test('forged remote summary cannot claim calibration authority', () {
    final summary =
        TripTrackingCalibrationApplyGuard.evaluate(
          signal: _signal(),
          userOptedIn: true,
          userAcceptedLatestReview: true,
          minimumReviewedDays: 7,
          latestReviewedAtUtc: now,
          nowUtc: now,
        ).toSafeDashboardMap()..addAll({
          'firestoreCanApplyCalibration': true,
          'cloudFunctionCanApplyCalibration': true,
          'mapboxCanApplyCalibration': true,
          'dashboardCacheCanApplyCalibration': true,
          'remoteCalibrationCanOverrideLocalState': true,
          'remoteCalibrationCanEnableSetting': true,
          'remoteCalibrationCanResetPrompt': true,
          'mapboxCanTriggerTirePrompt': true,
          'gpsCanAutoApplyCalibration': true,
        });

    final validation =
        TripTrackingCalibrationApplySummaryValidation.fromSummary(summary);

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('remote_or_map_can_apply_calibration'));
    expect(validation.reasons, contains('remote_or_sensor_can_control_prompt'));
  });
}

TripOdometerCalibrationSignal _signal() {
  return const TripOdometerCalibrationSignal(
    status: TripOdometerCalibrationStatus.reviewRecommended,
    eligibleSampleCount: 7,
    trustedGpsWindowCount: 7,
    excludedPoorGpsDayCount: 0,
    averageGpsToOdometerRatio: .94,
    averageDifferencePercent: 6,
    reasonCode: 'persistent_gps_odometer_drift',
  );
}
