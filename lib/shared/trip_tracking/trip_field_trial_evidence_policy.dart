import 'trip_release_gate_policy.dart';

enum TripFieldTrialEvidenceStatus {
  readyToRecord,
  waitingForReleaseGate,
  waitingForDeviceRun,
  invalidEvidence,
}

class TripFieldTrialEvidenceDecision {
  const TripFieldTrialEvidenceDecision({
    required this.status,
    required this.reasonCode,
    required this.canAttachToReleaseGate,
    required this.canSupportLimitedFieldTrial,
    required this.canSupportCommercialClaim,
  });

  final TripFieldTrialEvidenceStatus status;
  final String reasonCode;
  final bool canAttachToReleaseGate;
  final bool canSupportLimitedFieldTrial;
  final bool canSupportCommercialClaim;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'canAttachToReleaseGate': canAttachToReleaseGate,
    'canSupportLimitedFieldTrial': canSupportLimitedFieldTrial,
    'canSupportCommercialClaim': canSupportCommercialClaim,
    'fieldTrialEvidenceRequiresRealDeviceRun': true,
    'syntheticOnlyEvidenceCanSupportCommercialClaim': false,
    'commercialClaimRequiresSeparateLaunchAudit': true,
    'limitedFieldTrialRequiresRedactedEvidence': true,
    'limitedFieldTrialRequiresPrivacyConsent': true,
    'limitedFieldTrialRequiresOdometerReview': true,
    'limitedFieldTrialRequiresStopDisposition': true,
    'evidenceCanConfirmOdometer': false,
    'evidenceCanCreateOfficialStop': false,
    'evidenceCanDeleteLocalData': false,
    'gpsAssistedTrackingAvailableWithoutMaps': true,
    'mapsRequiredForEvidence': false,
    'mapboxFailureCanInvalidateGpsEvidence': false,
    'odometerRemainsOfficialMileageTruth': true,
    'employeeTrackingRequiresMutualConsent': true,
    'rawTripRecordsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'deviceIdentifierIncluded': false,
    'tokensIncluded': false,
  };
}

class TripFieldTrialEvidencePolicy {
  const TripFieldTrialEvidencePolicy._();

  static TripFieldTrialEvidenceDecision evaluate({
    required TripReleaseGateDecision releaseGate,
    required bool realDeviceRunCompleted,
    required bool focusedQaGreen,
    required bool reusableQaGreen,
    required bool odometerReviewCompleted,
    required bool stopReviewDispositionCaptured,
    required bool privacyConsentVerified,
    required bool rawLocationRedacted,
  }) {
    if (!focusedQaGreen || !reusableQaGreen || !rawLocationRedacted) {
      return _decision(
        status: TripFieldTrialEvidenceStatus.invalidEvidence,
        reasonCode: !rawLocationRedacted
            ? 'field_trial_evidence_not_redacted'
            : 'field_trial_qa_not_green',
        canAttachToReleaseGate: false,
        canSupportLimitedFieldTrial: false,
        canSupportCommercialClaim: false,
      );
    }
    if (releaseGate.status == TripReleaseGateStatus.blocked ||
        releaseGate.status == TripReleaseGateStatus.needsMoreHardening) {
      return _decision(
        status: TripFieldTrialEvidenceStatus.waitingForReleaseGate,
        reasonCode: 'field_trial_release_gate_not_ready',
        canAttachToReleaseGate: false,
        canSupportLimitedFieldTrial: false,
        canSupportCommercialClaim: false,
      );
    }
    if (!realDeviceRunCompleted) {
      return _decision(
        status: TripFieldTrialEvidenceStatus.waitingForDeviceRun,
        reasonCode: 'field_trial_real_device_run_required',
        canAttachToReleaseGate: true,
        canSupportLimitedFieldTrial: false,
        canSupportCommercialClaim: false,
      );
    }
    final evidenceComplete =
        odometerReviewCompleted &&
        stopReviewDispositionCaptured &&
        privacyConsentVerified;
    return _decision(
      status: evidenceComplete
          ? TripFieldTrialEvidenceStatus.readyToRecord
          : TripFieldTrialEvidenceStatus.waitingForDeviceRun,
      reasonCode: evidenceComplete
          ? 'field_trial_evidence_ready'
          : 'field_trial_review_evidence_incomplete',
      canAttachToReleaseGate: true,
      canSupportLimitedFieldTrial: evidenceComplete,
      canSupportCommercialClaim: false,
    );
  }
}

TripFieldTrialEvidenceDecision _decision({
  required TripFieldTrialEvidenceStatus status,
  required String reasonCode,
  required bool canAttachToReleaseGate,
  required bool canSupportLimitedFieldTrial,
  required bool canSupportCommercialClaim,
}) {
  return TripFieldTrialEvidenceDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    canAttachToReleaseGate: canAttachToReleaseGate,
    canSupportLimitedFieldTrial: canSupportLimitedFieldTrial,
    canSupportCommercialClaim: canSupportCommercialClaim,
  );
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'field_trial_evidence_not_redacted' => 'field_trial_evidence_not_redacted',
    'field_trial_qa_not_green' => 'field_trial_qa_not_green',
    'field_trial_release_gate_not_ready' =>
      'field_trial_release_gate_not_ready',
    'field_trial_real_device_run_required' =>
      'field_trial_real_device_run_required',
    'field_trial_review_evidence_incomplete' =>
      'field_trial_review_evidence_incomplete',
    'field_trial_evidence_ready' => 'field_trial_evidence_ready',
    _ => 'field_trial_evidence_not_redacted',
  };
}
