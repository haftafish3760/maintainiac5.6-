import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_field_trial_evidence_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_release_gate_policy.dart';

void main() {
  const syntheticGate = TripReleaseGateDecision(
    status: TripReleaseGateStatus.syntheticReady,
    reasonCode: 'release_gate_synthetic_ready_device_proof_needed',
    canStartSyntheticRegression: true,
    canStartLimitedFieldTrial: false,
    requiresPhysicalDeviceProof: true,
    blocksCommercialClaim: true,
  );
  const fieldGate = TripReleaseGateDecision(
    status: TripReleaseGateStatus.fieldTrialReady,
    reasonCode: 'release_gate_field_trial_ready',
    canStartSyntheticRegression: true,
    canStartLimitedFieldTrial: true,
    requiresPhysicalDeviceProof: false,
    blocksCommercialClaim: false,
  );
  const blockedGate = TripReleaseGateDecision(
    status: TripReleaseGateStatus.blocked,
    reasonCode: 'release_gate_runtime_boundary_blocked',
    canStartSyntheticRegression: true,
    canStartLimitedFieldTrial: false,
    requiresPhysicalDeviceProof: true,
    blocksCommercialClaim: true,
  );

  TripFieldTrialEvidenceDecision evaluate({
    TripReleaseGateDecision gate = fieldGate,
    bool deviceRun = true,
    bool focusedQa = true,
    bool reusableQa = true,
    bool odometerReview = true,
    bool stopReview = true,
    bool privacyConsent = true,
    bool redacted = true,
  }) {
    return TripFieldTrialEvidencePolicy.evaluate(
      releaseGate: gate,
      realDeviceRunCompleted: deviceRun,
      focusedQaGreen: focusedQa,
      reusableQaGreen: reusableQa,
      odometerReviewCompleted: odometerReview,
      stopReviewDispositionCaptured: stopReview,
      privacyConsentVerified: privacyConsent,
      rawLocationRedacted: redacted,
    );
  }

  test('synthetic gate waits for real device run before field evidence', () {
    final decision = evaluate(gate: syntheticGate, deviceRun: false);

    expect(decision.status, TripFieldTrialEvidenceStatus.waitingForDeviceRun);
    expect(decision.canAttachToReleaseGate, isTrue);
    expect(decision.canSupportLimitedFieldTrial, isFalse);
  });

  test(
    'complete redacted device evidence supports limited field trial only',
    () {
      final decision = evaluate();

      expect(decision.status, TripFieldTrialEvidenceStatus.readyToRecord);
      expect(decision.canSupportLimitedFieldTrial, isTrue);
      expect(decision.canSupportCommercialClaim, isFalse);
    },
  );

  test('blocked release gate or redaction failure rejects evidence', () {
    final blocked = evaluate(gate: blockedGate);
    final unredacted = evaluate(redacted: false);

    expect(blocked.status, TripFieldTrialEvidenceStatus.waitingForReleaseGate);
    expect(unredacted.status, TripFieldTrialEvidenceStatus.invalidEvidence);
    expect(unredacted.reasonCode, 'field_trial_evidence_not_redacted');
  });

  test('missing odometer stop or privacy review keeps evidence incomplete', () {
    final missingOdometer = evaluate(odometerReview: false);
    final missingStop = evaluate(stopReview: false);
    final missingPrivacy = evaluate(privacyConsent: false);

    expect(
      missingOdometer.reasonCode,
      'field_trial_review_evidence_incomplete',
    );
    expect(missingStop.canSupportLimitedFieldTrial, isFalse);
    expect(missingPrivacy.canSupportLimitedFieldTrial, isFalse);
  });

  test(
    'safe summary does not expose device, location, route, or token data',
    () {
      final safe = evaluate().toSafeSummary();

      expect(safe['fieldTrialEvidenceRequiresRealDeviceRun'], isTrue);
      expect(safe['syntheticOnlyEvidenceCanSupportCommercialClaim'], isFalse);
      expect(safe['evidenceCanConfirmOdometer'], isFalse);
      expect(safe['evidenceCanCreateOfficialStop'], isFalse);
      expect(safe['preciseLocationIncluded'], isFalse);
      expect(safe['deviceIdentifierIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
    },
  );
}
