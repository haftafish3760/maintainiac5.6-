import 'trip_tracking_models.dart';

enum TripSimulationReadinessStatus {
  readyForFieldTrial,
  needsMoreSyntheticCoverage,
  blockedByUnsafeEvidence,
}

class TripSimulationReadinessDecision {
  const TripSimulationReadinessDecision({
    required this.status,
    required this.reasonCode,
    required this.profile,
    required this.acceptedMiles,
    required this.acceptedDistanceCount,
    required this.rejectedUnsafeCount,
    required this.excludedWalkingCount,
    required this.stopReviewSuggested,
  });

  final TripSimulationReadinessStatus status;
  final String reasonCode;
  final TripTrackingProfile profile;
  final double acceptedMiles;
  final int acceptedDistanceCount;
  final int rejectedUnsafeCount;
  final int excludedWalkingCount;
  final bool stopReviewSuggested;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'profile': profile.name,
    'acceptedMilesBucket': _milesBucket(acceptedMiles),
    'acceptedDistanceCount': _safeCount(acceptedDistanceCount),
    'rejectedUnsafeCount': _safeCount(rejectedUnsafeCount),
    'excludedWalkingCount': _safeCount(excludedWalkingCount),
    'stopReviewSuggested': stopReviewSuggested,
    'readyForSyntheticRegression':
        status != TripSimulationReadinessStatus.blockedByUnsafeEvidence,
    'readyForFieldTrial':
        status == TripSimulationReadinessStatus.readyForFieldTrial,
    'simulationCanCreateOfficialStop': false,
    'simulationCanConfirmOdometer': false,
    'simulationCanDeleteLocalData': false,
    'deviceTestingStillRequiredBeforeCommercialClaim': true,
    'mapsRequiredForSimulation': false,
    'mapboxCanMakeSimulationPass': false,
    'odometerRemainsOfficialMileageTruth': true,
    'rawSamplesIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripSimulationReadinessPolicy {
  const TripSimulationReadinessPolicy._();

  static TripSimulationReadinessDecision evaluate({
    required TripTrackingProfile profile,
    required double acceptedMiles,
    required int acceptedDistanceCount,
    required int rejectedUnsafeCount,
    required int excludedWalkingCount,
    required bool stopReviewSuggested,
    required bool expectedStopReview,
    required bool expectedVehicleMovement,
  }) {
    if (!acceptedMiles.isFinite ||
        acceptedMiles < 0 ||
        rejectedUnsafeCount >= 3) {
      return _decision(
        status: TripSimulationReadinessStatus.blockedByUnsafeEvidence,
        reasonCode: 'simulation_unsafe_evidence_blocked',
        profile: profile,
        acceptedMiles: acceptedMiles,
        acceptedDistanceCount: acceptedDistanceCount,
        rejectedUnsafeCount: rejectedUnsafeCount,
        excludedWalkingCount: excludedWalkingCount,
        stopReviewSuggested: false,
      );
    }

    final movementOk =
        !expectedVehicleMovement ||
        (acceptedMiles > 0 && acceptedDistanceCount >= 2);
    final stopOk = stopReviewSuggested == expectedStopReview;
    if (!movementOk || !stopOk) {
      return _decision(
        status: TripSimulationReadinessStatus.needsMoreSyntheticCoverage,
        reasonCode: !movementOk
            ? 'simulation_vehicle_movement_not_verified'
            : 'simulation_stop_expectation_mismatch',
        profile: profile,
        acceptedMiles: acceptedMiles,
        acceptedDistanceCount: acceptedDistanceCount,
        rejectedUnsafeCount: rejectedUnsafeCount,
        excludedWalkingCount: excludedWalkingCount,
        stopReviewSuggested: stopReviewSuggested,
      );
    }

    return _decision(
      status: TripSimulationReadinessStatus.readyForFieldTrial,
      reasonCode: 'simulation_ready_for_field_trial',
      profile: profile,
      acceptedMiles: acceptedMiles,
      acceptedDistanceCount: acceptedDistanceCount,
      rejectedUnsafeCount: rejectedUnsafeCount,
      excludedWalkingCount: excludedWalkingCount,
      stopReviewSuggested: stopReviewSuggested,
    );
  }
}

TripSimulationReadinessDecision _decision({
  required TripSimulationReadinessStatus status,
  required String reasonCode,
  required TripTrackingProfile profile,
  required double acceptedMiles,
  required int acceptedDistanceCount,
  required int rejectedUnsafeCount,
  required int excludedWalkingCount,
  required bool stopReviewSuggested,
}) {
  return TripSimulationReadinessDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    profile: profile,
    acceptedMiles: acceptedMiles.isFinite
        ? acceptedMiles.clamp(0, 2500).toDouble()
        : 0,
    acceptedDistanceCount: _safeCount(acceptedDistanceCount),
    rejectedUnsafeCount: _safeCount(rejectedUnsafeCount),
    excludedWalkingCount: _safeCount(excludedWalkingCount),
    stopReviewSuggested: stopReviewSuggested,
  );
}

int _safeCount(int value) {
  if (value <= 0) return 0;
  return value > 100000 ? 100000 : value;
}

String _milesBucket(double miles) {
  if (!miles.isFinite || miles <= 0) return 'none';
  if (miles < 1) return 'under_1_mile';
  if (miles < 25) return '1_to_25_miles';
  if (miles < 250) return '25_to_250_miles';
  return 'over_250_miles';
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'simulation_unsafe_evidence_blocked' =>
      'simulation_unsafe_evidence_blocked',
    'simulation_vehicle_movement_not_verified' =>
      'simulation_vehicle_movement_not_verified',
    'simulation_stop_expectation_mismatch' =>
      'simulation_stop_expectation_mismatch',
    'simulation_ready_for_field_trial' => 'simulation_ready_for_field_trial',
    _ => 'simulation_unsafe_evidence_blocked',
  };
}
