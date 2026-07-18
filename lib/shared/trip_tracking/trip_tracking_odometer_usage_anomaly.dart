import 'dart:math' as math;

import 'trip_tracking_session_store.dart';

enum TripOdometerUsageAnomalyStatus {
  invalid,
  insufficientHistory,
  normal,
  reviewRecommended,
}

class TripOdometerUsageAnomalySignal {
  const TripOdometerUsageAnomalySignal({
    required this.status,
    required this.reviewedDayCount,
    required this.currentOdometerMiles,
    required this.averageDailyMiles,
    required this.reviewThresholdMiles,
    required this.reasonCode,
  });

  final TripOdometerUsageAnomalyStatus status;
  final int reviewedDayCount;
  final double currentOdometerMiles;
  final double averageDailyMiles;
  final double reviewThresholdMiles;
  final String reasonCode;

  /// This signal can prompt a driver to review a surprising mileage entry, but
  /// it must never rewrite the confirmed odometer or TripLog on its own.
  bool get canAutoCorrectOdometer => false;

  bool get shouldPromptUser =>
      status == TripOdometerUsageAnomalyStatus.reviewRecommended;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reviewedDayCount': reviewedDayCount < 0 ? 0 : reviewedDayCount,
    'currentOdometerMiles': _safeRoundedMiles(currentOdometerMiles),
    'averageDailyMiles': _safeRoundedMiles(averageDailyMiles),
    'reviewThresholdMiles': _safeRoundedMiles(reviewThresholdMiles),
    'reasonCode': _safeUsageReason(reasonCode),
    'shouldPromptUser': shouldPromptUser,
    'canAutoCorrectOdometer': false,
    'manualReviewRequiredBeforeChange': shouldPromptUser,
    'odometerRemainsCanonical': true,
    'gpsCanReplaceOdometer': false,
    'mapboxCanReplaceOdometer': false,
    'remoteTotalsCanReplaceOdometer': false,
    'anomalyAlertsRequireUserOptIn': true,
    'calibrationAssistRequiresUserOptIn': true,
    'calibrationRequiresMultipleReviewedTrips': true,
    'calibrationCanAutoRewriteConfirmedOdometer': false,
    'confirmedHistoryOnly': true,
    'futureConfirmationsIgnored': true,
    'rawHistoryIncluded': false,
    'rawTripRecordsIncluded': false,
    'rawLocationIncluded': false,
  };

  static TripOdometerUsageAnomalySignal evaluate({
    required double currentOdometerMiles,
    required Iterable<TripTrackingReviewRecord> history,
    String? vehicleId,
    DateTime? nowUtc,
    int minimumReviewedDays = 7,
    double reviewMultiplier = 2.5,
    double minimumReviewBufferMiles = 50,
    double maximumTrustedReviewedDayMiles = 1200,
  }) {
    if (!currentOdometerMiles.isFinite ||
        currentOdometerMiles < 0 ||
        minimumReviewedDays <= 0 ||
        !reviewMultiplier.isFinite ||
        reviewMultiplier < 1 ||
        !minimumReviewBufferMiles.isFinite ||
        minimumReviewBufferMiles < 0 ||
        !maximumTrustedReviewedDayMiles.isFinite ||
        maximumTrustedReviewedDayMiles <= 0) {
      return const TripOdometerUsageAnomalySignal(
        status: TripOdometerUsageAnomalyStatus.invalid,
        reviewedDayCount: 0,
        currentOdometerMiles: 0,
        averageDailyMiles: 0,
        reviewThresholdMiles: 0,
        reasonCode: 'invalid_usage_anomaly_input',
      );
    }

    final requestedVehicleId = vehicleId?.trim();
    final trustedNowUtc = nowUtc?.toUtc();
    final dailyMiles = <String, double>{};
    for (final review in history) {
      if (!review.isOdometerConfirmed ||
          !review.hasValidTimeline ||
          (trustedNowUtc != null &&
              review.odometerConfirmedAt!.toUtc().isAfter(trustedNowUtc))) {
        continue;
      }
      final reviewVehicleId = review.vehicleId.trim();
      if (reviewVehicleId.isEmpty ||
          (requestedVehicleId != null &&
              requestedVehicleId.isNotEmpty &&
              reviewVehicleId != requestedVehicleId)) {
        continue;
      }
      final miles = (review.confirmedEndingOdometer! - review.startingOdometer)
          .toDouble();
      if (!miles.isFinite ||
          miles < 0 ||
          miles > maximumTrustedReviewedDayMiles) {
        continue;
      }
      final dayKey = _usageDayKey(review.startedAt.toUtc());
      dailyMiles.update(
        dayKey,
        (value) => value + miles,
        ifAbsent: () => miles,
      );
    }

    if (dailyMiles.length < minimumReviewedDays) {
      return TripOdometerUsageAnomalySignal(
        status: TripOdometerUsageAnomalyStatus.insufficientHistory,
        reviewedDayCount: dailyMiles.length,
        currentOdometerMiles: currentOdometerMiles,
        averageDailyMiles: 0,
        reviewThresholdMiles: 0,
        reasonCode: 'needs_more_reviewed_days_for_usage_anomaly',
      );
    }

    final totalMiles = dailyMiles.values.fold<double>(
      0,
      (sum, miles) => sum + miles,
    );
    final average = totalMiles / dailyMiles.length;
    final threshold = math.max(
      average * reviewMultiplier,
      average + minimumReviewBufferMiles,
    );
    final lowThreshold = _lowUsageReviewThreshold(
      averageDailyMiles: average,
      reviewMultiplier: reviewMultiplier,
      minimumReviewBufferMiles: minimumReviewBufferMiles,
    );
    final shouldReviewHigh = currentOdometerMiles > threshold;
    final shouldReviewLow = currentOdometerMiles < lowThreshold;
    return TripOdometerUsageAnomalySignal(
      status: shouldReviewHigh || shouldReviewLow
          ? TripOdometerUsageAnomalyStatus.reviewRecommended
          : TripOdometerUsageAnomalyStatus.normal,
      reviewedDayCount: dailyMiles.length,
      currentOdometerMiles: currentOdometerMiles,
      averageDailyMiles: average,
      reviewThresholdMiles: shouldReviewLow ? lowThreshold : threshold,
      reasonCode: shouldReviewHigh
          ? 'unusually_high_odometer_delta'
          : shouldReviewLow
          ? 'unusually_low_odometer_delta'
          : 'odometer_usage_within_review_threshold',
    );
  }
}

double _lowUsageReviewThreshold({
  required double averageDailyMiles,
  required double reviewMultiplier,
  required double minimumReviewBufferMiles,
}) {
  if (averageDailyMiles <= minimumReviewBufferMiles) return 0;
  return math
      .min(
        averageDailyMiles / reviewMultiplier,
        averageDailyMiles - minimumReviewBufferMiles,
      )
      .clamp(0, double.infinity)
      .toDouble();
}

String _usageDayKey(DateTime utc) =>
    '${utc.year.toString().padLeft(4, '0')}-'
    '${utc.month.toString().padLeft(2, '0')}-'
    '${utc.day.toString().padLeft(2, '0')}';

double _safeRoundedMiles(double value) {
  if (!value.isFinite || value < 0) return 0;
  return double.parse(value.toStringAsFixed(1));
}

String _safeUsageReason(String value) {
  return switch (value) {
    'invalid_usage_anomaly_input' => value,
    'needs_more_reviewed_days_for_usage_anomaly' => value,
    'unusually_high_odometer_delta' => value,
    'unusually_low_odometer_delta' => value,
    'odometer_usage_within_review_threshold' => value,
    _ => 'invalid_usage_anomaly_input',
  };
}
