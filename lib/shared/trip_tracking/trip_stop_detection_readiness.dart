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
