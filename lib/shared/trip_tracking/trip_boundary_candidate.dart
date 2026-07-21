import 'trip_tracking_models.dart';

class TripBoundaryCandidate {
  const TripBoundaryCandidate({
    required this.id,
    required this.sessionId,
    required this.vehicleId,
    required this.profile,
    required this.proposedBoundaryAt,
    required this.detectedAt,
    required this.confidence,
    required this.sourceAdvisoryId,
  });

  final String id;
  final String sessionId;
  final String vehicleId;
  final TripTrackingProfile profile;
  final DateTime proposedBoundaryAt;
  final DateTime detectedAt;
  final TripTrackingConfidence confidence;
  final String sourceAdvisoryId;

  bool get requiresUserReview => true;
  bool get canFinalizeTrip => false;
  bool get canSplitTripAutomatically => false;
  bool get canChangeMileage => false;
  bool get canWriteTripLog => false;

  Map<String, Object?> toSafeSummary() => {
    'id': id,
    'sessionId': sessionId,
    'vehicleId': vehicleId,
    'profile': profile.name,
    'proposedBoundaryAt': proposedBoundaryAt.toUtc().toIso8601String(),
    'detectedAt': detectedAt.toUtc().toIso8601String(),
    'confidence': confidence.name,
    'sourceAdvisoryId': sourceAdvisoryId,
    'requiresUserReview': true,
    'canFinalizeTrip': false,
    'canSplitTripAutomatically': false,
    'canChangeMileage': false,
    'canWriteTripLog': false,
    'coordinatesIncluded': false,
  };
}

class TripBoundaryCandidateResolver {
  const TripBoundaryCandidateResolver._();

  static List<TripBoundaryCandidate> fromAdvisories(
    Iterable<TripTrackingAdvisoryEvent> advisories,
  ) => List.unmodifiable(
    advisories
        .where(
          (event) =>
              event.type == TripTrackingAdvisoryType.probableStop &&
              event.disposition == TripTrackingAdvisoryDisposition.pending,
        )
        .map(
          (event) => TripBoundaryCandidate(
            id: '${event.id}:boundary',
            sessionId: event.sessionId,
            vehicleId: event.vehicleId,
            profile: event.profile,
            proposedBoundaryAt:
                event.evidenceStartedAt.isAfter(event.detectedAt)
                ? event.detectedAt
                : event.evidenceStartedAt,
            detectedAt: event.detectedAt,
            confidence: event.confidence,
            sourceAdvisoryId: event.id,
          ),
        ),
  );
}
