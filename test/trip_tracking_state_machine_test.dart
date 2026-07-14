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
}
