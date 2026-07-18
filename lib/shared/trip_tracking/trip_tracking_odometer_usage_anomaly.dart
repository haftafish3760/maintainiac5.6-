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
    required this.ignoredHistoryRecordCount,
    required this.anomalyAlertsEnabled,
    required this.reasonCode,
  });

  final TripOdometerUsageAnomalyStatus status;
  final int reviewedDayCount;
  final double currentOdometerMiles;
  final double averageDailyMiles;
  final double reviewThresholdMiles;
  final int ignoredHistoryRecordCount;
  final bool anomalyAlertsEnabled;
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
    'ignoredHistoryRecordCount': ignoredHistoryRecordCount < 0
        ? 0
        : ignoredHistoryRecordCount,
    'currentOdometerMiles': _safeRoundedMiles(currentOdometerMiles),
    'averageDailyMiles': _safeRoundedMiles(averageDailyMiles),
    'reviewThresholdMiles': _safeRoundedMiles(reviewThresholdMiles),
    'reasonCode': _safeUsageReason(reasonCode),
    'shouldPromptUser': shouldPromptUser,
    'canAutoCorrectOdometer': false,
    'anomalyAlertsEnabled': anomalyAlertsEnabled,
    'manualReviewRequiredBeforeChange': shouldPromptUser,
    'odometerRemainsCanonical': true,
    'odometerIsGlobalTruth': true,
    'gpsCanReplaceOdometer': false,
    'gpsCanSetGlobalTruth': false,
    'gpsCanChangeOfficialMileage': false,
    'mapboxCanReplaceOdometer': false,
    'mapboxCanSetGlobalTruth': false,
    'mapboxCanChangeOfficialMileage': false,
    'remoteTotalsCanReplaceOdometer': false,
    'remoteTotalsCanSetGlobalTruth': false,
    'remoteTotalsCanChangeOfficialMileage': false,
    'firestoreCanCreateUsageAnomaly': false,
    'mapboxCanCreateUsageAnomaly': false,
    'usageAnomalyCanBlockWithoutUserReview': false,
    'anomalyAlertsRequireUserOptIn': true,
    'calibrationAssistRequiresUserOptIn': true,
    'calibrationRequiresMultipleReviewedTrips': true,
    'calibrationCanAutoRewriteConfirmedOdometer': false,
    'calibrationCanBypassVehicleProfile': false,
    'usageAnomalyCanApplyCalibration': false,
    'usageAnomalyCanPurgeLocalDataAfterBackup': false,
    'confirmedHistoryOnly': true,
    'futureConfirmationsIgnored': true,
    'rawHistoryIncluded': false,
    'rawTripRecordsIncluded': false,
    'rawLocationIncluded': false,
    'tokensIncluded': false,
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
    int maximumHistoryRecords = 366,
    bool anomalyAlertsEnabled = true,
  }) {
    if (!currentOdometerMiles.isFinite ||
        currentOdometerMiles < 0 ||
        minimumReviewedDays <= 0 ||
        !reviewMultiplier.isFinite ||
        reviewMultiplier < 1 ||
        !minimumReviewBufferMiles.isFinite ||
        minimumReviewBufferMiles < 0 ||
        !maximumTrustedReviewedDayMiles.isFinite ||
        maximumTrustedReviewedDayMiles <= 0 ||
        maximumHistoryRecords <= 0) {
      return TripOdometerUsageAnomalySignal(
        status: TripOdometerUsageAnomalyStatus.invalid,
        reviewedDayCount: 0,
        currentOdometerMiles: 0,
        averageDailyMiles: 0,
        reviewThresholdMiles: 0,
        ignoredHistoryRecordCount: 0,
        anomalyAlertsEnabled: anomalyAlertsEnabled,
        reasonCode: 'invalid_usage_anomaly_input',
      );
    }

    if (!anomalyAlertsEnabled) {
      return TripOdometerUsageAnomalySignal(
        status: TripOdometerUsageAnomalyStatus.normal,
        reviewedDayCount: 0,
        currentOdometerMiles: currentOdometerMiles,
        averageDailyMiles: 0,
        reviewThresholdMiles: 0,
        ignoredHistoryRecordCount: 0,
        anomalyAlertsEnabled: false,
        reasonCode: 'odometer_anomaly_alerts_disabled',
      );
    }

    final requestedVehicleId = vehicleId?.trim();
    final trustedNowUtc = nowUtc?.toUtc();
    final dailyMiles = <String, double>{};
    var inspectedRecords = 0;
    var ignoredRecords = 0;
    for (final review in history) {
      if (inspectedRecords >= maximumHistoryRecords) {
        ignoredRecords += 1;
        continue;
      }
      inspectedRecords += 1;
      if (!review.isOdometerConfirmed ||
          !review.hasValidTimeline ||
          (trustedNowUtc != null &&
              review.odometerConfirmedAt!.toUtc().isAfter(trustedNowUtc))) {
        ignoredRecords += 1;
        continue;
      }
      final reviewVehicleId = review.vehicleId.trim();
      if (reviewVehicleId.isEmpty ||
          (requestedVehicleId != null &&
              requestedVehicleId.isNotEmpty &&
              reviewVehicleId != requestedVehicleId)) {
        ignoredRecords += 1;
        continue;
      }
      final miles = (review.confirmedEndingOdometer! - review.startingOdometer)
          .toDouble();
      if (!miles.isFinite ||
          miles < 0 ||
          miles > maximumTrustedReviewedDayMiles) {
        ignoredRecords += 1;
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
        ignoredHistoryRecordCount: ignoredRecords,
        anomalyAlertsEnabled: true,
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
      ignoredHistoryRecordCount: ignoredRecords,
      anomalyAlertsEnabled: true,
      reasonCode: shouldReviewHigh
          ? 'unusually_high_odometer_delta'
          : shouldReviewLow
          ? 'unusually_low_odometer_delta'
          : 'odometer_usage_within_review_threshold',
    );
  }
}

class TripOdometerUsageAnomalySummaryValidation {
  const TripOdometerUsageAnomalySummaryValidation._({
    required this.isRenderable,
    required this.status,
    required this.reasons,
  });

  factory TripOdometerUsageAnomalySummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final status = _safeStatus(summary['status']);
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (status == null) reasons.add('invalid_usage_anomaly_status');
    if (_safeUsageReasonObject(summary['reasonCode']) == null) {
      reasons.add('invalid_usage_anomaly_reason');
    }
    for (final key in const [
      'reviewedDayCount',
      'ignoredHistoryRecordCount',
      'currentOdometerMiles',
      'averageDailyMiles',
      'reviewThresholdMiles',
    ]) {
      final value = summary[key];
      if (value is! num || !value.isFinite || value < 0) {
        reasons.add('invalid_$key');
      }
    }
    if (summary['shouldPromptUser'] == true &&
        status != TripOdometerUsageAnomalyStatus.reviewRecommended) {
      reasons.add('unsafe_prompt_claim');
    }
    if (summary['canAutoCorrectOdometer'] != false ||
        summary['manualReviewRequiredBeforeChange'] !=
            (summary['shouldPromptUser'] == true) ||
        summary['odometerRemainsCanonical'] != true ||
        summary['odometerIsGlobalTruth'] != true ||
        summary['gpsCanReplaceOdometer'] != false ||
        summary['gpsCanSetGlobalTruth'] != false ||
        summary['gpsCanChangeOfficialMileage'] != false ||
        summary['mapboxCanReplaceOdometer'] != false ||
        summary['mapboxCanSetGlobalTruth'] != false ||
        summary['mapboxCanChangeOfficialMileage'] != false ||
        summary['remoteTotalsCanReplaceOdometer'] != false ||
        summary['remoteTotalsCanSetGlobalTruth'] != false ||
        summary['remoteTotalsCanChangeOfficialMileage'] != false ||
        summary['usageAnomalyCanBlockWithoutUserReview'] != false) {
      reasons.add('usage_anomaly_can_mutate_odometer_truth');
    }
    if (summary['firestoreCanCreateUsageAnomaly'] != false ||
        summary['mapboxCanCreateUsageAnomaly'] != false) {
      reasons.add('remote_or_map_can_create_anomaly');
    }
    if (summary['anomalyAlertsRequireUserOptIn'] != true ||
        summary['calibrationAssistRequiresUserOptIn'] != true ||
        summary['calibrationRequiresMultipleReviewedTrips'] != true ||
        summary['calibrationCanAutoRewriteConfirmedOdometer'] != false ||
        summary['calibrationCanBypassVehicleProfile'] != false ||
        summary['usageAnomalyCanApplyCalibration'] != false ||
        summary['usageAnomalyCanPurgeLocalDataAfterBackup'] != false) {
      reasons.add('calibration_anomaly_boundary_missing');
    }
    if (summary['confirmedHistoryOnly'] != true ||
        summary['futureConfirmationsIgnored'] != true) {
      reasons.add('history_validation_boundary_missing');
    }
    if (summary['rawHistoryIncluded'] != false ||
        summary['rawTripRecordsIncluded'] != false ||
        summary['rawLocationIncluded'] != false ||
        summary['tokensIncluded'] != false) {
      reasons.add('summary_contains_sensitive_anomaly_material');
    }
    if (summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_text');
    }

    return TripOdometerUsageAnomalySummaryValidation._(
      isRenderable: reasons.isEmpty,
      status: reasons.isEmpty ? status : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final TripOdometerUsageAnomalyStatus? status;
  final List<String> reasons;
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
    'odometer_anomaly_alerts_disabled' => value,
    'unusually_high_odometer_delta' => value,
    'unusually_low_odometer_delta' => value,
    'odometer_usage_within_review_threshold' => value,
    _ => 'invalid_usage_anomaly_input',
  };
}

TripOdometerUsageAnomalyStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripOdometerUsageAnomalyStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

String? _safeUsageReasonObject(Object? value) {
  if (value is! String) return null;
  return _safeUsageReason(value);
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
