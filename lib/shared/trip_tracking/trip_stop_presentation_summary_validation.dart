import 'trip_stop_presentation_policy.dart';

class TripStopPresentationSummaryValidation {
  const TripStopPresentationSummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripStopPresentationSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final surface = _safeSurface(summary['surface']);
    final reason = _safeReason(summary['reason']);
    if (summary['schemaVersion'] != 1) reasons.add('unsupported_schema');
    if (surface == null) reasons.add('invalid_presentation_surface');
    if (reason == null) reasons.add('invalid_presentation_reason');
    for (final key in _trueClaims) {
      if (summary[key] != true) reasons.add('${key}_not_true');
    }
    for (final key in _falseClaims) {
      if (summary[key] != false) reasons.add('${key}_not_false');
    }
    if (summary['requiresUserReview'] is! bool ||
        summary['canShowManualFallback'] is! bool ||
        summary['canShowReviewPrompt'] is! bool ||
        summary['shouldDebounceAgain'] is! bool) {
      reasons.add('invalid_presentation_boolean');
    }
    reasons.addAll(
      _statusAuthorityRisks(summary: summary, surface: surface, reason: reason),
    );
    if (summary.values.any(_looksSensitive)) {
      reasons.add('presentation_contains_sensitive_text');
    }
    return TripStopPresentationSummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
}

const _trueClaims = [
  'reviewOnly',
  'advisoryOnly',
  'activeTripRequired',
  'localSessionRequired',
  'stopReviewAlreadyOpenSuppressesDuplicate',
  'longTrafficLightProtected',
  'vehicleOnlyStopsNeedManualFallback',
  'walkingEvidenceCanOnlySuggestReview',
  'odometerIsGlobalTruth',
  'gpsAssistedTrackingAvailableWithoutMaps',
];

const _falseClaims = [
  'activityRecognitionCanCreateOfficialStop',
  'canCreateOfficialStop',
  'canEndTripAutomatically',
  'canReplaceOdometer',
  'mapsRequiredForStopPrompt',
  'mapboxCanShowPromptWithoutValidation',
  'mapboxCanCreateStop',
  'firebaseCanCreateStop',
  'remoteMirrorCanShowPromptWithoutLocalState',
  'employerCanForceStopPrompt',
  'rawLocationIncluded',
  'routeGeometryIncluded',
  'rawMotionPayloadIncluded',
  'tokensIncluded',
];

List<String> _statusAuthorityRisks({
  required Map<String, Object?> summary,
  required TripStopPresentationSurface? surface,
  required TripStopPresentationReason? reason,
}) {
  if (surface == null || reason == null) return const [];
  final canShowReviewPrompt = summary['canShowReviewPrompt'] == true;
  final canShowManualFallback = summary['canShowManualFallback'] == true;
  final requiresUserReview = summary['requiresUserReview'] == true;
  final shouldDebounceAgain = summary['shouldDebounceAgain'] == true;
  if (requiresUserReview && !canShowReviewPrompt) {
    return const ['presentation_review_authority_mismatch'];
  }
  if (canShowReviewPrompt &&
      surface != TripStopPresentationSurface.reviewBanner &&
      surface != TripStopPresentationSurface.urgentReviewSheet) {
    return const ['presentation_review_surface_mismatch'];
  }
  if (canShowManualFallback &&
      surface != TripStopPresentationSurface.manualFallbackChip &&
      !canShowReviewPrompt) {
    return const ['presentation_manual_fallback_surface_mismatch'];
  }
  if (surface == TripStopPresentationSurface.none &&
      (canShowReviewPrompt || canShowManualFallback || shouldDebounceAgain)) {
    return const ['presentation_none_authority_mismatch'];
  }
  return const [];
}

TripStopPresentationSurface? _safeSurface(Object? value) {
  if (value is! String) return null;
  for (final surface in TripStopPresentationSurface.values) {
    if (surface.name == value) return surface;
  }
  return null;
}

TripStopPresentationReason? _safeReason(Object? value) {
  if (value is! String) return null;
  for (final reason in TripStopPresentationReason.values) {
    if (reason.name == value) return reason;
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  return value.startsWith('pk.') ||
      value.startsWith('sk.') ||
      RegExp(r'-?\d{1,3}\.\d{5,}').hasMatch(value);
}
