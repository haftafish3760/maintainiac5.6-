import 'trip_tracking_models.dart';

enum TripFailureClassification {
  none,
  recoverable,
  degradedButUsable,
  unusableGpsEvidence,
  fatalLocalStorageFailure,
  platformRestricted,
  userActionRequired,
}

class TripFailureDecision {
  const TripFailureDecision({
    required this.classification,
    required this.reasonCode,
    required this.preserveSession,
    required this.stopTrustedGps,
    required this.manualTripLogAvailable,
  });

  final TripFailureClassification classification;
  final String reasonCode;
  final bool preserveSession;
  final bool stopTrustedGps;
  final bool manualTripLogAvailable;

  bool get gpsFailureIsZeroMileTruth => false;
  bool get canEraseOdometerInputs => false;
}

class TripFailureClassifier {
  const TripFailureClassifier._();

  static TripFailureDecision evaluate({
    required TripTrackingHealthState health,
    required TripTrackingSessionLifecycleState lifecycle,
    required bool hasUsableGpsEvidence,
    required bool localStorageFailed,
  }) {
    if (localStorageFailed) {
      return _decision(
        TripFailureClassification.fatalLocalStorageFailure,
        'fatal_local_storage_failure',
        stopTrustedGps: true,
      );
    }
    if (health == TripTrackingHealthState.permissionBlocked) {
      return _decision(
        TripFailureClassification.userActionRequired,
        'location_permission_action_required',
        stopTrustedGps: true,
      );
    }
    if (health == TripTrackingHealthState.platformRestricted) {
      return _decision(
        TripFailureClassification.platformRestricted,
        'platform_restricted_tracking',
        stopTrustedGps: true,
      );
    }
    // Unavailable evidence and terminal lifecycle state must outrank a stale
    // degraded/recovering marker. Otherwise the UI can incorrectly describe
    // unusable GPS as still usable and leave trusted collection running.
    if (health == TripTrackingHealthState.unavailable ||
        lifecycle == TripTrackingSessionLifecycleState.failedTerminal) {
      return _decision(
        hasUsableGpsEvidence
            ? TripFailureClassification.recoverable
            : TripFailureClassification.unusableGpsEvidence,
        hasUsableGpsEvidence
            ? 'gps_unavailable_prior_evidence_preserved'
            : 'gps_evidence_unusable_manual_completion_available',
        stopTrustedGps: true,
      );
    }
    if (lifecycle == TripTrackingSessionLifecycleState.failedRecoverable ||
        lifecycle == TripTrackingSessionLifecycleState.interrupted ||
        lifecycle == TripTrackingSessionLifecycleState.recovering) {
      return _decision(
        TripFailureClassification.recoverable,
        'recoverable_tracking_failure',
      );
    }
    if (health == TripTrackingHealthState.reduced ||
        health == TripTrackingHealthState.poor ||
        lifecycle == TripTrackingSessionLifecycleState.degraded) {
      return _decision(
        TripFailureClassification.degradedButUsable,
        'degraded_gps_evidence',
      );
    }
    return _decision(TripFailureClassification.none, 'tracking_healthy');
  }

  static TripFailureDecision _decision(
    TripFailureClassification classification,
    String reasonCode, {
    bool stopTrustedGps = false,
  }) => TripFailureDecision(
    classification: classification,
    reasonCode: reasonCode,
    preserveSession: classification != TripFailureClassification.none,
    stopTrustedGps: stopTrustedGps,
    manualTripLogAvailable: true,
  );
}
