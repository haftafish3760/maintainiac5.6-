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
  Duration get duration => finishedAt.isBefore(startedAt)
      ? Duration.zero
      : finishedAt.difference(startedAt);
  int get beginningOdometer => review.startingOdometer;
  int? get endingOdometerDraft => review.endingOdometerDraft;
  int get vehicleConfigurationRevision => review.vehicleConfigurationRevision;
  double get gpsAssistanceCalibrationMultiplier =>
      review.gpsAssistanceCalibrationMultiplier;
  double get gpsAssistedDistanceMeters =>
      review.engineSnapshot.totalAcceptedMeters;
  double get calibrationAdjustedGpsAssistedDistanceMeters =>
      gpsAssistedDistanceMeters * gpsAssistanceCalibrationMultiplier;
  double get estimatedGapDistanceMeters =>
      review.engineSnapshot.diagnostics.estimatedGapDistanceMeters +
      review.engineSnapshot.signalGaps.fold(
        0,
        (total, gap) => total + gap.estimatedDistanceMeters,
      );
  double get rejectedDistanceMeters =>
      review.engineSnapshot.diagnostics.rejectedDistanceMeters;
  int get recoveryCount => review.recoveryCount < 0 ? 0 : review.recoveryCount;
  bool get requiresTripLogConfirmation => true;
  bool get canFinalizeTripLog => false;
  bool get canConfirmMileage => false;

  Map<String, Object?> toMap() => {
    'schemaVersion': 3,
    'proposalId': proposalId,
    'sourceReviewSchemaVersion': review.schemaVersion,
    'reviewRevision': reviewRevision,
    'vehicleId': vehicleId,
    'profileId': profileId,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'finishedAt': finishedAt.toUtc().toIso8601String(),
    'durationMillis': duration.inMilliseconds,
    'beginningOdometer': beginningOdometer,
    if (endingOdometerDraft != null) 'endingOdometerDraft': endingOdometerDraft,
    'vehicleConfigurationRevision': vehicleConfigurationRevision,
    'gpsAssistanceCalibrationMultiplier': gpsAssistanceCalibrationMultiplier,
    'gpsAssistedDistanceMeters': gpsAssistedDistanceMeters,
    'rawGpsMeasuredDistanceMeters': gpsAssistedDistanceMeters,
    'calibrationAdjustedGpsAssistedDistanceMeters':
        calibrationAdjustedGpsAssistedDistanceMeters,
    'estimatedGapDistanceMeters': estimatedGapDistanceMeters,
    'rejectedDistanceMeters': rejectedDistanceMeters,
    'algorithmVersion': review.engineSnapshot.algorithmVersion,
    'sampleDiagnostics': review.engineSnapshot.diagnostics.toMap(),
    'initialFixAssessment': review.engineSnapshot.initialFixAssessment?.toMap(),
    'initialFixHistory': review.engineSnapshot.initialFixHistory
        .map((item) => item.toMap())
        .toList(),
    'signalGaps': review.engineSnapshot.signalGaps
        .map((item) => item.toMap())
        .toList(),
    'advisories': review.advisories.map((item) => item.toMap()).toList(),
    'tripEvents': review.tripEvents.map((item) => item.toMap()).toList(),
    'manualAdjustments': review.manualAdjustments
        .map((item) => item.toMap())
        .toList(),
    'transitionAudits': review.transitionAudits
        .map((item) => item.toMap())
        .toList(),
    'permissionHistory': review.permissionHistory
        .map((item) => item.toMap())
        .toList(),
    'batteryStateSummary': review.batteryStateSummary?.toMap(),
    'recoveryCount': recoveryCount,
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
