// odometerIsGlobalTruth: true. Only confirmed odometer history is learned.

import 'trip_driver_pattern_assistant.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_session_store.dart';

class TripDriverPatternReviewAdapter {
  const TripDriverPatternReviewAdapter._();

  static List<TripDriverPatternObservation> fromReviews(
    Iterable<TripTrackingReviewRecord> reviews, {
    int maximumReviews = 256,
  }) {
    final safeMaximum = maximumReviews.clamp(1, 256);
    return _mostRecentReviews(
      reviews,
      safeMaximum,
    ).map(_fromReview).toList(growable: false);
  }

  static TripDriverPatternObservation _fromReview(
    TripTrackingReviewRecord review,
  ) => TripDriverPatternObservation(
    sessionId: review.id,
    vehicleId: review.vehicleId,
    profileId: review.effectiveProfileId,
    startedAtUtc: review.startedAt.toUtc(),
    endedAtUtc: review.finishedAt.toUtc(),
    confirmedOdometerDistanceMiles: review.isOdometerConfirmed
        ? (review.confirmedEndingOdometer! - review.startingOdometer).toDouble()
        : 0,
    confirmedStopCount: _confirmedStopCount(review),
    longestConfirmedStop: _longestConfirmedStop(review),
    userReviewed: review.isOdometerConfirmed,
    odometerConfirmed: review.isOdometerConfirmed,
  );
}

List<TripTrackingReviewRecord> _mostRecentReviews(
  Iterable<TripTrackingReviewRecord> reviews,
  int maximumReviews,
) {
  final retained = <TripTrackingReviewRecord>[];
  for (final review in reviews) {
    var insertionIndex = retained.indexWhere(
      (existing) =>
          review.finishedAt.isAfter(existing.finishedAt) ||
          (review.finishedAt.isAtSameMomentAs(existing.finishedAt) &&
              review.id.compareTo(existing.id) < 0),
    );
    if (insertionIndex < 0) insertionIndex = retained.length;
    if (insertionIndex >= maximumReviews && retained.length >= maximumReviews) {
      continue;
    }
    retained.insert(insertionIndex, review);
    if (retained.length > maximumReviews) retained.removeLast();
  }
  return retained;
}

int _confirmedStopCount(TripTrackingReviewRecord review) {
  final explicitStops = review.tripEvents.where(
    (event) =>
        event.userConfirmed &&
        (event.type == TripManualEventType.stop ||
            event.type == TripManualEventType.workStop ||
            event.type == TripManualEventType.pickup ||
            event.type == TripManualEventType.dropoff ||
            event.type == TripManualEventType.fuelStop ||
            event.type == TripManualEventType.jobSite ||
            event.type == TripManualEventType.customerWait),
  );
  if (explicitStops.isNotEmpty) return explicitStops.length;
  return review.advisories
      .where(
        (event) =>
            event.type == TripTrackingAdvisoryType.probableStop &&
            event.disposition == TripTrackingAdvisoryDisposition.confirmed,
      )
      .length;
}

Duration _longestConfirmedStop(TripTrackingReviewRecord review) {
  final ordered = [...review.advisories]
    ..sort((left, right) => left.detectedAt.compareTo(right.detectedAt));
  var longest = Duration.zero;
  for (var index = 0; index < ordered.length; index += 1) {
    final stop = ordered[index];
    if (stop.type != TripTrackingAdvisoryType.probableStop ||
        stop.disposition != TripTrackingAdvisoryDisposition.confirmed) {
      continue;
    }
    for (var next = index + 1; next < ordered.length; next += 1) {
      final resumed = ordered[next];
      if (resumed.type != TripTrackingAdvisoryType.resumedMovement ||
          resumed.detectedAt.isBefore(stop.detectedAt)) {
        continue;
      }
      final duration = resumed.detectedAt.difference(stop.detectedAt);
      if (duration > longest && duration <= const Duration(days: 7)) {
        longest = duration;
      }
      break;
    }
  }
  return longest;
}
