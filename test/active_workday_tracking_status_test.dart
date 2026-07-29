// Active Day GPS status regression coverage.
//
// Owns deterministic presentation checks for controller evidence states.
// Does not start native tracking or validate device GPS behavior. Consumed by
// Dashboard regression gates; prevents the UI from calling uncertain GPS live.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/active_workday_tracking_status_line.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  test('Active Day never calls an initial-fix wait live GPS', () {
    final status = ActiveWorkdayTrackingStatus.forSnapshot(
      gpsAssistanceEnabled: true,
      nativeTracking: true,
      tracking: true,
      lifecycleState: TripTrackingSessionLifecycleState.active,
      platformStatus: 'tracking',
      awaitingInitialFix: true,
      signalReviewRequired: false,
    );

    expect(status.label, contains('acquiring'));
  });

  test('Active Day makes degraded signal evidence visible', () {
    final status = ActiveWorkdayTrackingStatus.forSnapshot(
      gpsAssistanceEnabled: true,
      nativeTracking: true,
      tracking: true,
      lifecycleState: TripTrackingSessionLifecycleState.degraded,
      platformStatus: 'gps_signal_stale',
      awaitingInitialFix: false,
      signalReviewRequired: true,
    );

    expect(status.label, contains('degraded'));
    expect(status.label, isNot(contains('GPS live')));
  });

  test(
    'Active Day reports live GPS only after current evidence is healthy',
    () {
      final status = ActiveWorkdayTrackingStatus.forSnapshot(
        gpsAssistanceEnabled: true,
        nativeTracking: true,
        tracking: true,
        lifecycleState: TripTrackingSessionLifecycleState.active,
        platformStatus: 'tracking',
        awaitingInitialFix: false,
        signalReviewRequired: false,
      );

      expect(status.label, contains('GPS live'));
    },
  );

  test(
    'Active Day keeps an explicit paused state after native collection ends',
    () {
      final status = ActiveWorkdayTrackingStatus.forSnapshot(
        gpsAssistanceEnabled: true,
        nativeTracking: false,
        tracking: false,
        lifecycleState: null,
        platformStatus: 'paused',
        awaitingInitialFix: true,
        signalReviewRequired: false,
      );

      expect(status.label, contains('Location paused'));
    },
  );
}
