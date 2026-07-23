import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_failure_classification.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  test('fatal storage takes precedence and stops trusted GPS', () {
    final decision = TripFailureClassifier.evaluate(
      health: TripTrackingHealthState.healthy,
      lifecycle: TripTrackingSessionLifecycleState.active,
      hasUsableGpsEvidence: true,
      localStorageFailed: true,
    );

    expect(
      decision.classification,
      TripFailureClassification.fatalLocalStorageFailure,
    );
    expect(decision.stopTrustedGps, isTrue);
    expect(decision.preserveSession, isTrue);
    expect(decision.manualTripLogAvailable, isTrue);
    expect(decision.gpsFailureIsZeroMileTruth, isFalse);
    expect(decision.canEraseOdometerInputs, isFalse);
  });

  test(
    'unusable GPS remains manual-completable rather than zero-mile truth',
    () {
      final decision = TripFailureClassifier.evaluate(
        health: TripTrackingHealthState.unavailable,
        lifecycle: TripTrackingSessionLifecycleState.failedTerminal,
        hasUsableGpsEvidence: false,
        localStorageFailed: false,
      );

      expect(
        decision.classification,
        TripFailureClassification.unusableGpsEvidence,
      );
      expect(decision.manualTripLogAvailable, isTrue);
      expect(
        decision.reasonCode,
        'gps_evidence_unusable_manual_completion_available',
      );
    },
  );

  test('failure precedence cannot describe unavailable GPS as usable', () {
    final unavailableWhileDegraded = TripFailureClassifier.evaluate(
      health: TripTrackingHealthState.unavailable,
      lifecycle: TripTrackingSessionLifecycleState.degraded,
      hasUsableGpsEvidence: false,
      localStorageFailed: false,
    );
    final terminalWithPriorEvidence = TripFailureClassifier.evaluate(
      health: TripTrackingHealthState.reduced,
      lifecycle: TripTrackingSessionLifecycleState.failedTerminal,
      hasUsableGpsEvidence: true,
      localStorageFailed: false,
    );

    expect(
      unavailableWhileDegraded.classification,
      TripFailureClassification.unusableGpsEvidence,
    );
    expect(unavailableWhileDegraded.stopTrustedGps, isTrue);
    expect(
      terminalWithPriorEvidence.classification,
      TripFailureClassification.recoverable,
    );
    expect(
      terminalWithPriorEvidence.reasonCode,
      'gps_unavailable_prior_evidence_preserved',
    );
    expect(terminalWithPriorEvidence.stopTrustedGps, isTrue);
  });

  test('every failure class preserves the intended safe boundary', () {
    final cases =
        <
          ({
            TripTrackingHealthState health,
            TripTrackingSessionLifecycleState lifecycle,
            bool evidence,
            TripFailureClassification classification,
            String reason,
            bool stopsGps,
            bool preservesSession,
          })
        >[
          (
            health: TripTrackingHealthState.permissionBlocked,
            lifecycle: TripTrackingSessionLifecycleState.active,
            evidence: true,
            classification: TripFailureClassification.userActionRequired,
            reason: 'location_permission_action_required',
            stopsGps: true,
            preservesSession: true,
          ),
          (
            health: TripTrackingHealthState.platformRestricted,
            lifecycle: TripTrackingSessionLifecycleState.active,
            evidence: true,
            classification: TripFailureClassification.platformRestricted,
            reason: 'platform_restricted_tracking',
            stopsGps: true,
            preservesSession: true,
          ),
          (
            health: TripTrackingHealthState.healthy,
            lifecycle: TripTrackingSessionLifecycleState.interrupted,
            evidence: true,
            classification: TripFailureClassification.recoverable,
            reason: 'recoverable_tracking_failure',
            stopsGps: false,
            preservesSession: true,
          ),
          (
            health: TripTrackingHealthState.poor,
            lifecycle: TripTrackingSessionLifecycleState.active,
            evidence: true,
            classification: TripFailureClassification.degradedButUsable,
            reason: 'degraded_gps_evidence',
            stopsGps: false,
            preservesSession: true,
          ),
          (
            health: TripTrackingHealthState.healthy,
            lifecycle: TripTrackingSessionLifecycleState.active,
            evidence: true,
            classification: TripFailureClassification.none,
            reason: 'tracking_healthy',
            stopsGps: false,
            preservesSession: false,
          ),
        ];

    for (final entry in cases) {
      final decision = TripFailureClassifier.evaluate(
        health: entry.health,
        lifecycle: entry.lifecycle,
        hasUsableGpsEvidence: entry.evidence,
        localStorageFailed: false,
      );
      expect(decision.classification, entry.classification);
      expect(decision.reasonCode, entry.reason);
      expect(decision.stopTrustedGps, entry.stopsGps);
      expect(decision.preserveSession, entry.preservesSession);
      expect(decision.manualTripLogAvailable, isTrue);
      expect(decision.gpsFailureIsZeroMileTruth, isFalse);
      expect(decision.canEraseOdometerInputs, isFalse);
    }
  });
}
