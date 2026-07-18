import 'trip_stop_classification.dart';
import 'trip_stop_summary_validation.dart';

enum TripStopDetectionReadinessStatus {
  readyForUserReview,
  keepTracking,
  waitForMoreEvidence,
  unsafeBoundary,
  unauthorizedBoundary,
}

enum TripStopReviewBoundarySource {
  localTripLog,
  firestoreMirror,
  cloudFunction,
  importedFile,
  mapbox,
  dashboardCache,
}

class TripStopReviewAuthorization {
  const TripStopReviewAuthorization._({
    required this.allowed,
    required this.reasonCode,
    required this.reasons,
  });

  factory TripStopReviewAuthorization.fromBoundary({
    required String? currentUserId,
    required String? tripOwnerUserId,
    required TripStopReviewBoundarySource source,
    bool explicitSharedTripAccess = false,
    bool fleetObserverMode = false,
  }) {
    final reasons = <String>[];
    final safeCurrentUserId = _safeUserId(currentUserId);
    final safeTripOwnerUserId = _safeUserId(tripOwnerUserId);

    if (safeCurrentUserId == null) reasons.add('current_user_required');
    if (safeTripOwnerUserId == null) reasons.add('trip_owner_required');
    if (source != TripStopReviewBoundarySource.localTripLog) {
      reasons.add('local_trip_log_boundary_required');
    }
    if (fleetObserverMode) reasons.add('fleet_observer_read_only');
    if (safeCurrentUserId != null &&
        safeTripOwnerUserId != null &&
        safeCurrentUserId != safeTripOwnerUserId &&
        !explicitSharedTripAccess) {
      reasons.add('trip_owner_or_explicit_access_required');
    }

    return TripStopReviewAuthorization._(
      allowed: reasons.isEmpty,
      reasonCode: reasons.isEmpty
          ? 'authorized_for_local_stop_review'
          : 'unauthorized_stop_review_boundary',
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool allowed;
  final String reasonCode;
  final List<String> reasons;
}

class TripStopDetectionReadiness {
  const TripStopDetectionReadiness._({
    required this.status,
    required this.actionToken,
    required this.reasonCode,
    required this.reasons,
  });

  factory TripStopDetectionReadiness.fromSummary(
    Map<String, Object?> summary, {
    required bool activeTrip,
    required bool localSessionAvailable,
    required bool acceptedVehicleMovementObserved,
    TripStopReviewAuthorization? authorization,
  }) {
    final validation = TripStopSummaryValidation.fromSummary(summary);
    if (!validation.isRenderable) {
      return TripStopDetectionReadiness._(
        status: TripStopDetectionReadinessStatus.unsafeBoundary,
        actionToken: 'keep_tracking',
        reasonCode: 'unsafe_stop_summary_boundary',
        reasons: validation.reasons,
      );
    }
    if (!activeTrip) {
      return const TripStopDetectionReadiness._(
        status: TripStopDetectionReadinessStatus.keepTracking,
        actionToken: 'keep_tracking',
        reasonCode: 'no_active_trip_for_stop_review',
        reasons: ['active_trip_required'],
      );
    }
    final safeAuthorization =
        authorization ??
        TripStopReviewAuthorization.fromBoundary(
          currentUserId: 'local_user',
          tripOwnerUserId: 'local_user',
          source: TripStopReviewBoundarySource.localTripLog,
        );
    if (!safeAuthorization.allowed) {
      return TripStopDetectionReadiness._(
        status: TripStopDetectionReadinessStatus.unauthorizedBoundary,
        actionToken: 'keep_tracking',
        reasonCode: safeAuthorization.reasonCode,
        reasons: safeAuthorization.reasons,
      );
    }
    if (!localSessionAvailable) {
      return const TripStopDetectionReadiness._(
        status: TripStopDetectionReadinessStatus.unsafeBoundary,
        actionToken: 'keep_tracking',
        reasonCode: 'local_session_required_for_stop_review',
        reasons: ['local_trip_log_required'],
      );
    }
    if (!acceptedVehicleMovementObserved ||
        summary['stopRequiresAcceptedVehicleMovement'] != true) {
      return const TripStopDetectionReadiness._(
        status: TripStopDetectionReadinessStatus.waitForMoreEvidence,
        actionToken: 'continue_monitoring',
        reasonCode: 'vehicle_movement_required_for_stop_review',
        reasons: ['accepted_vehicle_movement_required'],
      );
    }

    final signal = validation.signal;
    if (signal == TripStopSignal.reviewOnlyStop &&
        summary['requiresUserReview'] == true &&
        summary['canSuggestStop'] == true) {
      return TripStopDetectionReadiness._(
        status: TripStopDetectionReadinessStatus.readyForUserReview,
        actionToken: _safeReadinessAction(summary['actionToken']),
        reasonCode: validation.reasonCode ?? 'stop_review_ready',
        reasons: const [],
      );
    }

    if (signal == TripStopSignal.stopCandidate) {
      final reasons = <String>['stronger_stop_evidence_required'];
      if (summary['shouldSurfaceManualStopFallback'] == true) {
        reasons.add('manual_stop_fallback_available');
      }
      return TripStopDetectionReadiness._(
        status: TripStopDetectionReadinessStatus.waitForMoreEvidence,
        actionToken: _safeReadinessAction(summary['actionToken']),
        reasonCode: validation.reasonCode ?? 'stop_review_waiting',
        reasons: List.unmodifiable(reasons),
      );
    }

    return TripStopDetectionReadiness._(
      status: TripStopDetectionReadinessStatus.keepTracking,
      actionToken: _safeReadinessAction(summary['actionToken']),
      reasonCode: validation.reasonCode ?? 'no_stop_review_needed',
      reasons: const [],
    );
  }

  final TripStopDetectionReadinessStatus status;
  final String actionToken;
  final String reasonCode;
  final List<String> reasons;

  bool get canOpenStopReview =>
      status == TripStopDetectionReadinessStatus.readyForUserReview;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'actionToken': actionToken,
    'reasonCode': reasonCode,
    'canOpenStopReview': canOpenStopReview,
    'dashboardMaySuggestStop': canOpenStopReview,
    'dashboardMaySuggestManualFallback': reasons.contains(
      'manual_stop_fallback_available',
    ),
    'manualFallbackCanCreateOfficialStop': false,
    'manualFallbackRequiresUserAction': true,
    'officialStopCreated': false,
    'officialMileageSource': 'odometer',
    'requiresLocalTripLog': true,
    'requiresActiveTrip': true,
    'requiresAcceptedVehicleMovement': true,
    'requiresOwnershipOrExplicitAccess': true,
    'requiresFreshLocalStopSummary': true,
    'requiresReviewBeforeCommit': true,
    'stopReviewCanEditOdometer': false,
    'stopReviewCanBackdateWithoutReview': false,
    'remoteReadinessCanOverrideLocalTrip': false,
    'validatedStopSummaryRequired': true,
    'malformedStopSummaryFailsClosed': true,
    'authenticationDoesNotGrantStopAuthority': true,
    'localTripLogMustOwnStopReview': true,
    'currentUserMustOwnOrAccessTrip': true,
    'fleetObserverCanOpenStopReview': false,
    'remoteDashboardCanOpenStopReview': false,
    'importedSummaryCanOpenStopReview': false,
    'firestoreCanOpenStopReview': false,
    'cloudFunctionCanOpenStopReview': false,
    'mapboxCanOpenStopReview': false,
    'mapsRequiredForStopReview': false,
    'rawSamplesIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
    'reasons': reasons,
  };
}

class TripStopDetectionReadinessSummaryValidation {
  const TripStopDetectionReadinessSummaryValidation._({
    required this.isRenderable,
    required this.canOpenStopReview,
    required this.reasons,
  });

  factory TripStopDetectionReadinessSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) reasons.add('unsupported_schema');
    if (!_allowedStatuses.contains(summary['status'])) {
      reasons.add('invalid_readiness_status');
    }
    if (!_allowedActions.contains(summary['actionToken'])) {
      reasons.add('invalid_readiness_action');
    }
    final reasonCode = summary['reasonCode'];
    if (reasonCode is! String || reasonCode.trim().isEmpty) {
      reasons.add('invalid_readiness_reason');
    }
    final canOpen = summary['canOpenStopReview'];
    if (canOpen is! bool) reasons.add('can_open_not_bool');
    if (summary['dashboardMaySuggestStop'] is! bool) {
      reasons.add('dashboard_suggest_stop_not_bool');
    }
    if (summary['dashboardMaySuggestManualFallback'] is! bool) {
      reasons.add('dashboard_manual_fallback_not_bool');
    }
    for (final key in const [
      'manualFallbackRequiresUserAction',
      'requiresLocalTripLog',
      'requiresActiveTrip',
      'requiresAcceptedVehicleMovement',
      'requiresOwnershipOrExplicitAccess',
      'requiresFreshLocalStopSummary',
      'requiresReviewBeforeCommit',
      'validatedStopSummaryRequired',
      'malformedStopSummaryFailsClosed',
      'authenticationDoesNotGrantStopAuthority',
      'localTripLogMustOwnStopReview',
      'currentUserMustOwnOrAccessTrip',
    ]) {
      if (summary[key] != true) reasons.add('${key}_not_true');
    }
    for (final key in const [
      'manualFallbackCanCreateOfficialStop',
      'stopReviewCanEditOdometer',
      'stopReviewCanBackdateWithoutReview',
      'officialStopCreated',
      'remoteReadinessCanOverrideLocalTrip',
      'fleetObserverCanOpenStopReview',
      'remoteDashboardCanOpenStopReview',
      'importedSummaryCanOpenStopReview',
      'firestoreCanOpenStopReview',
      'cloudFunctionCanOpenStopReview',
      'mapboxCanOpenStopReview',
      'mapsRequiredForStopReview',
      'rawSamplesIncluded',
      'coordinatesIncluded',
      'routeGeometryIncluded',
      'tokensIncluded',
    ]) {
      if (summary[key] != false) reasons.add('${key}_not_false');
    }
    if (summary['officialMileageSource'] != 'odometer') {
      reasons.add('odometer_not_official_source');
    }
    final safeReasons = summary['reasons'];
    if (safeReasons is! List ||
        safeReasons.any((entry) => entry is! String || _sensitiveText(entry))) {
      reasons.add('invalid_reason_list');
    }
    if (_containsSensitivePayload(summary)) {
      reasons.add('readiness_contains_sensitive_payload');
    }
    return TripStopDetectionReadinessSummaryValidation._(
      isRenderable: reasons.isEmpty,
      canOpenStopReview: reasons.isEmpty && canOpen == true,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final bool canOpenStopReview;
  final List<String> reasons;
}

String? _safeUserId(String? value) {
  final clean = value?.trim();
  if (clean == null || clean.isEmpty) return null;
  if (clean.length > 128) return null;
  if (clean.startsWith('pk.') || clean.startsWith('sk.')) return null;
  if (!RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(clean)) return null;
  return clean;
}

String _safeReadinessAction(Object? value) {
  if (value is! String) return 'keep_tracking';
  return switch (value) {
    'keep_tracking' => value,
    'continue_monitoring' => value,
    'review_delivery_stop' => value,
    'review_jobsite_stop' => value,
    'review_shift_stop' => value,
    'review_trip_stop' => value,
    _ => 'keep_tracking',
  };
}

const _allowedStatuses = {
  'readyForUserReview',
  'keepTracking',
  'waitForMoreEvidence',
  'unsafeBoundary',
  'unauthorizedBoundary',
};

const _allowedActions = {
  'keep_tracking',
  'continue_monitoring',
  'review_delivery_stop',
  'review_jobsite_stop',
  'review_shift_stop',
  'review_trip_stop',
};

bool _containsSensitivePayload(Map<String, Object?> summary) {
  for (final entry in summary.entries) {
    if (_sensitiveText(entry.key)) return true;
    final value = entry.value;
    if (value is Map || value is Iterable && entry.key != 'reasons') {
      return true;
    }
    if (value is String && _sensitiveText(value)) return true;
  }
  return false;
}

bool _sensitiveText(String value) {
  final normalized = value.toLowerCase();
  if (normalized == 'coordinatesincluded' ||
      normalized == 'routegeometryincluded' ||
      normalized == 'tokensincluded') {
    return false;
  }
  return normalized.contains('pk.') ||
      normalized.contains('sk.') ||
      normalized.contains('token=') ||
      normalized.contains('latitude') ||
      normalized.contains('longitude') ||
      normalized.contains('coordinate=') ||
      normalized.contains('geometry') ||
      normalized.contains('polyline') ||
      normalized.contains('gps trace') ||
      RegExp(r'-?\d{2,3}\.\d{4,}\s*,\s*-?\d{2,3}\.\d{4,}').hasMatch(normalized);
}
