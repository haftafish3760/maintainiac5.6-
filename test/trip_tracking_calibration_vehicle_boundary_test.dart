import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_calibration_apply_guard.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_calibration.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18, 12);

  test(
    'vehicle-bound calibration matrix only allows clean same-vehicle history',
    () {
      final cases = <_VehicleCalibrationCase>[
        _VehicleCalibrationCase(
          name: 'same vehicle accepted',
          activeVehicleId: 'van_1',
          reviewedVehicleId: 'van_1',
          reviewedVehicleIds: const ['van_1'],
          expectedStatus:
              TripTrackingCalibrationApplyStatus.readyForFutureProjection,
          expectedReason: 'calibration_review_accepted_future_projection_only',
          canApply: true,
        ),
        _VehicleCalibrationCase(
          name: 'mixed vehicle history rejected',
          activeVehicleId: 'van_1',
          reviewedVehicleId: null,
          reviewedVehicleIds: const ['van_1', 'truck_2'],
          expectedStatus: TripTrackingCalibrationApplyStatus.rejected,
          expectedReason: 'mixed_vehicle_calibration_history',
          canApply: false,
        ),
        _VehicleCalibrationCase(
          name: 'review vehicle mismatch rejected',
          activeVehicleId: 'van_1',
          reviewedVehicleId: 'truck_2',
          reviewedVehicleIds: const [],
          expectedStatus: TripTrackingCalibrationApplyStatus.rejected,
          expectedReason: 'calibration_vehicle_mismatch',
          canApply: false,
        ),
        _VehicleCalibrationCase(
          name: 'reviewed set mismatch rejected',
          activeVehicleId: 'van_1',
          reviewedVehicleId: null,
          reviewedVehicleIds: const ['truck_2'],
          expectedStatus: TripTrackingCalibrationApplyStatus.rejected,
          expectedReason: 'calibration_vehicle_mismatch',
          canApply: false,
        ),
        _VehicleCalibrationCase(
          name: 'unsafe active vehicle id rejected',
          activeVehicleId: 'van/../1',
          reviewedVehicleId: 'van_1',
          reviewedVehicleIds: const ['van_1'],
          expectedStatus: TripTrackingCalibrationApplyStatus.rejected,
          expectedReason: 'unsafe_active_vehicle_id',
          canApply: false,
        ),
        _VehicleCalibrationCase(
          name: 'unsafe reviewed vehicle id rejected',
          activeVehicleId: 'van_1',
          reviewedVehicleId: 'truck/../2',
          reviewedVehicleIds: const ['van_1'],
          expectedStatus: TripTrackingCalibrationApplyStatus.rejected,
          expectedReason: 'unsafe_reviewed_vehicle_id',
          canApply: false,
        ),
      ];

      for (final entry in cases) {
        final guard = TripTrackingCalibrationApplyGuard.evaluate(
          signal: _signal(),
          userOptedIn: true,
          userAcceptedLatestReview: true,
          minimumReviewedDays: 7,
          latestReviewedAtUtc: now,
          nowUtc: now,
          activeVehicleId: entry.activeVehicleId,
          reviewedVehicleId: entry.reviewedVehicleId,
          reviewedVehicleIds: entry.reviewedVehicleIds,
        );
        final safe = guard.toSafeDashboardMap();

        expect(guard.status, entry.expectedStatus, reason: entry.name);
        expect(
          guard.reasonCodes,
          contains(entry.expectedReason),
          reason: entry.name,
        );
        expect(
          guard.canApplyToFutureGpsProjection,
          entry.canApply,
          reason: entry.name,
        );
        expect(safe['calibrationRequiresSingleVehicleHistory'], isTrue);
        expect(safe['calibrationCanApplyAcrossVehicles'], isFalse);
        expect(safe['calibrationVehicleIdIncluded'], isFalse);
        expect(safe['rawVehicleIdsIncluded'], isFalse);
        expect(safe['canRewriteConfirmedOdometer'], isFalse);
        expect(safe['calibrationCanMutateTripLog'], isFalse);
        expect(safe['mapboxRouteDistanceCanBecomeOfficial'], isFalse);
        expect(safe.toString(), isNot(contains('van_1')));
        expect(safe.toString(), isNot(contains('truck_2')));
      }
    },
  );

  test('vehicle boundary still honors opt-in and review acceptance gates', () {
    final disabled = TripTrackingCalibrationApplyGuard.evaluate(
      signal: _signal(),
      userOptedIn: false,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      activeVehicleId: 'van_1',
      reviewedVehicleId: 'van_1',
      reviewedVehicleIds: const ['van_1'],
    );
    final reviewRequired = TripTrackingCalibrationApplyGuard.evaluate(
      signal: _signal(),
      userOptedIn: true,
      userAcceptedLatestReview: false,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      activeVehicleId: 'van_1',
      reviewedVehicleId: 'van_1',
      reviewedVehicleIds: const ['van_1'],
    );
    final waiting = TripTrackingCalibrationApplyGuard.evaluate(
      signal: _signal(
        status: TripOdometerCalibrationStatus.insufficientHistory,
        samples: 3,
        reason: 'needs_more_reviewed_days',
      ),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      activeVehicleId: 'van_1',
      reviewedVehicleId: 'van_1',
      reviewedVehicleIds: const ['van_1'],
    );

    expect(disabled.status, TripTrackingCalibrationApplyStatus.disabled);
    expect(disabled.reasonCodes, contains('calibration_user_opt_in_required'));
    expect(
      reviewRequired.status,
      TripTrackingCalibrationApplyStatus.reviewRequired,
    );
    expect(
      reviewRequired.reasonCodes,
      contains('user_must_accept_calibration_review'),
    );
    expect(
      waiting.status,
      TripTrackingCalibrationApplyStatus.waitingForHistory,
    );
    expect(
      waiting.reasonCodes,
      contains('more_reviewed_odometer_days_required'),
    );
    expect(disabled.multiplier, 1);
    expect(reviewRequired.multiplier, 1);
    expect(waiting.multiplier, 1);
  });

  test(
    'vehicle boundary summary validation rejects leaked ids and authority',
    () {
      final safe = TripTrackingCalibrationApplyGuard.evaluate(
        signal: _signal(),
        userOptedIn: true,
        userAcceptedLatestReview: true,
        minimumReviewedDays: 7,
        latestReviewedAtUtc: now,
        nowUtc: now,
        activeVehicleId: 'van_1',
        reviewedVehicleId: 'van_1',
        reviewedVehicleIds: const ['van_1'],
      ).toSafeDashboardMap();

      final validation =
          TripTrackingCalibrationApplySummaryValidation.fromSummary({
            ...safe,
            'calibrationCanApplyAcrossVehicles': true,
            'calibrationRequiresSingleVehicleHistory': false,
            'calibrationVehicleIdIncluded': true,
            'rawVehicleIdsIncluded': true,
            'debugVehicleId': 'van_1',
            'debug': '35.123456,-80.123456 sk.redacted',
          });

      expect(validation.isRenderable, isFalse);
      expect(validation.reasons, contains('calibration_can_mutate_trip_truth'));
      expect(
        validation.reasons,
        contains('summary_contains_sensitive_calibration_material'),
      );
      expect(validation.reasons, contains('summary_contains_sensitive_text'));
    },
  );
}

TripOdometerCalibrationSignal _signal({
  TripOdometerCalibrationStatus status =
      TripOdometerCalibrationStatus.reviewRecommended,
  int samples = 7,
  String reason = 'persistent_gps_odometer_drift',
}) {
  return TripOdometerCalibrationSignal(
    status: status,
    eligibleSampleCount: samples,
    averageGpsToOdometerRatio: .94,
    averageDifferencePercent: 6,
    reasonCode: reason,
  );
}

class _VehicleCalibrationCase {
  const _VehicleCalibrationCase({
    required this.name,
    required this.activeVehicleId,
    required this.reviewedVehicleId,
    required this.reviewedVehicleIds,
    required this.expectedStatus,
    required this.expectedReason,
    required this.canApply,
  });

  final String name;
  final String? activeVehicleId;
  final String? reviewedVehicleId;
  final List<String> reviewedVehicleIds;
  final TripTrackingCalibrationApplyStatus expectedStatus;
  final String expectedReason;
  final bool canApply;
}
