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
    required this.unresolvedStopCount,
    required this.recoveryCount,
    required this.durationMinutes,
    required this.initialFixQuality,
    required this.algorithmVersion,
    required this.vehicleConfigurationRevision,
    required this.gpsAssistanceCalibrationMultiplier,
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
      unresolvedStopCount: probableStops
          .where(
            (event) =>
                event.disposition == TripTrackingAdvisoryDisposition.pending,
          )
          .length,
      recoveryCount: review.recoveryCount,
      durationMinutes: review.finishedAt.isBefore(review.startedAt)
          ? 0
          : review.finishedAt.difference(review.startedAt).inMinutes,
      initialFixQuality:
          snapshot.initialFixAssessment?.quality.name ?? 'unavailable',
      algorithmVersion: snapshot.algorithmVersion,
      vehicleConfigurationRevision: review.vehicleConfigurationRevision,
      gpsAssistanceCalibrationMultiplier:
          review.gpsAssistanceCalibrationMultiplier,
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
  final int unresolvedStopCount;
  final int recoveryCount;
  final int durationMinutes;
  final String initialFixQuality;
  final String algorithmVersion;
  final int vehicleConfigurationRevision;
  final double gpsAssistanceCalibrationMultiplier;

  String get initialFixQualityLabel => switch (initialFixQuality) {
    'freshPrecise' => 'fresh precise',
    'freshModerate' => 'fresh moderate',
    'freshLowQuality' => 'fresh low quality',
    'staleCached' => 'stale cached',
    'approximateOnly' => 'approximate only',
    'rejected' => 'rejected',
    _ => 'unavailable',
  };

  double get acceptedSamplePercent => receivedSamples <= 0
      ? 0
      : (acceptedSamples / receivedSamples * 100).clamp(0, 100).toDouble();

  double? get signedDifferenceMiles =>
      odometerMiles == null ? null : gpsAssistedMiles - odometerMiles!;

  double? get absoluteDifferenceMiles => signedDifferenceMiles?.abs();

  double get calibrationAdjustedGpsMiles =>
      gpsAssistedMiles * gpsAssistanceCalibrationMultiplier;

  double? get calibrationAdjustedDifferenceMiles => odometerMiles == null
      ? null
      : calibrationAdjustedGpsMiles - odometerMiles!;

  String toPlainText() {
    final signedDifference = signedDifferenceMiles;
    final differenceLabel = signedDifference == null
        ? 'not available'
        : '${signedDifference >= 0 ? '+' : ''}${signedDifference.toStringAsFixed(2)} mi';
    return 'Odometer: ${odometerMiles?.toStringAsFixed(2) ?? 'awaiting confirmation'} mi\n'
        'GPS measured distance: ${gpsAssistedMiles.toStringAsFixed(2)} mi\n'
        'GPS estimate after calibration: ${calibrationAdjustedGpsMiles.toStringAsFixed(2)} mi\n'
        'Measured GPS vs odometer: $differenceLabel (positive means GPS is higher)\n'
        'Duration: $durationMinutes min; initial fix: $initialFixQualityLabel\n'
        'Samples: $receivedSamples received, $acceptedSamples accepted, $rejectedSamples rejected (${acceptedSamplePercent.toStringAsFixed(1)}% accepted)\n'
        'Rejected candidate distance: ${rejectedDistanceMiles.toStringAsFixed(2)} mi (not counted as mileage)\n'
        'Signal gaps: $signalGapCount; estimated gap: ${estimatedGapMiles.toStringAsFixed(2)} mi\n'
        'Possible stops: $probableStopCount; confirmed: $confirmedStopCount; dismissed: $dismissedStopCount; unresolved: $unresolvedStopCount\n'
        'Recoveries: $recoveryCount\n\n'
        'Engine: $algorithmVersion; vehicle configuration revision: $vehicleConfigurationRevision\n\n'
        'Applied GPS calibration multiplier: ${gpsAssistanceCalibrationMultiplier.toStringAsFixed(4)}\n\n'
        'The odometer remains official. GPS assistance never confirms mileage.';
  }

  Map<String, Object?> toSafeSummary() => {
    'gpsAssistedMiles': _round(gpsAssistedMiles),
    'calibrationAdjustedGpsMiles': _round(calibrationAdjustedGpsMiles),
    'odometerMiles': odometerMiles == null ? null : _round(odometerMiles!),
    'absoluteDifferenceMiles': absoluteDifferenceMiles == null
        ? null
        : _round(absoluteDifferenceMiles!),
    'signedDifferenceMiles': signedDifferenceMiles == null
        ? null
        : _round(signedDifferenceMiles!),
    'calibrationAdjustedDifferenceMiles':
        calibrationAdjustedDifferenceMiles == null
        ? null
        : _round(calibrationAdjustedDifferenceMiles!),
    'receivedSamples': receivedSamples,
    'acceptedSamples': acceptedSamples,
    'rejectedSamples': rejectedSamples,
    'rejectedDistanceMiles': _round(rejectedDistanceMiles),
    'estimatedGapMiles': _round(estimatedGapMiles),
    'signalGapCount': signalGapCount,
    'probableStopCount': probableStopCount,
    'confirmedStopCount': confirmedStopCount,
    'dismissedStopCount': dismissedStopCount,
    'unresolvedStopCount': unresolvedStopCount,
    'recoveryCount': recoveryCount,
    'durationMinutes': durationMinutes,
    'initialFixQuality': initialFixQuality,
    'algorithmVersion': algorithmVersion,
    'vehicleConfigurationRevision': vehicleConfigurationRevision,
    'gpsAssistanceCalibrationMultiplier': _round(
      gpsAssistanceCalibrationMultiplier,
    ),
    'acceptedSamplePercent': _round(acceptedSamplePercent),
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'odometerIsOfficial': true,
    'gpsCanConfirmMileage': false,
  };

  /// Privacy-minimized operational health evidence for opt-in diagnostics.
  ///
  /// Owns no upload, identity, route, mileage, customer, or business-record
  /// data. A diagnostics transport may consume only this allowlisted shape;
  /// it must remain opt-in and cannot affect trip or odometer decisions.
  Map<String, Object?> toHealthTelemetry() => {
    'schema': 'trip_tracking_health_v1',
    'privacyClass': 'health_only_no_personal_or_location_data',
    'receivedSamples': receivedSamples,
    'acceptedSamples': acceptedSamples,
    'rejectedSamples': rejectedSamples,
    'acceptedSampleRateBand': _percentBand(acceptedSamplePercent),
    'signalGapCount': signalGapCount,
    'probableStopCount': probableStopCount,
    'confirmedStopCount': confirmedStopCount,
    'dismissedStopCount': dismissedStopCount,
    'unresolvedStopCount': unresolvedStopCount,
    'recoveryCount': recoveryCount,
    'durationBand': _durationBand(durationMinutes),
    'initialFixQuality': initialFixQuality,
    'odometerComparisonAvailable': odometerMiles != null,
    'gpsOdometerDifferenceBand': _differenceBand(absoluteDifferenceMiles),
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'identifiersIncluded': false,
    'rawMileageIncluded': false,
    'canChangeOdometer': false,
  };
}

double _metersToMiles(double meters) {
  if (!meters.isFinite || meters <= 0) return 0;
  return meters / 1609.344;
}

double _round(double value) => double.parse(value.toStringAsFixed(3));

String _durationBand(int minutes) => switch (minutes) {
  < 5 => 'under_5_minutes',
  < 30 => '5_to_29_minutes',
  < 120 => '30_to_119_minutes',
  _ => '120_or_more_minutes',
};

String _percentBand(double percent) => switch (percent) {
  < 50 => 'under_50_percent',
  < 80 => '50_to_79_percent',
  < 95 => '80_to_94_percent',
  _ => '95_to_100_percent',
};

String _differenceBand(double? miles) {
  if (miles == null) return 'not_available';
  if (miles <= 0.5) return 'within_half_mile';
  if (miles <= 2) return 'over_half_to_2_miles';
  return 'over_2_miles';
}
