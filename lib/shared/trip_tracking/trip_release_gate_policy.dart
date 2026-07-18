import 'trip_commercial_readiness_policy.dart';
import 'trip_lifecycle_supervisor_policy.dart';
import 'trip_location_visibility_consent_policy.dart';
import 'trip_mapbox_request_boundary_policy.dart';
import 'trip_simulation_readiness_policy.dart';

enum TripReleaseGateStatus {
  syntheticReady,
  fieldTrialReady,
  needsMoreHardening,
  blocked,
}

class TripReleaseGateDecision {
  const TripReleaseGateDecision({
    required this.status,
    required this.reasonCode,
    required this.canStartSyntheticRegression,
    required this.canStartLimitedFieldTrial,
    required this.requiresPhysicalDeviceProof,
    required this.blocksCommercialClaim,
  });

  final TripReleaseGateStatus status;
  final String reasonCode;
  final bool canStartSyntheticRegression;
  final bool canStartLimitedFieldTrial;
  final bool requiresPhysicalDeviceProof;
  final bool blocksCommercialClaim;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'canStartSyntheticRegression': canStartSyntheticRegression,
    'canStartLimitedFieldTrial': canStartLimitedFieldTrial,
    'requiresPhysicalDeviceProof': requiresPhysicalDeviceProof,
    'blocksCommercialClaim': blocksCommercialClaim,
    'syntheticGreenIsNotCommercialProof': true,
    'deviceTestingRequiredBeforeProductionClaim': true,
    'gpsAssistedTrackingAvailableWithoutMaps': true,
    'mapsRequiredForGpsTripTracking': false,
    'mapboxFailureBlocksGpsTracking': false,
    'mapboxFailureCannotBlockGpsOnlyRegression': true,
    'mapboxApisRemainOptionalForGpsAssistedRelease': true,
    'privacyConsentRequiredBeforeFleetTrial': true,
    'employeeTrackingRequiresMutualConsent': true,
    'employerGodModeAllowed': false,
    'authorizationRulesRequiredBeforeFleetRelease': true,
    'authenticatedUserStillNeedsRecordAuthorization': true,
    'odometerRemainsOfficialMileageTruth': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'releaseGateCanDeleteLocalData': false,
    'releaseGateCanConfirmOdometer': false,
    'releaseGateCanCreateOfficialStop': false,
    'rawTripRecordsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripReleaseGatePolicy {
  const TripReleaseGatePolicy._();

  static TripReleaseGateDecision evaluate({
    required Iterable<TripSimulationReadinessDecision> simulations,
    required TripCommercialReadinessDecision commercialReadiness,
    required TripLifecycleSupervisorDecision lifecycleSupervisor,
    required TripLocationVisibilityConsentDecision visibilityConsent,
    required TripMapboxRequestBoundaryDecision mapboxBoundary,
    required bool focusedQaGreen,
    required bool reusableQaGreen,
    required bool nativeDeviceProofAvailable,
    required bool requestingCommercialClaim,
  }) {
    final simulationList = simulations.toList(growable: false);
    if (simulationList.isEmpty || !focusedQaGreen || !reusableQaGreen) {
      return _decision(
        status: TripReleaseGateStatus.needsMoreHardening,
        reasonCode: simulationList.isEmpty
            ? 'release_gate_missing_simulations'
            : 'release_gate_qa_not_green',
        canStartSyntheticRegression: false,
        canStartLimitedFieldTrial: false,
        requiresPhysicalDeviceProof: true,
        blocksCommercialClaim: true,
      );
    }

    final blockedSimulation = simulationList.any(
      (item) =>
          item.status == TripSimulationReadinessStatus.blockedByUnsafeEvidence,
    );
    final incompleteSimulation = simulationList.any(
      (item) => item.status != TripSimulationReadinessStatus.readyForFieldTrial,
    );
    if (blockedSimulation) {
      return _decision(
        status: TripReleaseGateStatus.blocked,
        reasonCode: 'release_gate_simulation_blocked',
        canStartSyntheticRegression: true,
        canStartLimitedFieldTrial: false,
        requiresPhysicalDeviceProof: true,
        blocksCommercialClaim: true,
      );
    }
    if (incompleteSimulation) {
      return _decision(
        status: TripReleaseGateStatus.needsMoreHardening,
        reasonCode: 'release_gate_more_synthetic_coverage_needed',
        canStartSyntheticRegression: true,
        canStartLimitedFieldTrial: false,
        requiresPhysicalDeviceProof: true,
        blocksCommercialClaim: true,
      );
    }

    if (commercialReadiness.status == TripCommercialReadinessStatus.blocked ||
        lifecycleSupervisor.status == TripLifecycleSupervisorStatus.blocked ||
        lifecycleSupervisor.status ==
            TripLifecycleSupervisorStatus.promptUser ||
        visibilityConsent.status != TripLocationVisibilityStatus.allowed) {
      return _decision(
        status: TripReleaseGateStatus.blocked,
        reasonCode: 'release_gate_runtime_boundary_blocked',
        canStartSyntheticRegression: true,
        canStartLimitedFieldTrial: false,
        requiresPhysicalDeviceProof: true,
        blocksCommercialClaim: true,
      );
    }

    final mapsOptional =
        mapboxBoundary.status != TripMapboxRequestBoundaryStatus.rejected;
    if (!mapsOptional) {
      return _decision(
        status: TripReleaseGateStatus.needsMoreHardening,
        reasonCode: 'release_gate_map_boundary_needs_hardening',
        canStartSyntheticRegression: true,
        canStartLimitedFieldTrial: true,
        requiresPhysicalDeviceProof: true,
        blocksCommercialClaim: true,
      );
    }

    if (!nativeDeviceProofAvailable) {
      return _decision(
        status: TripReleaseGateStatus.syntheticReady,
        reasonCode: 'release_gate_synthetic_ready_device_proof_needed',
        canStartSyntheticRegression: true,
        canStartLimitedFieldTrial: false,
        requiresPhysicalDeviceProof: true,
        blocksCommercialClaim: true,
      );
    }

    return _decision(
      status: TripReleaseGateStatus.fieldTrialReady,
      reasonCode: requestingCommercialClaim
          ? 'release_gate_field_trial_ready_not_commercial'
          : 'release_gate_field_trial_ready',
      canStartSyntheticRegression: true,
      canStartLimitedFieldTrial: true,
      requiresPhysicalDeviceProof: false,
      blocksCommercialClaim: requestingCommercialClaim,
    );
  }
}

TripReleaseGateDecision _decision({
  required TripReleaseGateStatus status,
  required String reasonCode,
  required bool canStartSyntheticRegression,
  required bool canStartLimitedFieldTrial,
  required bool requiresPhysicalDeviceProof,
  required bool blocksCommercialClaim,
}) {
  return TripReleaseGateDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    canStartSyntheticRegression: canStartSyntheticRegression,
    canStartLimitedFieldTrial: canStartLimitedFieldTrial,
    requiresPhysicalDeviceProof: requiresPhysicalDeviceProof,
    blocksCommercialClaim: blocksCommercialClaim,
  );
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'release_gate_missing_simulations' => 'release_gate_missing_simulations',
    'release_gate_qa_not_green' => 'release_gate_qa_not_green',
    'release_gate_simulation_blocked' => 'release_gate_simulation_blocked',
    'release_gate_more_synthetic_coverage_needed' =>
      'release_gate_more_synthetic_coverage_needed',
    'release_gate_runtime_boundary_blocked' =>
      'release_gate_runtime_boundary_blocked',
    'release_gate_map_boundary_needs_hardening' =>
      'release_gate_map_boundary_needs_hardening',
    'release_gate_synthetic_ready_device_proof_needed' =>
      'release_gate_synthetic_ready_device_proof_needed',
    'release_gate_field_trial_ready_not_commercial' =>
      'release_gate_field_trial_ready_not_commercial',
    'release_gate_field_trial_ready' => 'release_gate_field_trial_ready',
    _ => 'release_gate_runtime_boundary_blocked',
  };
}
