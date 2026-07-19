import 'trip_stop_review_open_guard.dart';

class TripStopReviewOpenSummaryValidation {
  static const bool odometerIsGlobalTruth = true;

  const TripStopReviewOpenSummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripStopReviewOpenSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final status = _safeStatus(summary['status']);
    if (summary['schemaVersion'] != 1) reasons.add('unsupported_schema');
    if (status == null) reasons.add('invalid_open_status');
    if (summary['mayOpenReview'] is! bool) reasons.add('may_open_not_bool');
    for (final key in _trueClaims) {
      if (summary[key] != true) reasons.add('${key}_not_true');
    }
    for (final key in _falseClaims) {
      if (summary[key] != false) reasons.add('${key}_not_false');
    }
    reasons.addAll(_statusAuthorityRisks(summary, status));
    if (summary.values.any(_looksSensitive)) {
      reasons.add('open_summary_contains_sensitive_text');
    }
    return TripStopReviewOpenSummaryValidation._(
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
  'requiresLocalTripLog',
  'requiresAcceptedVehicleMovement',
  'currentVehicleSpeedMustAllowStopReview',
  'movingVehicleCannotOpenStopReview',
  'addressRequiresUserConfirmation',
  'employeeTrackingRequiresMutualConsent',
];

const _falseClaims = [
  'createsOfficialStop',
  'remoteCanOpenStopReview',
  'firestoreCanOpenStopReview',
  'cloudFunctionCanOpenStopReview',
  'mapboxCanOpenStopReview',
  'mapboxCanInferOfficialStopAddress',
  'activityRecognitionCanOpenStopReviewWithoutValidation',
  'employerGodModeAllowed',
  'stopReviewPayloadCanExposeLiveLocation',
  'canEndTripAutomatically',
  'canReplaceOdometer',
  'tokensIncluded',
  'coordinatesIncluded',
  'routeGeometryIncluded',
  'rawSamplesIncluded',
];

List<String> _statusAuthorityRisks(
  Map<String, Object?> summary,
  TripStopReviewOpenStatus? status,
) {
  if (status == null) return const [];
  final mayOpen = summary['mayOpenReview'];
  final ownerValid = summary['ownerValid'];
  final sessionValid = summary['sessionValid'];
  final duplicate = summary['duplicatePendingReview'];
  final clockValid = summary['clockValid'];
  if (mayOpen is! bool ||
      ownerValid is! bool ||
      sessionValid is! bool ||
      duplicate is! bool ||
      clockValid is! bool) {
    return const ['invalid_open_authority_boolean'];
  }
  final risks = <String>[];
  if (mayOpen && status != TripStopReviewOpenStatus.ready) {
    risks.add('open_review_authority_mismatch');
  }
  if (status == TripStopReviewOpenStatus.ready &&
      (!mayOpen || !ownerValid || !sessionValid || duplicate || !clockValid)) {
    risks.add('open_ready_authority_mismatch');
  }
  if (status != TripStopReviewOpenStatus.ready && summary['reviewId'] != null) {
    risks.add('blocked_review_id_exposed');
  }
  return risks;
}

TripStopReviewOpenStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripStopReviewOpenStatus.values) {
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
