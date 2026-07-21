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
}
