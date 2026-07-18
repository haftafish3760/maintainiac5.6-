import 'trip_tracking_odometer_reconciliation.dart';
import 'trip_tracking_session_store.dart';

enum TripOdometerCalibrationStatus {
  insufficientHistory,
  stable,
  reviewRecommended,
}

class TripOdometerCalibrationSignal {
  const TripOdometerCalibrationSignal({
    required this.status,
    required this.eligibleSampleCount,
    required this.averageGpsToOdometerRatio,
    required this.averageDifferencePercent,
    required this.reasonCode,
  });

  final TripOdometerCalibrationStatus status;
  final int eligibleSampleCount;
  final double averageGpsToOdometerRatio;
  final double averageDifferencePercent;
  final String reasonCode;

  bool get canOverwriteConfirmedOdometer => false;

  bool get shouldPromptUser =>
      status == TripOdometerCalibrationStatus.reviewRecommended;

  bool get maySuggestTireOrSpeedometerReview =>
      shouldPromptUser &&
      averageDifferencePercent.isFinite &&
      averageDifferencePercent >= 4;

  String get userReviewPrompt {
    if (!maySuggestTireOrSpeedometerReview) return '';
    final direction = averageGpsToOdometerRatio > 1
        ? 'higher than'
        : 'lower than';
    return 'GPS-assisted mileage has been consistently $direction your confirmed odometer mileage across $eligibleSampleCount reviewed driving days. Review tire size, speedometer calibration, or GPS settings before applying any advisory calibration.';
  }

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'eligibleSampleCount': eligibleSampleCount < 0 ? 0 : eligibleSampleCount,
    'averageDifferencePercent': _safeRoundedPercent(averageDifferencePercent),
    'reasonCode': _safeCalibrationReason(reasonCode),
    'shouldPromptUser': _safeCalibrationShouldPrompt(
      status: status,
      reasonCode: reasonCode,
    ),
    'maySuggestTireOrSpeedometerReview':
        _safeCalibrationShouldPrompt(status: status, reasonCode: reasonCode) &&
        maySuggestTireOrSpeedometerReview,
    'tireSizeReviewSuggested':
        _safeCalibrationShouldPrompt(status: status, reasonCode: reasonCode) &&
        maySuggestTireOrSpeedometerReview,
    'speedometerCalibrationReviewSuggested':
        _safeCalibrationShouldPrompt(status: status, reasonCode: reasonCode) &&
        maySuggestTireOrSpeedometerReview,
    'canOverwriteConfirmedOdometer': false,
    'calibrationRequiresUserOptIn': true,
    'calibrationRequiresMultipleReviewedTrips': true,
    'continuousCalibrationAverageRequired': true,
    'singleDayCalibrationRejected': true,
    'calibrationRequiresVehicleScopedHistory': true,
    'calibrationCanRewritePastTrips': false,
    'canApplySilently': false,
    'gpsAssistCanOnlyScaleFutureProjectionAfterOptIn': true,
    'calibrationCanChangeDisplayedConfirmedMiles': false,
    'calibrationCanMutateTripLog': false,
    'calibrationCanLowerConfirmedOdometer': false,
    'calibrationCanCreateMaintenanceRecord': false,
    'mapboxRouteDistanceCanBecomeOfficial': false,
    'calibrationTrustedAfterReviewedHistoryOnly': true,
    'remoteHistoryCanCreateCalibration': false,
    'remoteCalibrationCanApplySilently': false,
    'remoteCalibrationCanEnableSetting': false,
    'remoteCalibrationCanResetPrompt': false,
    'firestoreCanOverrideCalibration': false,
    'mapboxRouteCanCreateCalibration': false,
    'mapboxCanOverrideCalibration': false,
    'mapboxCanTriggerTirePrompt': false,
    'gpsCanAutoApplyCalibration': false,
    'gpsAssistanceCalibrationMultiplier': _safeRoundedMultiplier(
      gpsAssistanceCalibrationMultiplier,
    ),
    'odometerRemainsCanonical': true,
    'gpsAssistAdvisoryOnly': true,
    'mapboxAssistAdvisoryOnly': true,
    'rawReviewedTripsIncluded': false,
    'rawLocationIncluded': false,
    'tokensIncluded': false,
  };

  double get gpsAssistanceCalibrationMultiplier {
    if (!averageGpsToOdometerRatio.isFinite || averageGpsToOdometerRatio <= 0) {
      return 1;
    }
    return (1 / averageGpsToOdometerRatio)
        .clamp(
          _minimumGpsAssistanceCalibrationMultiplier,
          _maximumGpsAssistanceCalibrationMultiplier,
        )
        .toDouble();
  }

  static TripOdometerCalibrationSignal evaluate({
    required Iterable<TripOdometerReconciliation> history,
    int minimumSamples = 7,
    double minimumOdometerMiles = 5,
    double reviewDifferencePercent = 4,
    double maximumEligibleDifferencePercent = 25,
  }) {
    if (minimumSamples <= 0 ||
        minimumOdometerMiles <= 0 ||
        !minimumOdometerMiles.isFinite ||
        !reviewDifferencePercent.isFinite ||
        reviewDifferencePercent < 0 ||
        !maximumEligibleDifferencePercent.isFinite ||
        maximumEligibleDifferencePercent < reviewDifferencePercent) {
      return const TripOdometerCalibrationSignal(
        status: TripOdometerCalibrationStatus.insufficientHistory,
        eligibleSampleCount: 0,
        averageGpsToOdometerRatio: 1,
        averageDifferencePercent: 0,
        reasonCode: 'invalid_calibration_threshold',
      );
    }

    final eligible = <MapEntry<TripOdometerReconciliation, double>>[];
    for (final sample in history) {
      final recomputedDifferencePercent =
          _recomputedCalibrationDifferencePercent(sample);
      if (sample.status == TripOdometerReconciliationStatus.invalid ||
          !sample.confirmedOdometerDeltaMiles.isFinite ||
          sample.confirmedOdometerDeltaMiles < minimumOdometerMiles ||
          !sample.filteredGpsMiles.isFinite ||
          sample.filteredGpsMiles <= 0 ||
          recomputedDifferencePercent == null ||
          recomputedDifferencePercent > maximumEligibleDifferencePercent) {
        continue;
      }
      eligible.add(MapEntry(sample, recomputedDifferencePercent));
    }
    if (eligible.length < minimumSamples) {
      return TripOdometerCalibrationSignal(
        status: TripOdometerCalibrationStatus.insufficientHistory,
        eligibleSampleCount: eligible.length,
        averageGpsToOdometerRatio: 1,
        averageDifferencePercent: 0,
        reasonCode: 'needs_more_reviewed_days',
      );
    }

    var odometerMilesTotal = 0.0;
    var gpsMilesTotal = 0.0;
    var differenceMilesTotal = 0.0;
    for (final entry in eligible) {
      final sample = entry.key;
      odometerMilesTotal += sample.confirmedOdometerDeltaMiles;
      gpsMilesTotal += sample.filteredGpsMiles;
      differenceMilesTotal +=
          (sample.confirmedOdometerDeltaMiles - sample.filteredGpsMiles).abs();
    }
    final averageRatio = gpsMilesTotal / odometerMilesTotal;
    final averagePercent = (differenceMilesTotal / odometerMilesTotal) * 100;
    final persistentSameDirection =
        eligible.every(
          (entry) =>
              entry.key.filteredGpsMiles >
              entry.key.confirmedOdometerDeltaMiles,
        ) ||
        eligible.every(
          (entry) =>
              entry.key.filteredGpsMiles <
              entry.key.confirmedOdometerDeltaMiles,
        );

    final shouldReview =
        persistentSameDirection && averagePercent >= reviewDifferencePercent;
    return TripOdometerCalibrationSignal(
      status: shouldReview
          ? TripOdometerCalibrationStatus.reviewRecommended
          : TripOdometerCalibrationStatus.stable,
      eligibleSampleCount: eligible.length,
      averageGpsToOdometerRatio: averageRatio,
      averageDifferencePercent: averagePercent,
      reasonCode: shouldReview
          ? 'persistent_gps_odometer_drift'
          : 'calibration_stable',
    );
  }

  static TripOdometerCalibrationSignal evaluateConfirmedReviews({
    required Iterable<TripTrackingReviewRecord> reviews,
    String? vehicleId,
    DateTime? nowUtc,
    int minimumSamples = 7,
    int maximumReviewedDays = 30,
    double minimumOdometerMiles = 5,
    double reviewDifferencePercent = 4,
    double maximumEligibleDifferencePercent = 25,
  }) {
    if (maximumReviewedDays < minimumSamples) {
      return const TripOdometerCalibrationSignal(
        status: TripOdometerCalibrationStatus.insufficientHistory,
        eligibleSampleCount: 0,
        averageGpsToOdometerRatio: 1,
        averageDifferencePercent: 0,
        reasonCode: 'invalid_calibration_threshold',
      );
    }
    final requestedVehicleId = vehicleId?.trim();
    final trustedNowUtc = nowUtc?.toUtc();
    final confirmedReviews = reviews
        .where(
          (review) =>
              review.isOdometerConfirmed &&
              review.hasValidTimeline &&
              (trustedNowUtc == null ||
                  !review.odometerConfirmedAt!.toUtc().isAfter(
                    trustedNowUtc,
                  )) &&
              review.vehicleId.trim().isNotEmpty &&
              (requestedVehicleId == null ||
                  requestedVehicleId.isEmpty ||
                  review.vehicleId.trim() == requestedVehicleId),
        )
        .toList(growable: false);
    final vehicleIds = confirmedReviews
        .map((review) => review.vehicleId.trim())
        .toSet();
    if ((requestedVehicleId == null || requestedVehicleId.isEmpty) &&
        vehicleIds.length > 1) {
      return const TripOdometerCalibrationSignal(
        status: TripOdometerCalibrationStatus.insufficientHistory,
        eligibleSampleCount: 0,
        averageGpsToOdometerRatio: 1,
        averageDifferencePercent: 0,
        reasonCode: 'mixed_vehicle_calibration_history',
      );
    }

    final dailyTotals = <String, _DailyCalibrationTotals>{};
    for (final review in confirmedReviews) {
      final reconciliation = TripOdometerReconciliation.compare(
        review: review,
        confirmedEndingOdometer: review.confirmedEndingOdometer!,
      );
      if (reconciliation.status == TripOdometerReconciliationStatus.invalid) {
        continue;
      }
      final dayKey = _calibrationDayKey(review.startedAt.toUtc());
      dailyTotals
          .putIfAbsent(dayKey, _DailyCalibrationTotals.new)
          .add(reconciliation);
    }
    final recentDayKeys = dailyTotals.keys.toList(growable: false)..sort();
    final boundedDayKeys = recentDayKeys.length > maximumReviewedDays
        ? recentDayKeys.skip(recentDayKeys.length - maximumReviewedDays)
        : recentDayKeys;
    final reconciliations = boundedDayKeys.map(
      (key) => dailyTotals[key]!.toReconciliation(),
    );
    return evaluate(
      history: reconciliations,
      minimumSamples: minimumSamples,
      minimumOdometerMiles: minimumOdometerMiles,
      reviewDifferencePercent: reviewDifferencePercent,
      maximumEligibleDifferencePercent: maximumEligibleDifferencePercent,
    );
  }
}

double _safeRoundedPercent(double value) {
  if (!value.isFinite || value < 0) return 0;
  return (value * 10).round() / 10;
}

double _safeRoundedMultiplier(double value) {
  if (!value.isFinite || value <= 0) return 1;
  return double.parse(value.toStringAsFixed(4));
}

String _safeCalibrationReason(String value) {
  final clean = value.trim();
  return switch (clean) {
    'invalid_calibration_threshold' => clean,
    'needs_more_reviewed_days' => clean,
    'mixed_vehicle_calibration_history' => clean,
    'persistent_gps_odometer_drift' => clean,
    'calibration_stable' => clean,
    _ => 'unknown_calibration_state',
  };
}

bool _safeCalibrationShouldPrompt({
  required TripOdometerCalibrationStatus status,
  required String reasonCode,
}) =>
    status == TripOdometerCalibrationStatus.reviewRecommended &&
    _safeCalibrationReason(reasonCode) == 'persistent_gps_odometer_drift';

class _DailyCalibrationTotals {
  var odometerMiles = 0.0;
  var gpsMiles = 0.0;

  void add(TripOdometerReconciliation reconciliation) {
    odometerMiles += reconciliation.confirmedOdometerDeltaMiles;
    gpsMiles += reconciliation.filteredGpsMiles;
  }

  TripOdometerReconciliation toReconciliation() {
    final difference = (odometerMiles - gpsMiles).abs();
    final percent = odometerMiles <= 0
        ? double.nan
        : difference / odometerMiles * 100;
    return TripOdometerReconciliation(
      status: TripOdometerReconciliationStatus.aligned,
      confirmedOdometerDeltaMiles: odometerMiles,
      filteredGpsMiles: gpsMiles,
      absoluteDifferenceMiles: difference,
      differencePercent: percent,
    );
  }
}

String _calibrationDayKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

double? _recomputedCalibrationDifferencePercent(
  TripOdometerReconciliation sample,
) {
  if (!sample.confirmedOdometerDeltaMiles.isFinite ||
      sample.confirmedOdometerDeltaMiles <= 0 ||
      !sample.filteredGpsMiles.isFinite ||
      sample.filteredGpsMiles < 0) {
    return null;
  }
  final difference =
      (sample.confirmedOdometerDeltaMiles - sample.filteredGpsMiles).abs();
  if (!difference.isFinite) return null;
  final percent = (difference / sample.confirmedOdometerDeltaMiles) * 100;
  return percent.isFinite && percent >= 0 ? percent : null;
}

const _minimumGpsAssistanceCalibrationMultiplier = 0.8;
const _maximumGpsAssistanceCalibrationMultiplier = 1.25;
