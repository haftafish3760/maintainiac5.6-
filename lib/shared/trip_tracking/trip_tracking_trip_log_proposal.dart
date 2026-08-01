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
  String get evidenceId => 'trip-evidence-$proposalId-$reviewRevision';
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
  String get userDecisionState => 'pendingReview';
  String get reviewPresentation => 'needsReviewOrange';
  bool get confidenceScoreShown => false;
  List<String> get evidenceSources => [
    if (gpsAssistedDistanceMeters > 0) 'acceptedGpsDistance',
    if (estimatedGapDistanceMeters > 0) 'estimatedSignalGaps',
    if (rejectedDistanceMeters > 0) 'rejectedLocationEvidence',
    if (review.tripEvents.isNotEmpty) 'tripEvents',
    if (review.manualAdjustments.isNotEmpty) 'manualAdjustments',
    if (review.permissionHistory.isNotEmpty) 'permissionHistory',
    if (recoveryCount > 0) 'recoveryEvidence',
  ];
  String get evidenceStrength {
    if (gpsAssistedDistanceMeters <= 0) return 'limited';
    if (estimatedGapDistanceMeters > 0 || rejectedDistanceMeters > 0) {
      return 'mixed';
    }
    return 'supported';
  }

  String get explanation {
    final distance = (gpsAssistedDistanceMeters / 1609.344).toStringAsFixed(1);
    return 'Maintainiac detected a possible trip lasting '
        '${duration.inMinutes} minutes with $distance GPS-assisted miles. '
        'Review the vehicle, odometer, distance, and business purpose before saving.';
  }

  String get expectedResultIfAccepted =>
      'Creates an editable TripLog draft. The odometer and business classification remain unchanged until you confirm them.';

  String get resultIfIgnored =>
      'The evidence remains available for review; no TripLog, odometer, vehicle, or business history is changed.';

  Map<String, Object?> toMap() => {
    'schemaVersion': 3,
    'proposalId': proposalId,
    'evidenceId': evidenceId,
    'sourceReviewSchemaVersion': review.schemaVersion,
    if (review.ancestry != null) 'ancestry': review.ancestry!.toMap(),
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
    'evidenceSources': evidenceSources,
    'evidenceStrength': evidenceStrength,
    'recommendationConfidence': evidenceStrength,
    'userDecisionState': userDecisionState,
    'reviewPresentation': reviewPresentation,
    'confidenceScoreShown': confidenceScoreShown,
    'affectedModules': const ['tripLog'],
    'explanation': explanation,
    'expectedResultIfAccepted': expectedResultIfAccepted,
    'resultIfIgnored': resultIfIgnored,
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
