import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_error_recovery_plan.dart';

void main() {
  test('malformed native payloads continue offline without data loss', () {
    final plan = TripTrackingErrorRecoveryPlan.forNativeError(
      'invalidLocationPayload',
      failureCount: 2,
      activeTripHasLocalCheckpoint: true,
      userCanOpenSettings: true,
    );
    final safe = plan.toSafeSummary();

    expect(plan.action, TripTrackingErrorRecoveryAction.continueOffline);
    expect(plan.retryAfter, const Duration(seconds: 8));
    expect(plan.reasonCode, 'malformed_payload_checkpoint_preserved');
    expect(safe['nonBlockingRecovery'], isTrue);
    expect(safe['localCheckpointPreserved'], isTrue);
    expect(safe['tripDataDeletionAllowed'], isFalse);
  });

  test(
    'permission and disabled GPS errors prompt user when settings are available',
    () {
      final plan = TripTrackingErrorRecoveryPlan.forNativeError(
        'trip_tracking_location_denied',
        failureCount: 3,
        activeTripHasLocalCheckpoint: true,
        userCanOpenSettings: true,
      );

      expect(plan.action, TripTrackingErrorRecoveryAction.promptUser);
      expect(plan.retryAfter, Duration.zero);
      expect(plan.reasonCode, 'user_permission_or_device_action_required');
      expect(plan.toSafeSummary()['nonBlockingRecovery'], isFalse);
    },
  );

  test('recoverable native errors retry without losing local trip state', () {
    final plan = TripTrackingErrorRecoveryPlan.forNativeError(
      'trip_tracking_location_registration_failed',
      failureCount: 4,
      activeTripHasLocalCheckpoint: true,
      userCanOpenSettings: false,
    );

    expect(
      plan.action,
      TripTrackingErrorRecoveryAction.retryNativeRegistration,
    );
    expect(plan.retryAfter, const Duration(seconds: 32));
    expect(plan.reasonCode, 'retry_without_losing_local_trip');
    expect(plan.toSafeSummary()['localCheckpointPreserved'], isTrue);
  });

  test(
    'unknown sensitive errors are sanitized and do not mutate trip truth',
    () {
      final plan = TripTrackingErrorRecoveryPlan.forNativeError(
        'token=sk.secret lat=35.12345,-80.98765',
        failureCount: 999,
        activeTripHasLocalCheckpoint: true,
        userCanOpenSettings: false,
      );
      final safe = plan.toSafeSummary();

      expect(plan.action, TripTrackingErrorRecoveryAction.keepTracking);
      expect(plan.nativeErrorCode, 'unknown_native_gps_error');
      expect(plan.retryAfter, Duration.zero);
      expect(safe['firestoreErrorCanOverrideRecovery'], isFalse);
      expect(safe['mapboxErrorCanOverrideRecovery'], isFalse);
      expect(safe['nativeErrorCanOverrideOdometer'], isFalse);
      expect(safe['confirmedOdometerRemainsCanonical'], isTrue);
      expect(safe.toString(), isNot(contains('sk.secret')));
      expect(safe.toString(), isNot(contains('35.12345')));
    },
  );

  test('retry backoff is bounded for repeated native failures', () {
    final first = TripTrackingErrorRecoveryPlan.forNativeError(
      'invalidStatusPayload',
      failureCount: -10,
      activeTripHasLocalCheckpoint: false,
      userCanOpenSettings: false,
    );
    final repeated = TripTrackingErrorRecoveryPlan.forNativeError(
      'invalidStatusPayload',
      failureCount: 20,
      activeTripHasLocalCheckpoint: false,
      userCanOpenSettings: false,
    );

    expect(first.retryAfter, const Duration(seconds: 2));
    expect(repeated.retryAfter, lessThanOrEqualTo(const Duration(seconds: 60)));
    expect(first.reasonCode, 'malformed_payload_waiting_for_local_checkpoint');
  });
}
