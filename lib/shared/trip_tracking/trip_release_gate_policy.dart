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
    'commercialClaimRequiresSeparateLaunchAudit': true,
    'limitedFieldTrialRequiresRealDeviceEvidence': true,
    'betaEvidenceMustRemainRedacted': true,
    'rawTripRecordsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripReleaseGateSummaryValidation {
  const TripReleaseGateSummaryValidation._({
    required this.isRenderable,
    required this.status,
    required this.reasons,
  });

  factory TripReleaseGateSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final status = _safeStatus(summary['status']);
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (status == null) reasons.add('invalid_release_gate_status');
    if (_safeReasonObject(summary['reasonCode']) == null) {
      reasons.add('invalid_release_gate_reason');
    }
    if (summary['canStartLimitedFieldTrial'] == true &&
        summary['limitedFieldTrialRequiresRealDeviceEvidence'] != true) {
      reasons.add('field_trial_device_evidence_missing');
    }
    if (summary['blocksCommercialClaim'] == false &&
        summary['commercialClaimRequiresSeparateLaunchAudit'] != true) {
      reasons.add('commercial_claim_audit_missing');
    }
    if (summary['syntheticGreenIsNotCommercialProof'] != true ||
        summary['deviceTestingRequiredBeforeProductionClaim'] != true ||
        summary['betaEvidenceMustRemainRedacted'] != true) {
      reasons.add('evidence_boundary_missing');
    }
    if (summary['gpsAssistedTrackingAvailableWithoutMaps'] != true ||
        summary['mapsRequiredForGpsTripTracking'] != false ||
        summary['mapboxFailureBlocksGpsTracking'] != false ||
        summary['mapboxFailureCannotBlockGpsOnlyRegression'] != true ||
        summary['mapboxApisRemainOptionalForGpsAssistedRelease'] != true) {
      reasons.add('maps_not_optional_for_gps_release');
    }
    if (summary['privacyConsentRequiredBeforeFleetTrial'] != true ||
        summary['employeeTrackingRequiresMutualConsent'] != true ||
        summary['employerGodModeAllowed'] != false ||
        summary['authorizationRulesRequiredBeforeFleetRelease'] != true ||
        summary['authenticatedUserStillNeedsRecordAuthorization'] != true) {
      reasons.add('privacy_authorization_boundary_missing');
    }
    if (summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['hiveRemainsOperationalSourceOfTruth'] != true ||
        summary['firestoreMirrorOnly'] != true ||
        summary['releaseGateCanDeleteLocalData'] != false ||
        summary['releaseGateCanConfirmOdometer'] != false ||
        summary['releaseGateCanCreateOfficialStop'] != false) {
      reasons.add('release_gate_can_mutate_trip_truth');
    }
    if (summary['rawTripRecordsIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false) {
      reasons.add('summary_contains_sensitive_trip_material');
    }
    if (summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_text');
    }

    return TripReleaseGateSummaryValidation._(
      isRenderable: reasons.isEmpty,
      status: reasons.isEmpty ? status : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final TripReleaseGateStatus? status;
  final List<String> reasons;
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

TripReleaseGateStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripReleaseGateStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

String? _safeReasonObject(Object? value) {
  if (value is! String) return null;
  return _safeReason(value);
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
