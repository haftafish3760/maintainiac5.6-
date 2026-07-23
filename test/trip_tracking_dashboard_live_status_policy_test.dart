import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_dashboard_live_status_policy.dart';

void main() {
  test('does not show a stale warning after a trip has ended', () {
    expect(
      TripTrackingDashboardLiveStatusPolicy.warning(
        tracking: false,
        platformStatus: 'gps_signal_stale',
        platformError: 'GPS has not produced a location fix recently.',
      ),
      isNull,
    );
  });

  test(
    'keeps a stale active GPS stream visible with safe fallback guidance',
    () {
      expect(
        TripTrackingDashboardLiveStatusPolicy.warning(
          tracking: true,
          platformStatus: 'gps_signal_stale',
          platformError: '   ',
        ),
        contains('has not produced a location fix recently'),
      );
    },
  );

  test(
    'shows a live recoverable GPS error without inventing a stale signal',
    () {
      expect(
        TripTrackingDashboardLiveStatusPolicy.warning(
          tracking: true,
          platformStatus: 'battery_critical_gps_blocked',
          platformError:
              'Battery is critically low. GPS-assisted tracking is paused.',
        ),
        'Battery is critically low. GPS-assisted tracking is paused.',
      );
    },
  );

  test('explains initial-fix wait without moving the trip start', () {
    expect(
      TripTrackingDashboardLiveStatusPolicy.warning(
        tracking: true,
        platformStatus: 'tracking',
        awaitingInitialFix: true,
      ),
      allOf(contains('Waiting for a current GPS fix'), contains('start time')),
    );
  });

  test(
    'explains stale and approximate initial fixes as degraded assistance',
    () {
      expect(
        TripTrackingDashboardLiveStatusPolicy.warning(
          tracking: true,
          platformStatus: 'initial_fix_stale',
          awaitingInitialFix: true,
        ),
        allOf(contains('old cached location'), contains('start time')),
      );
      expect(
        TripTrackingDashboardLiveStatusPolicy.warning(
          tracking: true,
          platformStatus: 'initial_fix_approximate',
          awaitingInitialFix: true,
        ),
        allOf(contains('degraded'), contains('odometer')),
      );
    },
  );
}
