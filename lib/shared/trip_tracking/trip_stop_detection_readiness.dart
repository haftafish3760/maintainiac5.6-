import 'trip_stop_classification.dart';
import 'trip_stop_summary_validation.dart';

enum TripStopDetectionReadinessStatus {
  readyForUserReview,
  keepTracking,
  waitForMoreEvidence,
  unsafeBoundary,
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
      return TripStopDetectionReadiness._(
        status: TripStopDetectionReadinessStatus.waitForMoreEvidence,
        actionToken: _safeReadinessAction(summary['actionToken']),
        reasonCode: validation.reasonCode ?? 'stop_review_waiting',
        reasons: const ['stronger_stop_evidence_required'],
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
    'officialStopCreated': false,
    'officialMileageSource': 'odometer',
    'requiresLocalTripLog': true,
    'requiresActiveTrip': true,
    'requiresAcceptedVehicleMovement': true,
    'remoteReadinessCanOverrideLocalTrip': false,
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
