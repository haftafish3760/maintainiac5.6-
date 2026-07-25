import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_state_machine.dart';

void main() {
  test('commercial contract contains every required lifecycle state', () {
    expect(
      TripTrackingSessionLifecycleContractState.values.map(
        (state) => state.name,
      ),
      const [
        'IDLE',
        'PREPARING',
        'AWAITING_PERMISSION',
        'AWAITING_LOCATION_SERVICES',
        'AWAITING_INITIAL_FIX',
        'CANDIDATE_MOVEMENT',
        'ACTIVE_TRACKING',
        'TEMPORARILY_STOPPED',
        'PAUSED_BY_USER',
        'PAUSED_BY_SYSTEM',
        'SIGNAL_DEGRADED',
        'SIGNAL_LOST',
        'RECOVERING',
        'COMPLETION_PENDING',
        'COMPLETED',
        'CANCELLED',
        'FAILED_RECOVERABLE',
        'FAILED_UNRECOVERABLE',
      ],
    );
  });

  test('every legal and illegal contract transition fails predictably', () {
    for (final from in TripTrackingSessionLifecycleContractState.values) {
      final allowed = TripTrackingSessionContractStateMachine.allowedNextStates(
        from,
      );
      expect(
        () => allowed.add(TripTrackingSessionLifecycleContractState.IDLE),
        throwsUnsupportedError,
        reason: '${from.name} must expose an immutable transition set',
      );

      for (final to in TripTrackingSessionLifecycleContractState.values) {
        final expectedAllowed = allowed.contains(to);
        final decision =
            TripTrackingSessionContractStateMachine.evaluateTransition(
              from,
              to,
            );
        final reason = '${from.name} -> ${to.name}';

        expect(
          TripTrackingSessionContractStateMachine.canTransition(from, to),
          expectedAllowed,
          reason: reason,
        );
        expect(decision.from, from, reason: reason);
        expect(decision.to, to, reason: reason);
        expect(decision.allowed, expectedAllowed, reason: reason);
        expect(
          decision.toSafeSummary()['allowed'],
          expectedAllowed,
          reason: reason,
        );
        if (expectedAllowed) {
          expect(
            () => TripTrackingSessionContractStateMachine.requireTransition(
              from,
              to,
            ),
            returnsNormally,
            reason: reason,
          );
        } else {
          expect(
            () => TripTrackingSessionContractStateMachine.requireTransition(
              from,
              to,
            ),
            throwsStateError,
            reason: reason,
          );
          expect(decision.requiresUserReview, isTrue, reason: reason);
        }
      }
    }
  });
}
