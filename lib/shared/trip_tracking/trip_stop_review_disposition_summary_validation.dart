import 'trip_stop_review_disposition_guard.dart';

class TripStopReviewDispositionSummaryValidation {
  const TripStopReviewDispositionSummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripStopReviewDispositionSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final status = _safeStatus(summary['status']);
    if (summary['schemaVersion'] != 1) reasons.add('unsupported_schema');
    if (status == null) reasons.add('invalid_disposition_status');
    if (summary['mayApplyDisposition'] is! bool) {
      reasons.add('may_apply_not_bool');
    }
    for (final key in _trueClaims) {
      if (summary[key] != true) reasons.add('${key}_not_true');
    }
    for (final key in _falseClaims) {
      if (summary[key] != false) reasons.add('${key}_not_false');
    }
    reasons.addAll(_statusAuthorityRisks(summary, status));
    if (summary.values.any(_looksSensitive)) {
      reasons.add('disposition_summary_contains_sensitive_text');
    }
    return TripStopReviewDispositionSummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
}

const _trueClaims = [
  'requiresAuthenticatedOwner',
  'requiresLocalSessionRevision',
  'requiresLocalSessionAvailable',
  'requiresAcceptedVehicleMovement',
  'requiresPendingReview',
  'requiresFinalUserDisposition',
  'requiresLocalUserReviewConfirmation',
  'requiresLocalUserReviewSource',
  'confirmedDispositionCanCreateStopAfterUserAcceptance',
  'correctedRequiresSeparateUserEditedTripLog',
  'odometerIsGlobalTruth',
  'addressRequiresUserConfirmation',
  'employeeTrackingRequiresMutualConsent',
];

const _falseClaims = [
  'createsOfficialStop',
  'rejectedOrDismissedCreatesStop',
  'remoteCanMarkStopOfficial',
  'remoteCanApplyDisposition',
  'firestoreCanApplyDisposition',
  'cloudFunctionCanApplyDisposition',
  'mapboxCanApplyDisposition',
  'mapboxCanInferOfficialStopAddress',
  'activityRecognitionCanApplyDisposition',
  'employerGodModeAllowed',
  'dispositionPayloadCanExposeLiveLocation',
  'canEndTripAutomatically',
  'canReplaceOdometer',
  'tokensIncluded',
  'coordinatesIncluded',
  'routeGeometryIncluded',
  'rawSamplesIncluded',
];

List<String> _statusAuthorityRisks(
  Map<String, Object?> summary,
  TripStopReviewDispositionStatus? status,
) {
  if (status == null) return const [];
  final mayApply = summary['mayApplyDisposition'];
  final ownerValid = summary['ownerValid'];
  final sessionValid = summary['sessionValid'];
  final localBoundary = summary['localCommitBoundaryValid'];
  final clockValid = summary['clockValid'];
  if (mayApply is! bool ||
      ownerValid is! bool ||
      sessionValid is! bool ||
      localBoundary is! bool ||
      clockValid is! bool) {
    return const ['invalid_disposition_authority_boolean'];
  }
  if (mayApply && status != TripStopReviewDispositionStatus.ready) {
    return const ['disposition_apply_authority_mismatch'];
  }
  if (status == TripStopReviewDispositionStatus.ready &&
      (!mayApply ||
          !ownerValid ||
          !sessionValid ||
          !localBoundary ||
          !clockValid)) {
    return const ['disposition_ready_authority_mismatch'];
  }
  return const [];
}

TripStopReviewDispositionStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripStopReviewDispositionStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  return value.startsWith('pk.') ||
      value.startsWith('sk.') ||
      RegExp(r'-?\d{1,3}\.\d{5,}').hasMatch(value);
}
