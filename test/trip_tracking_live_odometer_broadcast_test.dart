import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/live_odometer_display.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_live_odometer_broadcast.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18, 12);

  test('confirmed odometer snapshot still notifies dashboard safely', () {
    const snapshot = LiveOdometerDisplaySnapshot(
      confirmedReading: 1000,
      displayReading: 1000,
      isLive: false,
    );
    final broadcast = TripTrackingLiveOdometerBroadcast.fromSnapshot(
      snapshot,
      now: now,
      activeTripId: null,
      expectedTripId: 'trip_inactive',
    );
    final safe = broadcast.toSafeDashboardMap();

    expect(broadcast.status, TripTrackingLiveOdometerBroadcastStatus.inactive);
    expect(broadcast.shouldNotifyDashboard, isTrue);
    expect(safe['displayOnlyMileageSource'], 'confirmed_odometer');
    expect(safe['manualConfirmationRequired'], isFalse);
    expect(safe['writesConfirmedOdometer'], isFalse);
  });

  test('fresh live projection is renderable across dashboard consumers', () {
    final controller = GlobalOdometerController(
      initialReading: 1000,
      initialRecordedAt: now,
    );
    addTearDown(controller.dispose);

    expect(
      controller.beginLiveTripProjection(
        tripId: 'trip_live',
        startingOdometer: 1000,
        observedAtUtc: now,
      ),
      isTrue,
    );
    expect(
      controller.updateLiveTripProjection(
        tripId: 'trip_live',
        estimatedOdometer: 1003,
        observedAtUtc: now.add(const Duration(minutes: 1)),
        receivedAtUtc: now.add(const Duration(minutes: 1)),
      ),
      isTrue,
    );
    final broadcast = TripTrackingLiveOdometerBroadcast.fromSnapshot(
      controller.liveDisplaySnapshot,
      now: now.add(const Duration(minutes: 2)),
      activeTripId: controller.activeLiveTripId,
      expectedTripId: 'trip_live',
    );
    final safe = broadcast.toSafeDashboardMap();

    expect(
      broadcast.status,
      TripTrackingLiveOdometerBroadcastStatus.renderable,
    );
    expect(broadcast.displayValue, '0001003');
    expect(safe['globalOdometerScopeMustNotifyListeners'], isTrue);
    expect(safe['dashboardActiveVehicleBlockUsesLiveProjection'], isTrue);
    expect(safe['contractorDashboardUsesLiveProjection'], isTrue);
    expect(safe['crossDashboardLiveOdometerReady'], isTrue);
  });

  test('stale live projection remains display-only and review-required', () {
    final snapshot = LiveOdometerDisplaySnapshot(
      confirmedReading: 1000,
      displayReading: 1004,
      isLive: true,
      liveUpdatedAt: now.subtract(const Duration(minutes: 6)),
      projectionRevision: 4,
    );
    final broadcast = TripTrackingLiveOdometerBroadcast.fromSnapshot(
      snapshot,
      now: now,
      activeTripId: 'trip_stale',
      expectedTripId: 'trip_stale',
    );
    final safe = broadcast.toSafeDashboardMap();

    expect(
      broadcast.status,
      TripTrackingLiveOdometerBroadcastStatus.staleReviewOnly,
    );
    expect(broadcast.reviewRequired, isTrue);
    expect(safe['staleProjectionCanCommitMileage'], isFalse);
    expect(safe['confirmedOdometerRemainsCanonical'], isTrue);
  });

  test('trip id mismatch rejects remote or stale live odometer payloads', () {
    final snapshot = LiveOdometerDisplaySnapshot(
      confirmedReading: 1000,
      displayReading: 1005,
      isLive: true,
      liveUpdatedAt: now,
      projectionRevision: 1,
    );
    final broadcast = TripTrackingLiveOdometerBroadcast.fromSnapshot(
      snapshot,
      now: now,
      activeTripId: 'trip_other',
      expectedTripId: 'trip_expected',
    );

    expect(broadcast.status, TripTrackingLiveOdometerBroadcastStatus.rejected);
    expect(broadcast.shouldNotifyDashboard, isFalse);
    expect(broadcast.reasonCodes, contains('live_trip_id_mismatch'));
    expect(
      broadcast.toSafeDashboardMap()['firestoreCanOverrideLiveDisplay'],
      isFalse,
    );
  });

  test(
    'malformed live odometer display cannot roll back confirmed reading',
    () {
      const snapshot = LiveOdometerDisplaySnapshot(
        confirmedReading: 1000,
        displayReading: 999,
        isLive: true,
        projectionRevision: -1,
      );
      final broadcast = TripTrackingLiveOdometerBroadcast.fromSnapshot(
        snapshot,
        now: now,
        activeTripId: 'trip_bad',
        expectedTripId: 'trip_bad',
      );

      expect(
        broadcast.status,
        TripTrackingLiveOdometerBroadcastStatus.rejected,
      );
      expect(broadcast.displayValue, isNull);
      expect(
        broadcast.reasonCodes,
        containsAll([
          'display_below_confirmed_reading',
          'negative_projection_revision',
          'missing_live_update_time',
        ]),
      );
    },
  );

  test('future live projection timestamp is rejected before UI render', () {
    final snapshot = LiveOdometerDisplaySnapshot(
      confirmedReading: 1000,
      displayReading: 1005,
      isLive: true,
      liveUpdatedAt: now.add(const Duration(minutes: 5)),
      projectionRevision: 2,
    );
    final broadcast = TripTrackingLiveOdometerBroadcast.fromSnapshot(
      snapshot,
      now: now,
      activeTripId: 'trip_future',
      expectedTripId: 'trip_future',
    );
    final safe = broadcast.toSafeDashboardMap();

    expect(broadcast.status, TripTrackingLiveOdometerBroadcastStatus.rejected);
    expect(broadcast.shouldNotifyDashboard, isFalse);
    expect(broadcast.reasonCodes, contains('live_update_time_in_future'));
    expect(safe['futureProjectionBlocked'], isTrue);
    expect(safe['futureProjectionCanRender'], isFalse);
  });

  test('impossible live projection delta is rejected as review-only data', () {
    final snapshot = LiveOdometerDisplaySnapshot(
      confirmedReading: 1000,
      displayReading: 4000,
      isLive: true,
      liveUpdatedAt: now,
      projectionRevision: 3,
    );
    final broadcast = TripTrackingLiveOdometerBroadcast.fromSnapshot(
      snapshot,
      now: now,
      activeTripId: 'trip_jump',
      expectedTripId: 'trip_jump',
    );
    final safe = broadcast.toSafeDashboardMap();

    expect(broadcast.status, TripTrackingLiveOdometerBroadcastStatus.rejected);
    expect(broadcast.reasonCodes, contains('live_projection_delta_too_large'));
    expect(broadcast.displayValue, isNull);
    expect(safe['impossibleProjectionDeltaBlocked'], isTrue);
    expect(safe['impossibleProjectionCanRender'], isFalse);
    expect(safe['writesConfirmedOdometer'], isFalse);
  });

  test('safe broadcast summaries never expose GPS, routes, or tokens', () {
    final safe = TripTrackingLiveOdometerBroadcast.fromSnapshot(
      LiveOdometerDisplaySnapshot(
        confirmedReading: 1000,
        displayReading: 1001,
        isLive: true,
        liveUpdatedAt: now,
      ),
      now: now,
      activeTripId: 'trip_safe',
      expectedTripId: 'trip_safe',
    ).toSafeDashboardMap();

    expect(safe['rawGpsIncluded'], isFalse);
    expect(safe['preciseLocationIncluded'], isFalse);
    expect(safe['routeGeometryIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
    expect(safe['gpsCanReplaceOdometer'], isFalse);
    expect(safe['mapboxCanReplaceOdometer'], isFalse);
  });
}
