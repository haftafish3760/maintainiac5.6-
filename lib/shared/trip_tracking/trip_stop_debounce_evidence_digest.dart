import 'trip_tracking_models.dart';
import 'trip_walking_evidence_recency_guard.dart';

class TripStopDebounceEvidenceDigest {
  const TripStopDebounceEvidenceDigest({
    required this.profile,
    required this.acceptedDistanceCount,
    required this.rejectedDriftCount,
    required this.rejectedUnsafeCount,
    required this.walkingEvidenceCount,
    required this.stationaryDuration,
    required this.walkingEvidenceSpan,
    required this.minimumStationary,
    required this.minimumWalkingEvidenceSpacing,
    required this.acceptedVehicleMovementObserved,
    required this.providerValuesUsable,
    required this.walkingBurstProtected,
    required this.walkingEvidenceCurrent,
    required this.walkingEvidenceRecency,
  });

  final TripTrackingProfile profile;
  final int acceptedDistanceCount;
  final int rejectedDriftCount;
  final int rejectedUnsafeCount;
  final int walkingEvidenceCount;
  final Duration stationaryDuration;
  final Duration walkingEvidenceSpan;
  final Duration minimumStationary;
  final Duration minimumWalkingEvidenceSpacing;
  final bool acceptedVehicleMovementObserved;
  final bool providerValuesUsable;
  final bool walkingBurstProtected;
  final bool walkingEvidenceCurrent;
  final TripWalkingEvidenceRecencyDecision walkingEvidenceRecency;

  bool get hasAcceptedVehicleMovement =>
      acceptedVehicleMovementObserved && acceptedDistanceCount > 0;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'profile': profile.name,
    'acceptedDistanceCount': _safeCount(acceptedDistanceCount),
    'rejectedDriftCount': _safeCount(rejectedDriftCount),
    'rejectedUnsafeCount': _safeCount(rejectedUnsafeCount),
    'walkingEvidenceCount': _safeCount(walkingEvidenceCount),
    'stationarySeconds': _safeDuration(stationaryDuration).inSeconds,
    'walkingEvidenceSpanSeconds': _safeDuration(walkingEvidenceSpan).inSeconds,
    'minimumStationarySeconds': _safeDuration(minimumStationary).inSeconds,
    'minimumWalkingEvidenceSpacingSeconds': _safeDuration(
      minimumWalkingEvidenceSpacing,
    ).inSeconds,
    'hasAcceptedVehicleMovement': hasAcceptedVehicleMovement,
    'providerValuesUsable': providerValuesUsable,
    'walkingBurstProtected': walkingBurstProtected,
    'walkingEvidenceCurrent': walkingEvidenceCurrent,
    'walkingEvidenceRecency': walkingEvidenceRecency.toSafeDashboardMap(),
    'rawSamplesIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

int _safeCount(int value) {
  if (value <= 0) return 0;
  return value > 100000 ? 100000 : value;
}

Duration _safeDuration(Duration value) {
  if (value.isNegative) return Duration.zero;
  return value > const Duration(hours: 24) ? const Duration(hours: 24) : value;
}
