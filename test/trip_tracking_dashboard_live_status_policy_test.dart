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
        contains('has not reported a recent location'),
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
      allOf(
        contains('Waiting for your current location'),
        contains('start time'),
      ),
    );
  });

  test('user pause stays explicit and recoverable on the dashboard', () {
    for (final status in ['paused', 'recovery_paused_by_user']) {
      final warning = TripTrackingDashboardLiveStatusPolicy.warning(
        tracking: true,
        platformStatus: status,
      );
      expect(warning, contains('Location tracking is paused'));
      expect(warning, contains('trip is saved'));
      expect(warning, contains('resume or finish'));
    }
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
        allOf(contains('current location'), contains('start time')),
      );
      expect(
        TripTrackingDashboardLiveStatusPolicy.warning(
          tracking: true,
          platformStatus: 'initial_fix_approximate',
          awaitingInitialFix: true,
        ),
        allOf(contains('approximate location'), contains('odometer')),
      );
    },
  );

  test('vehicle row distinguishes acquiring live degraded and recovery GPS', () {
    expect(
      TripTrackingDashboardLiveStatusPolicy.vehicleStatus(
        activeTrip: true,
        nativeTracking: true,
        hasLiveProjection: true,
        awaitingInitialFix: true,
      ),
      'GPS ACQUIRING',
    );
    expect(
      TripTrackingDashboardLiveStatusPolicy.vehicleStatus(
        activeTrip: true,
        nativeTracking: true,
        hasLiveProjection: true,
      ),
      'LIVE GPS',
    );
    expect(
      TripTrackingDashboardLiveStatusPolicy.vehicleStatus(
        activeTrip: true,
        nativeTracking: true,
        hasLiveProjection: true,
        signalReviewRequired: true,
      ),
      'GPS DEGRADED',
    );
    expect(
      TripTrackingDashboardLiveStatusPolicy.vehicleStatus(
        activeTrip: true,
        nativeTracking: false,
        hasLiveProjection: false,
        gpsAssistanceEnabled: false,
      ),
      'GPS OFF',
    );
    expect(
      TripTrackingDashboardLiveStatusPolicy.vehicleStatus(
        activeTrip: true,
        nativeTracking: false,
        hasLiveProjection: true,
        platformStatus: 'awaiting_provider_registration',
      ),
      'GPS STARTING',
    );
    expect(
      TripTrackingDashboardLiveStatusPolicy.vehicleStatus(
        activeTrip: true,
        nativeTracking: false,
        hasLiveProjection: true,
        platformStatus: 'recoverable',
      ),
      'GPS RECOVERY',
    );
  });

  test('vehicle row makes explicit system and user pauses visible', () {
    for (final status in [
      'paused',
      'recovery_paused_by_user',
      'battery_critical_gps_blocked',
      'low_battery_requires_user_choice',
      'gps_signal_review_required',
    ]) {
      expect(
        TripTrackingDashboardLiveStatusPolicy.vehicleStatus(
          activeTrip: true,
          nativeTracking: false,
          hasLiveProjection: true,
          platformStatus: status,
        ),
        'GPS PAUSED',
      );
    }
  });
}
