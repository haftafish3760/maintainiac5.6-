import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/live_odometer_display.dart';
import 'package:maintaniac/shared/trip_tracking/trip_live_odometer_render_policy.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18, 12);

  test('confirmed odometer renders everywhere without live confirmation', () {
    final decision = TripLiveOdometerRenderPolicy.evaluate(
      snapshot: const LiveOdometerDisplaySnapshot(
        confirmedReading: 1000,
        displayReading: 1000,
        isLive: false,
      ),
      now: now,
      activeTripId: null,
      expectedTripId: 'trip_confirmed',
      subscribedSurfaces: TripLiveOdometerRenderSurface.values,
    );
    final safe = decision.toSafeUiMap();

    expect(decision.status, TripLiveOdometerRenderStatus.confirmedOnly);
    expect(decision.shouldRender, isTrue);
    expect(decision.shouldNotifyListeners, isTrue);
    expect(decision.reviewRequired, isFalse);
    expect(decision.displayValue, '0001000');
    expect(safe['manualConfirmationRequired'], isFalse);
    expect(safe['calendarReviewUsesConfirmedTruth'], isTrue);
    expect(safe['writesConfirmedOdometer'], isFalse);
  });

  test('fresh live projection updates all subscribed dashboard surfaces', () {
    final decision = TripLiveOdometerRenderPolicy.evaluate(
      snapshot: LiveOdometerDisplaySnapshot(
        confirmedReading: 1000,
        displayReading: 1003,
        isLive: true,
        liveUpdatedAt: now.subtract(const Duration(seconds: 20)),
        projectionRevision: 7,
      ),
      now: now,
      activeTripId: 'trip_live',
      expectedTripId: 'trip_live',
      subscribedSurfaces: const {
        TripLiveOdometerRenderSurface.dashboard,
        TripLiveOdometerRenderSurface.activeVehicleBlock,
        TripLiveOdometerRenderSurface.vehicleProfile,
        TripLiveOdometerRenderSurface.contractorDashboard,
        TripLiveOdometerRenderSurface.fleetDashboard,
      },
    );
    final safe = decision.toSafeUiMap();

    expect(decision.status, TripLiveOdometerRenderStatus.liveRenderable);
    expect(decision.shouldRender, isTrue);
    expect(decision.shouldNotifyListeners, isTrue);
    expect(decision.displayValue, '0001003');
    expect(safe['liveUiMustRefreshOnProjectionChange'], isTrue);
    expect(safe['allDashboardSurfacesUseSameSnapshot'], isTrue);
    expect(safe['activeVehicleBlockUsesLiveProjection'], isTrue);
    expect(safe['vehicleProfileUsesLiveProjection'], isTrue);
    expect(safe['contractorDashboardUsesLiveProjection'], isTrue);
    expect(safe['fleetDashboardUsesLiveProjection'], isTrue);
  });

  test(
    'stale live projection renders as review-only without committing mileage',
    () {
      final decision = TripLiveOdometerRenderPolicy.evaluate(
        snapshot: LiveOdometerDisplaySnapshot(
          confirmedReading: 1000,
          displayReading: 1004,
          isLive: true,
          liveUpdatedAt: now.subtract(const Duration(minutes: 7)),
          projectionRevision: 8,
        ),
        now: now,
        activeTripId: 'trip_stale',
        expectedTripId: 'trip_stale',
        subscribedSurfaces: const {
          TripLiveOdometerRenderSurface.dashboard,
          TripLiveOdometerRenderSurface.activeVehicleBlock,
        },
      );
      final safe = decision.toSafeUiMap();

      expect(decision.status, TripLiveOdometerRenderStatus.staleReviewOnly);
      expect(decision.shouldRender, isTrue);
      expect(decision.reviewRequired, isTrue);
      expect(safe['confirmedOdometerRemainsCanonical'], isTrue);
      expect(safe['writesConfirmedOdometer'], isFalse);
      expect(safe['gpsCanReplaceOdometer'], isFalse);
    },
  );

  test('trip mismatch blocks live render and suppresses stale remote data', () {
    final decision = TripLiveOdometerRenderPolicy.evaluate(
      snapshot: LiveOdometerDisplaySnapshot(
        confirmedReading: 1000,
        displayReading: 1005,
        isLive: true,
        liveUpdatedAt: now,
        projectionRevision: 3,
      ),
      now: now,
      activeTripId: 'trip_other',
      expectedTripId: 'trip_expected',
      subscribedSurfaces: TripLiveOdometerRenderSurface.values,
    );
    final safe = decision.toSafeUiMap();

    expect(decision.status, TripLiveOdometerRenderStatus.blocked);
    expect(decision.shouldRender, isFalse);
    expect(decision.shouldNotifyListeners, isFalse);
    expect(decision.displayValue, isNull);
    expect(decision.confirmedDisplayValue, isNull);
    expect(decision.reasonCodes, contains('live_trip_id_mismatch'));
    expect(safe['firestoreCanOverrideLiveDisplay'], isFalse);
  });

  test('malformed live snapshot cannot roll back the UI odometer', () {
    final decision = TripLiveOdometerRenderPolicy.evaluate(
      snapshot: const LiveOdometerDisplaySnapshot(
        confirmedReading: 1000,
        displayReading: 999,
        isLive: true,
        projectionRevision: -1,
      ),
      now: now,
      activeTripId: 'trip_bad',
      expectedTripId: 'trip_bad',
      subscribedSurfaces: const {TripLiveOdometerRenderSurface.dashboard},
    );

    expect(decision.status, TripLiveOdometerRenderStatus.blocked);
    expect(decision.shouldRender, isFalse);
    expect(decision.reasonCodes, contains('display_below_confirmed_reading'));
    expect(decision.reasonCodes, contains('negative_projection_revision'));
    expect(decision.reasonCodes, contains('missing_live_update_time'));
  });

  test(
    'no subscribed surface keeps snapshot safe but avoids redundant repaint',
    () {
      final decision = TripLiveOdometerRenderPolicy.evaluate(
        snapshot: LiveOdometerDisplaySnapshot(
          confirmedReading: 1000,
          displayReading: 1002,
          isLive: true,
          liveUpdatedAt: now,
        ),
        now: now,
        activeTripId: 'trip_live',
        expectedTripId: 'trip_live',
        subscribedSurfaces: const {},
      );

      expect(decision.status, TripLiveOdometerRenderStatus.liveRenderable);
      expect(decision.shouldRender, isTrue);
      expect(decision.shouldNotifyListeners, isFalse);
      expect(decision.reasonCodes, contains('no_dashboard_surface_subscribed'));
    },
  );

  test(
    'safe UI map does not expose GPS, route geometry, Mapbox, or tokens',
    () {
      final safe = TripLiveOdometerRenderPolicy.evaluate(
        snapshot: LiveOdometerDisplaySnapshot(
          confirmedReading: 1000,
          displayReading: 1001,
          isLive: true,
          liveUpdatedAt: now,
        ),
        now: now,
        activeTripId: 'trip_safe',
        expectedTripId: 'trip_safe',
        subscribedSurfaces: TripLiveOdometerRenderSurface.values,
      ).toSafeUiMap();

      expect(safe['advisoryOnly'], isTrue);
      expect(safe['remoteDisplayCanOverrideLocalTrip'], isFalse);
      expect(safe['rawGpsIncluded'], isFalse);
      expect(safe['preciseLocationIncluded'], isFalse);
      expect(safe['routeGeometryIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
      expect(safe['mapboxCanReplaceOdometer'], isFalse);
      expect(safe.toString(), isNot(contains('pk.')));
      expect(safe.toString(), isNot(contains('sk.')));
    },
  );
}
