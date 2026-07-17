import 'trip_tracking_session_store.dart';

enum TripOdometerReconciliationStatus { aligned, reviewRecommended, invalid }

enum TripOdometerCalibrationStatus {
  insufficientHistory,
  stable,
  reviewRecommended,
}

enum TripOdometerContinuityStatus {
  insufficientData,
  aligned,
  reviewRecommended,
  invalid,
}

/// Explicit comparison only: confirmed odometer mileage remains authoritative.
/// This object never writes an odometer, TripLog, or recap record.
class TripOdometerReconciliation {
  const TripOdometerReconciliation({
    required this.status,
    required this.confirmedOdometerDeltaMiles,
    required this.filteredGpsMiles,
    required this.absoluteDifferenceMiles,
    required this.differencePercent,
  });

  final TripOdometerReconciliationStatus status;
  final double confirmedOdometerDeltaMiles;
  final double filteredGpsMiles;
  final double absoluteDifferenceMiles;
  final double differencePercent;

  static TripOdometerReconciliation compare({
    required TripTrackingReviewRecord review,
    required int confirmedEndingOdometer,
    double materialDifferenceMiles = 5,
    double materialDifferencePercent = 10,
  }) {
    final odometerDelta = confirmedEndingOdometer - review.startingOdometer;
    final gpsMiles = review.engineSnapshot.totalAcceptedMeters / 1609.344;
    if (!review.hasValidTimeline ||
        review.id.trim().isEmpty ||
        review.vehicleId.trim().isEmpty ||
        review.estimatedEndingOdometer < review.startingOdometer ||
        odometerDelta < 0 ||
        !gpsMiles.isFinite ||
        gpsMiles < 0 ||
        !materialDifferenceMiles.isFinite ||
        materialDifferenceMiles < 0 ||
        !materialDifferencePercent.isFinite ||
        materialDifferencePercent < 0) {
      return const TripOdometerReconciliation(
        status: TripOdometerReconciliationStatus.invalid,
        confirmedOdometerDeltaMiles: 0,
        filteredGpsMiles: 0,
        absoluteDifferenceMiles: 0,
        differencePercent: 0,
      );
    }
    final difference = (odometerDelta - gpsMiles).abs();
    final denominator = odometerDelta == 0 ? 1.0 : odometerDelta.toDouble();
    final percent = (difference / denominator) * 100;
    return TripOdometerReconciliation(
      status:
          difference >= materialDifferenceMiles ||
              percent >= materialDifferencePercent
          ? TripOdometerReconciliationStatus.reviewRecommended
          : TripOdometerReconciliationStatus.aligned,
      confirmedOdometerDeltaMiles: odometerDelta.toDouble(),
      filteredGpsMiles: gpsMiles,
      absoluteDifferenceMiles: difference,
      differencePercent: percent,
    );
  }
}

class TripOdometerContinuityCheck {
  const TripOdometerContinuityCheck({
    required this.status,
    required this.odometerGapMiles,
    required this.reasonCode,
  });

  final TripOdometerContinuityStatus status;
  final int odometerGapMiles;
  final String reasonCode;

  bool get shouldBlockConfirmation =>
      status == TripOdometerContinuityStatus.invalid;

  static TripOdometerContinuityCheck betweenReviews({
    required TripTrackingReviewRecord previous,
    required TripTrackingReviewRecord next,
    int materialUntrackedGapMiles = 50,
  }) {
    final previousEnding = previous.confirmedEndingOdometer;
    final previousVehicleId = previous.vehicleId.trim();
    final nextVehicleId = next.vehicleId.trim();
    if (previousVehicleId != nextVehicleId || previousEnding == null) {
      return const TripOdometerContinuityCheck(
        status: TripOdometerContinuityStatus.insufficientData,
        odometerGapMiles: 0,
        reasonCode: 'missing_same_vehicle_confirmed_history',
      );
    }
    if (previous.id.trim().isEmpty ||
        next.id.trim().isEmpty ||
        previousVehicleId.isEmpty ||
        nextVehicleId.isEmpty ||
        !previous.hasValidTimeline ||
        !next.hasValidTimeline ||
        !previous.isOdometerConfirmed ||
        previous.estimatedEndingOdometer < previous.startingOdometer ||
        next.estimatedEndingOdometer < next.startingOdometer ||
        previousEnding < previous.startingOdometer ||
        next.startingOdometer < 0 ||
        next.startedAt.isBefore(previous.finishedAt) ||
        materialUntrackedGapMiles < 0) {
      return const TripOdometerContinuityCheck(
        status: TripOdometerContinuityStatus.invalid,
        odometerGapMiles: 0,
        reasonCode: 'invalid_odometer_continuity_input',
      );
    }
    final gap = next.startingOdometer - previousEnding;
    if (gap < 0) {
      return TripOdometerContinuityCheck(
        status: TripOdometerContinuityStatus.invalid,
        odometerGapMiles: gap,
        reasonCode: 'starting_odometer_below_previous_confirmed_ending',
      );
    }
    if (gap > materialUntrackedGapMiles) {
      return TripOdometerContinuityCheck(
        status: TripOdometerContinuityStatus.reviewRecommended,
        odometerGapMiles: gap,
        reasonCode: 'large_untracked_odometer_gap',
      );
    }
    return TripOdometerContinuityCheck(
      status: TripOdometerContinuityStatus.aligned,
      odometerGapMiles: gap,
      reasonCode: 'odometer_continuity_aligned',
    );
  }
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

  /// Calibration is advisory. It may prompt a user review or tune future
  /// assistance, but it must never overwrite confirmed odometer truth.
  bool get canOverwriteConfirmedOdometer => false;

  /// Multiplier future GPS assistance may apply to its estimated distance when
  /// a user accepts calibration guidance. It is intentionally advisory and
  /// never changes confirmed odometer records by itself.
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
    double minimumOdometerMiles = 5,
    double reviewDifferencePercent = 4,
    double maximumEligibleDifferencePercent = 25,
  }) {
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
    final reconciliations = dailyTotals.values.map(
      (totals) => totals.toReconciliation(),
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
