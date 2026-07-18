import 'trip_tracking_session_store.dart';

enum TripOdometerReconciliationStatus { aligned, reviewRecommended, invalid }

enum TripOdometerContinuityStatus {
  insufficientData,
  aligned,
  reviewRecommended,
  invalid,
}

enum TripOdometerEntryValidationStatus { valid, reviewRecommended, invalid }

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

  bool get shouldPromptUser =>
      status == TripOdometerReconciliationStatus.reviewRecommended;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'confirmedOdometerDeltaMiles': _safeRoundedMiles(
      confirmedOdometerDeltaMiles,
    ),
    'filteredGpsMiles': _safeRoundedMiles(filteredGpsMiles),
    'absoluteDifferenceMiles': _safeRoundedMiles(absoluteDifferenceMiles),
    'differencePercent': _safeRoundedPercent(differencePercent),
    'shouldPromptUser': shouldPromptUser,
    'userReviewRequiredBeforeChange': shouldPromptUser,
    'odometerRemainsCanonical': true,
    'gpsCanReplaceOdometer': false,
    'mapboxCanReplaceOdometer': false,
    'calibrationCanApplySilently': false,
    'externalMileageTrustedAfterValidationOnly': true,
    'remoteTotalsCanBecomeCanonical': false,
    'firestoreCanOverrideOdometerTruth': false,
    'mapboxCanOverrideOdometerTruth': false,
    'rawLocationIncluded': false,
    'rawTripRecordsIncluded': false,
  };

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

  bool get shouldPromptUser =>
      status == TripOdometerContinuityStatus.reviewRecommended ||
      status == TripOdometerContinuityStatus.invalid;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'odometerGapMiles': odometerGapMiles,
    'reasonCode': _safeContinuityReason(reasonCode),
    'shouldBlockConfirmation': shouldBlockConfirmation,
    'shouldPromptUser': shouldPromptUser,
    'manualReviewRequired': shouldPromptUser,
    'odometerRemainsCanonical': true,
    'gpsCanFillGapAutomatically': false,
    'mapboxCanFillGapAutomatically': false,
    'remoteBackupCanFillGapAutomatically': false,
    'continuityTrustedAfterValidationOnly': true,
    'firestoreCanOverrideContinuity': false,
    'mapboxCanOverrideContinuity': false,
    'rawTripRecordsIncluded': false,
    'rawLocationIncluded': false,
  };

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

class TripOdometerEntryValidation {
  const TripOdometerEntryValidation({
    required this.status,
    required this.startingOdometer,
    required this.endingOdometer,
    required this.previousConfirmedEndingOdometer,
    required this.deltaMiles,
    required this.reasonCode,
  });

  final TripOdometerEntryValidationStatus status;
  final int startingOdometer;
  final int endingOdometer;
  final int? previousConfirmedEndingOdometer;
  final int deltaMiles;
  final String reasonCode;

  bool get shouldBlockConfirmation =>
      status == TripOdometerEntryValidationStatus.invalid;

  bool get shouldPromptUser =>
      status == TripOdometerEntryValidationStatus.reviewRecommended ||
      shouldBlockConfirmation;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'deltaMiles': deltaMiles < 0 ? 0 : deltaMiles,
    'previousConfirmedEndingPresent':
        previousConfirmedEndingOdometer != null &&
        previousConfirmedEndingOdometer! >= 0,
    'reasonCode': _safeEntryValidationReason(reasonCode),
    'shouldBlockConfirmation': shouldBlockConfirmation,
    'shouldPromptUser': shouldPromptUser,
    'manualReviewRequired': shouldPromptUser,
    'odometerRemainsCanonical': true,
    'gpsCanCorrectEntryAutomatically': false,
    'mapboxCanCorrectEntryAutomatically': false,
    'remoteBackupCanCorrectEntryAutomatically': false,
    'entryTrustedAfterLocalValidationOnly': true,
    'firestoreCanOverrideEntryValidation': false,
    'cloudFunctionCanOverrideEntryValidation': false,
    'rawTripRecordsIncluded': false,
    'rawLocationIncluded': false,
  };

  static TripOdometerEntryValidation validate({
    required int startingOdometer,
    required int endingOdometer,
    int? previousConfirmedEndingOdometer,
    double? averageDailyMiles,
    int materialUntrackedGapMiles = 50,
    double highMileageMultiplier = 2.5,
    double minimumReviewBufferMiles = 50,
  }) {
    if (startingOdometer < 0 ||
        endingOdometer < 0 ||
        (previousConfirmedEndingOdometer != null &&
            previousConfirmedEndingOdometer < 0) ||
        materialUntrackedGapMiles < 0 ||
        !highMileageMultiplier.isFinite ||
        highMileageMultiplier < 1 ||
        !minimumReviewBufferMiles.isFinite ||
        minimumReviewBufferMiles < 0 ||
        (averageDailyMiles != null &&
            (!averageDailyMiles.isFinite || averageDailyMiles < 0))) {
      return _entryValidation(
        status: TripOdometerEntryValidationStatus.invalid,
        startingOdometer: startingOdometer,
        endingOdometer: endingOdometer,
        previousConfirmedEndingOdometer: previousConfirmedEndingOdometer,
        reasonCode: 'invalid_odometer_entry_input',
      );
    }
    if (endingOdometer < startingOdometer) {
      return _entryValidation(
        status: TripOdometerEntryValidationStatus.invalid,
        startingOdometer: startingOdometer,
        endingOdometer: endingOdometer,
        previousConfirmedEndingOdometer: previousConfirmedEndingOdometer,
        reasonCode: 'ending_odometer_below_starting_odometer',
      );
    }
    if (previousConfirmedEndingOdometer != null &&
        startingOdometer < previousConfirmedEndingOdometer) {
      return _entryValidation(
        status: TripOdometerEntryValidationStatus.invalid,
        startingOdometer: startingOdometer,
        endingOdometer: endingOdometer,
        previousConfirmedEndingOdometer: previousConfirmedEndingOdometer,
        reasonCode: 'starting_odometer_below_previous_confirmed_ending',
      );
    }

    final previousGap = previousConfirmedEndingOdometer == null
        ? 0
        : startingOdometer - previousConfirmedEndingOdometer;
    if (previousGap > materialUntrackedGapMiles) {
      return _entryValidation(
        status: TripOdometerEntryValidationStatus.reviewRecommended,
        startingOdometer: startingOdometer,
        endingOdometer: endingOdometer,
        previousConfirmedEndingOdometer: previousConfirmedEndingOdometer,
        reasonCode: 'large_untracked_odometer_gap',
      );
    }

    final deltaMiles = endingOdometer - startingOdometer;
    final average = averageDailyMiles ?? 0;
    if (average > 0) {
      final highThreshold =
          average * highMileageMultiplier > average + minimumReviewBufferMiles
          ? average * highMileageMultiplier
          : average + minimumReviewBufferMiles;
      final lowThreshold = _lowEntryReviewThreshold(
        averageDailyMiles: average,
        highMileageMultiplier: highMileageMultiplier,
        minimumReviewBufferMiles: minimumReviewBufferMiles,
      );
      if (deltaMiles > highThreshold) {
        return _entryValidation(
          status: TripOdometerEntryValidationStatus.reviewRecommended,
          startingOdometer: startingOdometer,
          endingOdometer: endingOdometer,
          previousConfirmedEndingOdometer: previousConfirmedEndingOdometer,
          reasonCode: 'unusually_high_odometer_delta',
        );
      }
      if (deltaMiles < lowThreshold) {
        return _entryValidation(
          status: TripOdometerEntryValidationStatus.reviewRecommended,
          startingOdometer: startingOdometer,
          endingOdometer: endingOdometer,
          previousConfirmedEndingOdometer: previousConfirmedEndingOdometer,
          reasonCode: 'unusually_low_odometer_delta',
        );
      }
    }

    return _entryValidation(
      status: TripOdometerEntryValidationStatus.valid,
      startingOdometer: startingOdometer,
      endingOdometer: endingOdometer,
      previousConfirmedEndingOdometer: previousConfirmedEndingOdometer,
      reasonCode: 'odometer_entry_validated',
    );
  }
}

double _safeRoundedPercent(double value) {
  if (!value.isFinite || value < 0) return 0;
  return (value * 10).round() / 10;
}

double _safeRoundedMiles(double value) {
  if (!value.isFinite || value < 0) return 0;
  return (value * 10).round() / 10;
}

TripOdometerEntryValidation _entryValidation({
  required TripOdometerEntryValidationStatus status,
  required int startingOdometer,
  required int endingOdometer,
  required int? previousConfirmedEndingOdometer,
  required String reasonCode,
}) {
  final delta = endingOdometer - startingOdometer;
  return TripOdometerEntryValidation(
    status: status,
    startingOdometer: startingOdometer,
    endingOdometer: endingOdometer,
    previousConfirmedEndingOdometer: previousConfirmedEndingOdometer,
    deltaMiles: delta < 0 ? 0 : delta,
    reasonCode: reasonCode,
  );
}

double _lowEntryReviewThreshold({
  required double averageDailyMiles,
  required double highMileageMultiplier,
  required double minimumReviewBufferMiles,
}) {
  if (averageDailyMiles <= minimumReviewBufferMiles) return 0;
  return (averageDailyMiles / highMileageMultiplier <
              averageDailyMiles - minimumReviewBufferMiles
          ? averageDailyMiles / highMileageMultiplier
          : averageDailyMiles - minimumReviewBufferMiles)
      .clamp(0, double.infinity)
      .toDouble();
}

String _safeEntryValidationReason(String value) {
  final clean = value.trim();
  return switch (clean) {
    'invalid_odometer_entry_input' => clean,
    'ending_odometer_below_starting_odometer' => clean,
    'starting_odometer_below_previous_confirmed_ending' => clean,
    'large_untracked_odometer_gap' => clean,
    'unusually_high_odometer_delta' => clean,
    'unusually_low_odometer_delta' => clean,
    'odometer_entry_validated' => clean,
    _ => 'invalid_odometer_entry_input',
  };
}

String _safeContinuityReason(String value) {
  final clean = value.trim();
  return switch (clean) {
    'missing_same_vehicle_confirmed_history' => clean,
    'invalid_odometer_continuity_input' => clean,
    'starting_odometer_below_previous_confirmed_ending' => clean,
    'large_untracked_odometer_gap' => clean,
    'odometer_continuity_aligned' => clean,
    _ => 'invalid_odometer_continuity_input',
  };
}
