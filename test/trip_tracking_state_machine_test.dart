import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_state_machine.dart';

void main() {
  test(
    'GPS session lifecycle permits recovery but not completed resurrection',
    () {
      expect(
        TripTrackingSessionStateMachine.canTransition(
          TripTrackingSessionLifecycleState.active,
          TripTrackingSessionLifecycleState.interrupted,
        ),
        isTrue,
      );
      expect(
        TripTrackingSessionStateMachine.canTransition(
          TripTrackingSessionLifecycleState.active,
          TripTrackingSessionLifecycleState.starting,
        ),
        isTrue,
      );
      expect(
        TripTrackingSessionStateMachine.canTransition(
          TripTrackingSessionLifecycleState.interrupted,
          TripTrackingSessionLifecycleState.recovering,
        ),
        isTrue,
      );
      expect(
        TripTrackingSessionStateMachine.canTransition(
          TripTrackingSessionLifecycleState.completed,
          TripTrackingSessionLifecycleState.active,
        ),
        isFalse,
      );
      expect(
        TripTrackingSessionStateMachine.canTransition(
          TripTrackingSessionLifecycleState.completed,
          TripTrackingSessionLifecycleState.disabled,
        ),
        isFalse,
      );
    },
  );

  test('illegal GPS session lifecycle transitions fail closed', () {
    expect(
      () => TripTrackingSessionStateMachine.requireTransition(
        TripTrackingSessionLifecycleState.awaitingReview,
        TripTrackingSessionLifecycleState.active,
      ),
      throwsStateError,
    );
  });

  test(
    'safe lifecycle summaries reject remote or native forced completion',
    () {
      final allowed = TripTrackingSessionStateMachine.evaluateTransition(
        TripTrackingSessionLifecycleState.recovering,
        TripTrackingSessionLifecycleState.awaitingReview,
      ).toSafeSummary();
      final rejected = TripTrackingSessionStateMachine.evaluateTransition(
        TripTrackingSessionLifecycleState.completed,
        TripTrackingSessionLifecycleState.active,
      ).toSafeSummary();

      expect(allowed['allowed'], isTrue);
      expect(allowed['requiresUserReview'], isTrue);
      expect(allowed['localLifecycleAuthoritative'], isTrue);
      expect(allowed['nativeEventCanForceComplete'], isFalse);
      expect(allowed['mapboxEventCanForceComplete'], isFalse);
      expect(allowed['remoteEventCanForceComplete'], isFalse);
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
      from: TripTrackingSessionLifecycleState.active,
      to: TripTrackingSessionLifecycleState.completed,
      allowed: false,
      reasonCode: 'token=pk.secret lat=35.1',
      requiresUserReview: true,
    );
    final summary = decision.toSafeSummary();

    expect(summary['reasonCode'], 'illegal_gps_session_transition');
    expect(summary.toString(), isNot(contains('pk.secret')));
    expect(summary.toString(), isNot(contains('35.1')));
  });
}
