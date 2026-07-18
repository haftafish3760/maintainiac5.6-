import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_calibration_apply_guard.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_calibration.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18, 12);

  test(
    'calibration signal exposes trusted and excluded GPS evidence counts',
    () {
      const signal = TripOdometerCalibrationSignal(
        status: TripOdometerCalibrationStatus.reviewRecommended,
        eligibleSampleCount: 7,
        trustedGpsWindowCount: 7,
        excludedPoorGpsDayCount: 2,
        averageGpsToOdometerRatio: .94,
        averageDifferencePercent: 6,
        reasonCode: 'persistent_gps_odometer_drift',
      );

      final safe = signal.toSafeDashboardMap();

      expect(safe['trustedGpsWindowCount'], 7);
      expect(safe['excludedPoorGpsDayCount'], 2);
      expect(safe['poorGpsDaysExcludedFromCalibration'], isTrue);
      expect(safe['calibrationRequiresTrustedGpsWindow'], isTrue);
      expect(safe['odometerIsGlobalTruth'], isTrue);
    },
  );

  test(
    'apply guard preserves evidence counts without granting odometer truth',
    () {
      const signal = TripOdometerCalibrationSignal(
        status: TripOdometerCalibrationStatus.reviewRecommended,
        eligibleSampleCount: 7,
        trustedGpsWindowCount: 7,
        excludedPoorGpsDayCount: 2,
        averageGpsToOdometerRatio: .94,
        averageDifferencePercent: 6,
        reasonCode: 'persistent_gps_odometer_drift',
      );

      final guard = TripTrackingCalibrationApplyGuard.evaluate(
        signal: signal,
        userOptedIn: true,
        userAcceptedLatestReview: true,
        minimumReviewedDays: 7,
        latestReviewedAtUtc: now,
        nowUtc: now,
        activeVehicleId: 'vehicle_1',
        reviewedVehicleId: 'vehicle_1',
        reviewedVehicleIds: const ['vehicle_1'],
      );
      final safe = guard.toSafeDashboardMap();

      expect(guard.canApplyToFutureGpsProjection, isTrue);
      expect(safe['trustedGpsWindowCount'], 7);
      expect(safe['excludedPoorGpsDayCount'], 2);
      expect(safe['excludedPoorGpsDayCountIncluded'], isTrue);
      expect(safe['poorGpsExcludedDayCountTrustedAfterValidationOnly'], isTrue);
      expect(safe['calibrationCanMutateTripLog'], isFalse);
      expect(safe['canRewriteConfirmedOdometer'], isFalse);
      expect(safe['odometerIsGlobalTruth'], isTrue);
    },
  );

  test('apply summary validation rejects forged evidence counters', () {
    final safe = TripTrackingCalibrationApplyGuard.evaluate(
      signal: const TripOdometerCalibrationSignal(
        status: TripOdometerCalibrationStatus.reviewRecommended,
        eligibleSampleCount: 7,
        trustedGpsWindowCount: 7,
        excludedPoorGpsDayCount: 2,
        averageGpsToOdometerRatio: .94,
        averageDifferencePercent: 6,
        reasonCode: 'persistent_gps_odometer_drift',
      ),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      activeVehicleId: 'vehicle_1',
      reviewedVehicleId: 'vehicle_1',
      reviewedVehicleIds: const ['vehicle_1'],
    ).toSafeDashboardMap();

    final validation =
        TripTrackingCalibrationApplySummaryValidation.fromSummary(
          safe..addAll({
            'trustedGpsWindowCount': 999,
            'excludedPoorGpsDayCount': -1,
            'canRewriteConfirmedOdometer': true,
          }),
        );

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('invalid_trusted_gps_window_count'));
    expect(validation.reasons, contains('invalid_excluded_poor_gps_day_count'));
    expect(validation.reasons, contains('calibration_can_mutate_trip_truth'));
  });
}
