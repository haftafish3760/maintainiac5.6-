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
    'limitedFieldTrialRequiresCalibrationSignalReview': true,
    'poorGpsCalibrationEvidenceRequired': true,
    'evidenceCanConfirmOdometer': false,
    'evidenceCanCreateOfficialStop': false,
    'evidenceCanDeleteLocalData': false,
    'gpsAssistedTrackingAvailableWithoutMaps': true,
    'mapsRequiredForEvidence': false,
    'mapboxFailureCanInvalidateGpsEvidence': false,
    'odometerIsGlobalTruth': true,
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

class TripFieldTrialEvidenceSummaryValidation {
  const TripFieldTrialEvidenceSummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripFieldTrialEvidenceSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (_safeStatus(summary['status']) == null) {
      reasons.add('invalid_field_trial_status');
    }
    if (_safeReason(summary['reasonCode']?.toString() ?? '') !=
        summary['reasonCode']) {
      reasons.add('invalid_field_trial_reason');
    }
    for (final key in const [
      'canAttachToReleaseGate',
      'canSupportLimitedFieldTrial',
      'canSupportCommercialClaim',
      'fieldTrialEvidenceRequiresRealDeviceRun',
      'syntheticOnlyEvidenceCanSupportCommercialClaim',
      'commercialClaimRequiresSeparateLaunchAudit',
      'limitedFieldTrialRequiresRedactedEvidence',
      'limitedFieldTrialRequiresPrivacyConsent',
      'limitedFieldTrialRequiresOdometerReview',
      'limitedFieldTrialRequiresStopDisposition',
      'limitedFieldTrialRequiresCalibrationSignalReview',
      'poorGpsCalibrationEvidenceRequired',
      'evidenceCanConfirmOdometer',
      'evidenceCanCreateOfficialStop',
      'evidenceCanDeleteLocalData',
      'gpsAssistedTrackingAvailableWithoutMaps',
      'mapsRequiredForEvidence',
      'mapboxFailureCanInvalidateGpsEvidence',
      'odometerIsGlobalTruth',
      'odometerRemainsOfficialMileageTruth',
      'employeeTrackingRequiresMutualConsent',
      'rawTripRecordsIncluded',
      'preciseLocationIncluded',
      'routeGeometryIncluded',
      'deviceIdentifierIncluded',
      'tokensIncluded',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['canSupportCommercialClaim'] != false ||
        summary['syntheticOnlyEvidenceCanSupportCommercialClaim'] != false ||
        summary['commercialClaimRequiresSeparateLaunchAudit'] != true) {
      reasons.add('commercial_claim_boundary_missing');
    }
    if (summary['fieldTrialEvidenceRequiresRealDeviceRun'] != true ||
        summary['limitedFieldTrialRequiresRedactedEvidence'] != true ||
        summary['limitedFieldTrialRequiresPrivacyConsent'] != true ||
        summary['limitedFieldTrialRequiresOdometerReview'] != true ||
        summary['limitedFieldTrialRequiresStopDisposition'] != true ||
        summary['limitedFieldTrialRequiresCalibrationSignalReview'] != true ||
        summary['poorGpsCalibrationEvidenceRequired'] != true) {
      reasons.add('limited_field_trial_evidence_boundary_missing');
    }
    if (summary['evidenceCanConfirmOdometer'] != false ||
        summary['evidenceCanCreateOfficialStop'] != false ||
        summary['evidenceCanDeleteLocalData'] != false ||
        summary['odometerIsGlobalTruth'] != true ||
        summary['odometerRemainsOfficialMileageTruth'] != true) {
      reasons.add('evidence_can_create_trip_truth');
    }
    if (summary['gpsAssistedTrackingAvailableWithoutMaps'] != true ||
        summary['mapsRequiredForEvidence'] != false ||
        summary['mapboxFailureCanInvalidateGpsEvidence'] != false) {
      reasons.add('map_dependency_boundary_missing');
    }
    if (summary['employeeTrackingRequiresMutualConsent'] != true) {
      reasons.add('employee_tracking_consent_boundary_missing');
    }
    if (summary['rawTripRecordsIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['deviceIdentifierIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_field_trial_material');
    }

    return TripFieldTrialEvidenceSummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
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

TripFieldTrialEvidenceStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripFieldTrialEvidenceStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
