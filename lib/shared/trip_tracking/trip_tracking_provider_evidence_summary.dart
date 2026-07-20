import 'trip_tracking_models.dart';

extension TripLocationSampleEvidenceSummary on TripLocationSample {
  Map<String, Object?> toEvidenceBoundarySummary({
    DateTime? receivedAtUtc,
    bool fromRemoteProvider = true,
  }) {
    final receivedAt = receivedAtUtc?.toUtc();
    final recordedUtc = recordedAt.toUtc();
    final age = receivedAt?.difference(recordedUtc);
    return {
      'schemaVersion': 1,
      'evidenceType': 'gps_location_sample',
      'fromRemoteProvider': fromRemoteProvider,
      'hasValidCoordinate': hasValidCoordinate,
      'hasValidAccuracy': hasValidAccuracy,
      'accuracyBucket': _accuracyBucket(horizontalAccuracyMeters),
      'speedBucket': _speedBucket(speedMetersPerSecond),
      'hasSpeedAccuracy': speedAccuracyMetersPerSecond != null,
      'hasBearing': bearingDegrees != null,
      'hasMonotonicElapsedTime': monotonicElapsedNanos != null,
      'timestampBucket': _timestampBucket(age),
      'mockedLocationReported': mockedLocation == true,
      'trustedAfterValidationOnly': true,
      'odometerIsGlobalTruth': true,
      'calibrationRequiresTrustedGpsWindow': true,
      'poorGpsDaysExcludedFromCalibration': true,
      'providerEvidenceCanCreateCalibration': false,
      'providerEvidenceCanApplyCalibration': false,
      'canCreateOfficialMileage': false,
      'canOverrideOdometer': false,
      'canCreateOfficialStop': false,
      'mapboxCanOverrideSample': false,
      'firestoreCanOverrideSample': false,
      'rawLatitudeIncluded': false,
      'rawLongitudeIncluded': false,
      'rawTimestampIncluded': false,
      'rawBearingIncluded': false,
      'rawProviderPayloadIncluded': false,
      'tokensIncluded': false,
    };
  }
}

extension TripActivityObservationEvidenceSummary on TripActivityObservation {
  Map<String, Object?> toEvidenceBoundarySummary() => {
    'schemaVersion': 1,
    'evidenceType': 'activity_observation',
    'activity': activity.name,
    'confidenceBucket': _activityConfidenceBucket(confidence),
    'canSupportStopReview': canSupportStopReview,
    'trustedAfterValidationOnly': true,
    'odometerIsGlobalTruth': true,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'activityEvidenceCanCreateCalibration': false,
    'activityEvidenceCanApplyCalibration': false,
    'activityRecognitionRequiresOptIn': true,
    'canCreateOfficialStop': false,
    'canEndTripAutomatically': false,
    'canOverrideOdometer': false,
    'requiresAcceptedVehicleMovement': true,
    'rawSensorPayloadIncluded': false,
    'preciseTimestampIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };
}

String _accuracyBucket(double meters) {
  if (!meters.isFinite || meters <= 0) return 'invalid';
  if (meters <= 10) return 'high';
  if (meters <= 35) return 'usable';
  if (meters <= 65) return 'degraded';
  return 'untrusted';
}

String _speedBucket(double? metersPerSecond) {
  final speed = metersPerSecond;
  if (speed == null) return 'unknown';
  if (!speed.isFinite || speed < 0) return 'invalid';
  if (speed < 0.8) return 'stationary';
  if (speed < 5.6) return 'low_speed';
  if (speed < 20) return 'road_speed';
  if (speed <= 75) return 'highway_speed';
  return 'untrusted';
}

String _timestampBucket(Duration? age) {
  if (age == null) return 'unknown';
  if (age.isNegative) return 'future';
  if (age <= const Duration(minutes: 5)) return 'fresh';
  if (age <= const Duration(minutes: 30)) return 'stale';
  return 'expired';
}

String _activityConfidenceBucket(int confidence) {
  if (confidence < 0 || confidence > 100) return 'invalid';
  if (confidence >= 85) return 'high';
  if (confidence >= 70) return 'review';
  if (confidence >= 40) return 'medium';
  return 'low';
}
