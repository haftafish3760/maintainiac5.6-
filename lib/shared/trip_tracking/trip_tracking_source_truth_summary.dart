import 'trip_tracking_session_store.dart';

class TripTrackingSourceTruthSummary {
  const TripTrackingSourceTruthSummary._({
    required this.day,
    required this.vehicleId,
    required this.confirmedTripCount,
    required this.unconfirmedTripCount,
    required this.confirmedMiles,
    required this.advisoryEstimatedMiles,
    required this.rejectedRecordCount,
    required this.rejectionReasons,
  });

  factory TripTrackingSourceTruthSummary.forLocalReviewDay({
    required DateTime day,
    required Iterable<TripTrackingReviewRecord> reviews,
    String? vehicleId,
  }) {
    final targetDay = DateTime.utc(
      day.toUtc().year,
      day.toUtc().month,
      day.toUtc().day,
    );
    var confirmedTripCount = 0;
    var unconfirmedTripCount = 0;
    var confirmedMiles = 0;
    var advisoryEstimatedMiles = 0;
    var rejectedRecordCount = 0;
    final rejectionReasons = <String>{};
    final seenReviewIds = <String>{};

    for (final review in reviews) {
      final rejection = _rejectionReason(
        review,
        targetDay: targetDay,
        vehicleId: vehicleId,
        seenReviewIds: seenReviewIds,
      );
      if (rejection != null) {
        rejectedRecordCount += 1;
        rejectionReasons.add(rejection);
        continue;
      }

      final confirmedEnding = review.confirmedEndingOdometer;
      if (review.isOdometerConfirmed && confirmedEnding != null) {
        confirmedTripCount += 1;
        confirmedMiles += confirmedEnding - review.startingOdometer;
      } else {
        unconfirmedTripCount += 1;
        advisoryEstimatedMiles +=
            review.estimatedEndingOdometer - review.startingOdometer;
      }
    }

    return TripTrackingSourceTruthSummary._(
      day: targetDay,
      vehicleId: vehicleId,
      confirmedTripCount: confirmedTripCount,
      unconfirmedTripCount: unconfirmedTripCount,
      confirmedMiles: confirmedMiles,
      advisoryEstimatedMiles: advisoryEstimatedMiles,
      rejectedRecordCount: rejectedRecordCount,
      rejectionReasons: List.unmodifiable(rejectionReasons.toList()..sort()),
    );
  }

  final DateTime day;
  final String? vehicleId;
  final int confirmedTripCount;
  final int unconfirmedTripCount;
  final int confirmedMiles;
  final int advisoryEstimatedMiles;
  final int rejectedRecordCount;
  final List<String> rejectionReasons;

  bool get hasUnconfirmedMileage => unconfirmedTripCount > 0;
  bool get isEmpty => confirmedTripCount == 0 && unconfirmedTripCount == 0;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'day': day.toIso8601String(),
    'vehicleId': vehicleId,
    'confirmedTripCount': confirmedTripCount,
    'unconfirmedTripCount': unconfirmedTripCount,
    'confirmedMiles': confirmedMiles,
    'advisoryEstimatedMiles': advisoryEstimatedMiles,
    'hasUnconfirmedMileage': hasUnconfirmedMileage,
    'rejectedRecordCount': rejectedRecordCount,
    'rejectionReasons': rejectionReasons,
    'duplicateReviewIdsRejected': rejectionReasons.contains(
      'duplicate_review_id',
    ),
    'derivedFromValidatedLocalReviewRecords': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreTotalsAcceptedAsCanonical': false,
    'mapboxDistanceAcceptedAsCanonical': false,
    'remoteRecapCanOverrideLocalDay': false,
    'notificationsUseRemoteTotals': false,
    'exportsUseRemoteTotals': false,
    'invoicesUseRemoteTotals': false,
    'officialMileageSource': 'confirmed_odometer',
    'unconfirmedMileageIsAdvisory': true,
    'rawGpsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

String? _rejectionReason(
  TripTrackingReviewRecord review, {
  required DateTime targetDay,
  required String? vehicleId,
  required Set<String> seenReviewIds,
}) {
  if (!review.hasValidTimeline) return 'invalid_timeline';
  final reviewId = review.id.trim();
  if (reviewId.isEmpty || reviewId != review.id) return 'invalid_review_id';
  if (!seenReviewIds.add(reviewId)) return 'duplicate_review_id';
  if (vehicleId != null && review.vehicleId != vehicleId) {
    return 'wrong_vehicle';
  }
  final reviewDay = DateTime.utc(
    review.startedAt.toUtc().year,
    review.startedAt.toUtc().month,
    review.startedAt.toUtc().day,
  );
  if (reviewDay != targetDay) return 'outside_requested_day';
  if (review.startingOdometer < 0) return 'negative_starting_odometer';
  if (review.estimatedEndingOdometer < review.startingOdometer) {
    return 'estimated_ending_below_starting';
  }
  final confirmedEnding = review.confirmedEndingOdometer;
  if (confirmedEnding != null && confirmedEnding < review.startingOdometer) {
    return 'confirmed_ending_below_starting';
  }
  if ((confirmedEnding != null || review.odometerConfirmedAt != null) &&
      !review.isOdometerConfirmed) {
    return 'invalid_confirmed_odometer';
  }
  return null;
}
