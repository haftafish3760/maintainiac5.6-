import 'trip_tracking_session_store.dart';

/// Coordinate-free handoff from GPS assistance to the TripLog owner.
/// A proposal can never confirm mileage or mutate the global odometer.
class TripTrackingTripLogProposal {
  TripTrackingTripLogProposal._({required this.review});

  factory TripTrackingTripLogProposal.fromReview(
    TripTrackingReviewRecord review,
  ) => TripTrackingTripLogProposal._(
    review: TripTrackingReviewRecord.fromMap(review.toMap()),
  );

  final TripTrackingReviewRecord review;

  String get proposalId => review.id;
  int get reviewRevision => review.revision;
  String get vehicleId => review.vehicleId;
  String get profileId => review.effectiveProfileId;
  DateTime get startedAt => review.startedAt;
  DateTime get finishedAt => review.finishedAt;
  int get beginningOdometer => review.startingOdometer;
  int? get endingOdometerDraft => review.endingOdometerDraft;
  double get gpsAssistedDistanceMeters =>
      review.engineSnapshot.totalAcceptedMeters;
  double get estimatedGapDistanceMeters =>
      review.engineSnapshot.diagnostics.estimatedGapDistanceMeters +
      review.engineSnapshot.signalGaps.fold(
        0,
        (total, gap) => total + gap.estimatedDistanceMeters,
      );
  double get rejectedDistanceMeters =>
      review.engineSnapshot.diagnostics.rejectedDistanceMeters;
  bool get requiresTripLogConfirmation => true;
  bool get canFinalizeTripLog => false;
  bool get canConfirmMileage => false;

  Map<String, Object?> toMap() => {
    'schemaVersion': 2,
    'proposalId': proposalId,
    'reviewRevision': reviewRevision,
    'vehicleId': vehicleId,
    'profileId': profileId,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'finishedAt': finishedAt.toUtc().toIso8601String(),
    'beginningOdometer': beginningOdometer,
    if (endingOdometerDraft != null) 'endingOdometerDraft': endingOdometerDraft,
    'gpsAssistedDistanceMeters': gpsAssistedDistanceMeters,
    'estimatedGapDistanceMeters': estimatedGapDistanceMeters,
    'rejectedDistanceMeters': rejectedDistanceMeters,
    'advisories': review.advisories.map((item) => item.toMap()).toList(),
    'tripEvents': review.tripEvents.map((item) => item.toMap()).toList(),
    'manualAdjustments': review.manualAdjustments
        .map((item) => item.toMap())
        .toList(),
    'requiresTripLogConfirmation': true,
    'canFinalizeTripLog': false,
    'canConfirmMileage': false,
    'odometerIsGlobalTruth': true,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
  };
}

abstract interface class TripTrackingTripLogProposalSink {
  /// Implementations must de-duplicate by [TripTrackingTripLogProposal.proposalId].
  Future<void> propose(TripTrackingTripLogProposal proposal);
}
