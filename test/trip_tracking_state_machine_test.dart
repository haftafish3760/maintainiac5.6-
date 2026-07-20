import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_state_machine.dart';

void main() {
  test(
    'GPS session lifecycle permits recovery but not completed resurrection',
    () {
      expect(
        TripTrackingSessionStateMachine.canTransition(
          TripTrackingSessionLifecycleState.activeTracking,
          TripTrackingSessionLifecycleState.signalLost,
        ),
        isTrue,
      );
      expect(
        TripTrackingSessionStateMachine.canTransition(
          TripTrackingSessionLifecycleState.signalDegraded,
          TripTrackingSessionLifecycleState.signalLost,
        ),
        isTrue,
      );
      expect(
        TripTrackingSessionStateMachine.canTransition(
          TripTrackingSessionLifecycleState.activeTracking,
          TripTrackingSessionLifecycleState.awaitingInitialFix,
        ),
        isTrue,
      );
      expect(
        TripTrackingSessionStateMachine.canTransition(
          TripTrackingSessionLifecycleState.signalLost,
          TripTrackingSessionLifecycleState.recovering,
        ),
        isTrue,
      );
      expect(
        TripTrackingSessionStateMachine.canTransition(
          TripTrackingSessionLifecycleState.completed,
          TripTrackingSessionLifecycleState.activeTracking,
        ),
        isFalse,
      );
      expect(
        TripTrackingSessionStateMachine.canTransition(
          TripTrackingSessionLifecycleState.completed,
          TripTrackingSessionLifecycleState.idle,
        ),
        isFalse,
      );
    },
  );

  test('illegal GPS session lifecycle transitions fail closed', () {
    expect(
      () => TripTrackingSessionStateMachine.requireTransition(
        TripTrackingSessionLifecycleState.completionPending,
        TripTrackingSessionLifecycleState.activeTracking,
      ),
      throwsStateError,
    );
  });

  test(
    'safe lifecycle summaries reject remote or native forced completion',
    () {
      final allowed = TripTrackingSessionStateMachine.evaluateTransition(
        TripTrackingSessionLifecycleState.recovering,
        TripTrackingSessionLifecycleState.completionPending,
      ).toSafeSummary();
      final rejected = TripTrackingSessionStateMachine.evaluateTransition(
        TripTrackingSessionLifecycleState.completed,
        TripTrackingSessionLifecycleState.activeTracking,
      ).toSafeSummary();

      expect(allowed['allowed'], isTrue);
      expect(allowed['requiresUserReview'], isTrue);
      expect(allowed['localLifecycleAuthoritative'], isTrue);
      expect(allowed['transitionTrustedAfterValidationOnly'], isTrue);
      expect(allowed['remoteLifecycleCanOverrideLocalCheckpoint'], isFalse);
      expect(allowed['firestoreCanForceLifecycleTransition'], isFalse);
      expect(allowed['cloudFunctionCanForceLifecycleTransition'], isFalse);
      expect(allowed['nativeEventCanForceComplete'], isFalse);
      expect(allowed['mapboxEventCanForceComplete'], isFalse);
      expect(allowed['remoteEventCanForceComplete'], isFalse);
      expect(allowed['backgroundPauseCanDeleteCheckpoint'], isFalse);
      expect(allowed['backgroundInterruptionRequiresRecovery'], isTrue);
      expect(allowed['permissionLossRequiresUserReview'], isTrue);
      expect(allowed['localCheckpointPreservedAcrossInterruption'], isTrue);
      expect(allowed['recoveryRequiresLocalCheckpoint'], isTrue);
      expect(rejected['allowed'], isFalse);
      expect(rejected['reasonCode'], 'completed_session_cannot_resume');
      expect(rejected['completedSessionCanResume'], isFalse);
      expect(rejected['rawNativePayloadIncluded'], isFalse);
      expect(rejected['rawLocationIncluded'], isFalse);
    },
  );

  test('malformed lifecycle reason text is sanitized in summaries', () {
    const decision = TripTrackingLifecycleTransitionDecision(
      from: TripTrackingSessionLifecycleState.activeTracking,
      to: TripTrackingSessionLifecycleState.completed,
      allowed: false,
      reasonCode: 'token=pk.secret lat=35.1',
      requiresUserReview: true,
    );
    final summary = decision.toSafeSummary();

    expect(summary['reasonCode'], 'illegal_gps_session_transition');
    expect(summary['allowed'], isFalse);
    expect(summary['requiresUserReview'], isTrue);
    expect(summary.toString(), isNot(contains('pk.secret')));
    expect(summary.toString(), isNot(contains('35.1')));
  });

  test('direct lifecycle summaries cannot forge illegal transitions', () {
    const decision = TripTrackingLifecycleTransitionDecision(
      from: TripTrackingSessionLifecycleState.completed,
      to: TripTrackingSessionLifecycleState.activeTracking,
      allowed: true,
      reasonCode: 'gps_session_transition_allowed',
      requiresUserReview: false,
    );
    final summary = decision.toSafeSummary();

    expect(summary['allowed'], isFalse);
    expect(summary['requiresUserReview'], isTrue);
    expect(summary['completedSessionCanResume'], isFalse);
    expect(summary['remoteLifecycleCanOverrideLocalCheckpoint'], isFalse);
    expect(summary['firestoreCanForceLifecycleTransition'], isFalse);
  });

  test('background interruption transitions preserve local checkpoint', () {
    final interrupted = TripTrackingSessionStateMachine.evaluateTransition(
      TripTrackingSessionLifecycleState.activeTracking,
      TripTrackingSessionLifecycleState.signalLost,
    ).toSafeSummary();
    final recovering = TripTrackingSessionStateMachine.evaluateTransition(
      TripTrackingSessionLifecycleState.signalLost,
      TripTrackingSessionLifecycleState.recovering,
    ).toSafeSummary();
    final permissionLoss = TripTrackingSessionStateMachine.evaluateTransition(
      TripTrackingSessionLifecycleState.awaitingInitialFix,
      TripTrackingSessionLifecycleState.awaitingPermission,
    ).toSafeSummary();

    for (final summary in [interrupted, recovering, permissionLoss]) {
      expect(summary['allowed'], isTrue);
      expect(summary['backgroundPauseCanDeleteCheckpoint'], isFalse);
      expect(summary['localCheckpointPreservedAcrossInterruption'], isTrue);
      expect(summary['remoteLifecycleCanOverrideLocalCheckpoint'], isFalse);
      expect(summary['nativeEventCanForceComplete'], isFalse);
      expect(summary['mapboxEventCanForceComplete'], isFalse);
      expect(summary['odometerRemainsCanonical'], isTrue);
    }
    expect(interrupted['requiresUserReview'], isFalse);
    expect(recovering['requiresUserReview'], isFalse);
    expect(permissionLoss['permissionLossRequiresUserReview'], isTrue);
  });
}
