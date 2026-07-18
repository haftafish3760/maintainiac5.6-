import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_commercial_readiness_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_lifecycle_supervisor_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_location_visibility_consent_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_mapbox_request_boundary_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_release_gate_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_simulation_readiness_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  const simulationReady = TripSimulationReadinessDecision(
    status: TripSimulationReadinessStatus.readyForFieldTrial,
    reasonCode: 'simulation_ready_for_field_trial',
    profile: TripTrackingProfile.deliveryVehicle,
    acceptedMiles: 1.2,
    acceptedDistanceCount: 4,
    rejectedUnsafeCount: 0,
    excludedWalkingCount: 3,
    stopReviewSuggested: true,
  );
  const simulationBlocked = TripSimulationReadinessDecision(
    status: TripSimulationReadinessStatus.blockedByUnsafeEvidence,
    reasonCode: 'simulation_unsafe_evidence_blocked',
    profile: TripTrackingProfile.deliveryVehicle,
    acceptedMiles: 0,
    acceptedDistanceCount: 0,
    rejectedUnsafeCount: 3,
    excludedWalkingCount: 0,
    stopReviewSuggested: false,
  );
  const commercialReady = TripCommercialReadinessDecision(
    status: TripCommercialReadinessStatus.readyWithReview,
    scenario: TripCommercialDriverScenario.delivery,
    reasonCode: 'commercial_ready_with_review',
    canStartOrContinueTrip: true,
    manualReviewRecommended: true,
    mapsOptionalAndSafe: true,
    employeePrivacySafe: true,
  );
  const commercialBlocked = TripCommercialReadinessDecision(
    status: TripCommercialReadinessStatus.blocked,
    scenario: TripCommercialDriverScenario.delivery,
    reasonCode: 'privacy_consent_blocked',
    canStartOrContinueTrip: false,
    manualReviewRecommended: true,
    mapsOptionalAndSafe: true,
    employeePrivacySafe: false,
  );
  const lifecycleContinue = TripLifecycleSupervisorDecision(
    status: TripLifecycleSupervisorStatus.continueTracking,
    reasonCode: 'supervisor_continue_tracking',
    nextLifecycle: TripTrackingSessionLifecycleState.active,
    shouldKeepForegroundServiceAlive: true,
    shouldRequestUserAction: false,
    canReplayPendingSample: false,
    canUploadBackupMirror: true,
  );
  const visibilityPrivate = TripLocationVisibilityConsentDecision(
    status: TripLocationVisibilityStatus.allowed,
    mode: TripLocationVisibilityMode.personalBackupOnly,
    reasonCode: 'personal_visibility_only',
    canShowLiveLocationToOrganization: false,
    canMirrorReviewedMileageToOrganization: false,
    canShowRouteHistoryToOrganization: false,
  );
  const mapsGpsOnly = TripMapboxRequestBoundaryDecision(
    status: TripMapboxRequestBoundaryStatus.fallbackGpsOnly,
    reasonCode: 'map_preview_not_enabled',
    canCallMapbox: false,
    canRenderMapAssist: false,
    shouldUseGpsOnlyFallback: true,
    shouldRetryLater: false,
    requestsRemainingInWindow: 10,
  );

  TripReleaseGateDecision evaluate({
    List<TripSimulationReadinessDecision> simulations = const [simulationReady],
    TripCommercialReadinessDecision commercial = commercialReady,
    TripLifecycleSupervisorDecision lifecycle = lifecycleContinue,
    TripLocationVisibilityConsentDecision visibility = visibilityPrivate,
    TripMapboxRequestBoundaryDecision maps = mapsGpsOnly,
    bool focusedQaGreen = true,
    bool reusableQaGreen = true,
    bool deviceProof = false,
    bool commercialClaim = false,
  }) {
    return TripReleaseGatePolicy.evaluate(
      simulations: simulations,
      commercialReadiness: commercial,
      lifecycleSupervisor: lifecycle,
      visibilityConsent: visibility,
      mapboxBoundary: maps,
      focusedQaGreen: focusedQaGreen,
      reusableQaGreen: reusableQaGreen,
      nativeDeviceProofAvailable: deviceProof,
      requestingCommercialClaim: commercialClaim,
    );
  }

  test(
    'green synthetic evidence is not enough for field trial without device proof',
    () {
      final decision = evaluate();

      expect(decision.status, TripReleaseGateStatus.syntheticReady);
      expect(decision.canStartSyntheticRegression, isTrue);
      expect(decision.canStartLimitedFieldTrial, isFalse);
      expect(decision.requiresPhysicalDeviceProof, isTrue);
    },
  );

  test('device proof allows limited field trial but not commercial claim', () {
    final fieldTrial = evaluate(deviceProof: true);
    final commercialClaim = evaluate(deviceProof: true, commercialClaim: true);

    expect(fieldTrial.status, TripReleaseGateStatus.fieldTrialReady);
    expect(fieldTrial.canStartLimitedFieldTrial, isTrue);
    expect(fieldTrial.blocksCommercialClaim, isFalse);
    expect(commercialClaim.blocksCommercialClaim, isTrue);
  });

  test('missing QA or simulations needs more hardening', () {
    final noSimulation = evaluate(simulations: const []);
    final qaRed = evaluate(reusableQaGreen: false);

    expect(noSimulation.status, TripReleaseGateStatus.needsMoreHardening);
    expect(noSimulation.reasonCode, 'release_gate_missing_simulations');
    expect(qaRed.reasonCode, 'release_gate_qa_not_green');
  });

  test('unsafe simulation or runtime privacy blocks release gate', () {
    final unsafe = evaluate(simulations: const [simulationBlocked]);
    final runtime = evaluate(commercial: commercialBlocked);

    expect(unsafe.status, TripReleaseGateStatus.blocked);
    expect(unsafe.reasonCode, 'release_gate_simulation_blocked');
    expect(runtime.status, TripReleaseGateStatus.blocked);
    expect(runtime.reasonCode, 'release_gate_runtime_boundary_blocked');
  });

  test('safe summary keeps release gate non-authoritative', () {
    final safe = evaluate(deviceProof: true).toSafeDashboardMap();

    expect(safe['syntheticGreenIsNotCommercialProof'], isTrue);
    expect(safe['deviceTestingRequiredBeforeProductionClaim'], isTrue);
    expect(safe['gpsAssistedTrackingAvailableWithoutMaps'], isTrue);
    expect(safe['mapsRequiredForGpsTripTracking'], isFalse);
    expect(safe['mapboxFailureCannotBlockGpsOnlyRegression'], isTrue);
    expect(safe['mapboxApisRemainOptionalForGpsAssistedRelease'], isTrue);
    expect(safe['employeeTrackingRequiresMutualConsent'], isTrue);
    expect(safe['authorizationRulesRequiredBeforeFleetRelease'], isTrue);
    expect(safe['authenticatedUserStillNeedsRecordAuthorization'], isTrue);
    expect(safe['releaseGateCanConfirmOdometer'], isFalse);
    expect(safe['releaseGateCanCreateOfficialStop'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
  });
}
