import 'trip_tracking_calibration_state.dart';
import 'trip_tracking_odometer_calibration.dart';

enum TripTrackingCalibrationApplyStatus {
  disabled,
  waitingForHistory,
  reviewRequired,
  readyForFutureProjection,
  rejected,
}

class TripTrackingCalibrationApplyGuard {
  const TripTrackingCalibrationApplyGuard._({
    required this.status,
    required this.multiplier,
    required this.reasonCodes,
  });

  factory TripTrackingCalibrationApplyGuard.evaluate({
    required TripOdometerCalibrationSignal signal,
    required bool userOptedIn,
    required bool userAcceptedLatestReview,
    required int minimumReviewedDays,
    required DateTime? latestReviewedAtUtc,
    required DateTime nowUtc,
    Duration maximumCalibrationReviewAge = const Duration(days: 30),
  }) {
    final reasons = <String>[];
    final now = nowUtc.toUtc();
    final latestReviewed = latestReviewedAtUtc?.toUtc();
    if (minimumReviewedDays <= 0) reasons.add('invalid_minimum_reviewed_days');
    if (signal.eligibleSampleCount < 0) reasons.add('negative_sample_count');
    if (signal.eligibleSampleCount > 366) reasons.add('excessive_sample_count');
    if (!signal.averageGpsToOdometerRatio.isFinite ||
        signal.averageGpsToOdometerRatio <= 0) {
      reasons.add('invalid_gps_odometer_ratio');
    }
    if (!signal.averageDifferencePercent.isFinite ||
        signal.averageDifferencePercent < 0) {
      reasons.add('invalid_difference_percent');
    }
    if (_safeReason(signal.reasonCode) == 'unknown_calibration_state') {
      reasons.add('unknown_signal_reason');
    }
    if (latestReviewed != null && latestReviewed.isAfter(now)) {
      reasons.add('future_review_timestamp');
    }
    if (signal.status == TripOdometerCalibrationStatus.reviewRecommended &&
        latestReviewed == null) {
      reasons.add('missing_latest_review_timestamp');
    }
    if (latestReviewed != null &&
        latestReviewed.isBefore(
          now.subtract(_safeReviewAge(maximumCalibrationReviewAge)),
        )) {
      reasons.add('stale_review_timestamp');
    }
    if (reasons.isNotEmpty) {
      return TripTrackingCalibrationApplyGuard._(
        status: TripTrackingCalibrationApplyStatus.rejected,
        multiplier: 1,
        reasonCodes: List.unmodifiable(reasons),
      );
    }
    if (!userOptedIn) {
      return const TripTrackingCalibrationApplyGuard._(
        status: TripTrackingCalibrationApplyStatus.disabled,
        multiplier: 1,
        reasonCodes: ['calibration_user_opt_in_required'],
      );
    }
    if (signal.eligibleSampleCount < minimumReviewedDays ||
        signal.status == TripOdometerCalibrationStatus.insufficientHistory) {
      return const TripTrackingCalibrationApplyGuard._(
        status: TripTrackingCalibrationApplyStatus.waitingForHistory,
        multiplier: 1,
        reasonCodes: ['more_reviewed_odometer_days_required'],
      );
    }
    if (signal.status == TripOdometerCalibrationStatus.reviewRecommended &&
        !userAcceptedLatestReview) {
      return const TripTrackingCalibrationApplyGuard._(
        status: TripTrackingCalibrationApplyStatus.reviewRequired,
        multiplier: 1,
        reasonCodes: ['user_must_accept_calibration_review'],
      );
    }
    if (signal.status == TripOdometerCalibrationStatus.stable) {
      return const TripTrackingCalibrationApplyGuard._(
        status: TripTrackingCalibrationApplyStatus.readyForFutureProjection,
        multiplier: 1,
        reasonCodes: ['calibration_stable_neutral_multiplier'],
      );
    }
    return TripTrackingCalibrationApplyGuard._(
      status: TripTrackingCalibrationApplyStatus.readyForFutureProjection,
      multiplier: TripTrackingCalibrationState.safeMultiplier(
        signal.gpsAssistanceCalibrationMultiplier,
      ),
      reasonCodes: const ['calibration_review_accepted_future_projection_only'],
    );
  }

  final TripTrackingCalibrationApplyStatus status;
  final double multiplier;
  final List<String> reasonCodes;

  bool get canApplyToFutureGpsProjection =>
      status == TripTrackingCalibrationApplyStatus.readyForFutureProjection;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'multiplier': _safeRoundedMultiplier(multiplier),
    'reasonCodes': reasonCodes,
    'canApplyToFutureGpsProjection': canApplyToFutureGpsProjection,
    'appliesToPastTrips': false,
    'canRewriteConfirmedOdometer': false,
    'canApplySilently': false,
    'userOptInRequired': true,
    'reviewAcceptanceRequired': true,
    'requiresMultipleReviewedOdometerDays': true,
    'latestReviewTimestampRequired': true,
    'staleCalibrationReviewRejected': true,
    'excessiveHistoryCountRejected': true,
    'tireOrSpeedometerReviewIsAdvisory': true,
    'odometerRemainsCanonical': true,
    'gpsEstimateRemainsNonCanonical': true,
    'remoteCalibrationCanOverrideLocalState': false,
    'firestoreCanApplyCalibration': false,
    'mapboxCanApplyCalibration': false,
    'cloudFunctionCanApplyCalibration': false,
    'rawReviewedTripsIncluded': false,
    'rawGpsIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'invalid_calibration_threshold' => value.trim(),
    'needs_more_reviewed_days' => value.trim(),
    'mixed_vehicle_calibration_history' => value.trim(),
    'persistent_gps_odometer_drift' => value.trim(),
    'calibration_stable' => value.trim(),
    _ => 'unknown_calibration_state',
  };
}

double _safeRoundedMultiplier(double value) {
  final safe = TripTrackingCalibrationState.safeMultiplier(value);
  return double.parse(safe.toStringAsFixed(4));
}

Duration _safeReviewAge(Duration value) {
  if (value <= Duration.zero) return const Duration(days: 1);
  return value > const Duration(days: 90) ? const Duration(days: 90) : value;
}
