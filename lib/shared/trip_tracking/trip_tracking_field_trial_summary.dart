// odometerIsGlobalTruth: true. This summary compares; it never confirms mileage.

import 'trip_tracking_models.dart';
import 'trip_tracking_session_store.dart';

class TripTrackingFieldTrialSummary {
  const TripTrackingFieldTrialSummary({
    required this.gpsAssistedMiles,
    required this.odometerMiles,
    required this.receivedSamples,
    required this.acceptedSamples,
    required this.rejectedSamples,
    required this.rejectedDistanceMiles,
    required this.estimatedGapMiles,
    required this.signalGapCount,
    required this.probableStopCount,
    required this.confirmedStopCount,
    required this.dismissedStopCount,
    required this.recoveryCount,
  });

  factory TripTrackingFieldTrialSummary.fromReview(
    TripTrackingReviewRecord review,
  ) {
    final snapshot = review.engineSnapshot;
    final diagnostics = snapshot.diagnostics;
    final probableStops = review.advisories.where(
      (event) => event.type == TripTrackingAdvisoryType.probableStop,
    );
    return TripTrackingFieldTrialSummary(
      gpsAssistedMiles: _metersToMiles(snapshot.totalAcceptedMeters),
      odometerMiles: review.isOdometerConfirmed
          ? (review.confirmedEndingOdometer! - review.startingOdometer)
                .toDouble()
          : null,
      receivedSamples: diagnostics.receivedSamples,
      acceptedSamples: diagnostics.acceptedSamples,
      rejectedSamples: diagnostics.rejectedSamples,
      rejectedDistanceMiles: _metersToMiles(diagnostics.rejectedDistanceMeters),
      estimatedGapMiles: _metersToMiles(diagnostics.estimatedGapDistanceMeters),
      signalGapCount: snapshot.signalGaps.length,
      probableStopCount: probableStops.length,
      confirmedStopCount: probableStops
          .where(
            (event) =>
                event.disposition == TripTrackingAdvisoryDisposition.confirmed,
          )
          .length,
      dismissedStopCount: probableStops
          .where(
            (event) =>
                event.disposition ==
                    TripTrackingAdvisoryDisposition.dismissed ||
                event.disposition == TripTrackingAdvisoryDisposition.rejected,
          )
          .length,
      recoveryCount: review.recoveryCount,
    );
  }

  final double gpsAssistedMiles;
  final double? odometerMiles;
  final int receivedSamples;
  final int acceptedSamples;
  final int rejectedSamples;
  final double rejectedDistanceMiles;
  final double estimatedGapMiles;
  final int signalGapCount;
  final int probableStopCount;
  final int confirmedStopCount;
  final int dismissedStopCount;
  final int recoveryCount;

  double? get absoluteDifferenceMiles =>
      odometerMiles == null ? null : (gpsAssistedMiles - odometerMiles!).abs();

  Map<String, Object?> toSafeSummary() => {
    'gpsAssistedMiles': _round(gpsAssistedMiles),
    'odometerMiles': odometerMiles == null ? null : _round(odometerMiles!),
    'absoluteDifferenceMiles': absoluteDifferenceMiles == null
        ? null
        : _round(absoluteDifferenceMiles!),
    'receivedSamples': receivedSamples,
    'acceptedSamples': acceptedSamples,
    'rejectedSamples': rejectedSamples,
    'rejectedDistanceMiles': _round(rejectedDistanceMiles),
    'estimatedGapMiles': _round(estimatedGapMiles),
    'signalGapCount': signalGapCount,
    'probableStopCount': probableStopCount,
    'confirmedStopCount': confirmedStopCount,
    'dismissedStopCount': dismissedStopCount,
    'recoveryCount': recoveryCount,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'odometerIsOfficial': true,
    'gpsCanConfirmMileage': false,
  };
}

double _metersToMiles(double meters) {
  if (!meters.isFinite || meters <= 0) return 0;
  return meters / 1609.344;
}

double _round(double value) => double.parse(value.toStringAsFixed(3));
