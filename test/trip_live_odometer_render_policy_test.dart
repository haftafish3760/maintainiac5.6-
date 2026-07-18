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
    expect(safe['odometerIsGlobalTruth'], isTrue);
    expect(safe['writesConfirmedOdometer'], isFalse);
    expect(safe['confirmedOnlyCanRenderWithoutActiveTrip'], isTrue);
    expect(
      TripLiveOdometerRenderSummaryValidation.fromSummary(safe).isRenderable,
      isTrue,
    );
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
    expect(safe['singleLiveOdometerSnapshotRequired'], isTrue);
    expect(safe['allDashboardSurfacesUseSameSnapshot'], isTrue);
    expect(safe['allDashboardSurfacesUseSameProjectionRevision'], isTrue);
    expect(safe['surfaceSpecificMileageCalculationAllowed'], isFalse);
    expect(safe['activeVehicleBlockUsesLiveProjection'], isTrue);
    expect(safe['activeVehicleBlockMustNotCacheProjection'], isTrue);
    expect(safe['vehicleProfileUsesLiveProjection'], isTrue);
    expect(safe['contractorDashboardUsesLiveProjection'], isTrue);
    expect(safe['fleetDashboardUsesLiveProjection'], isTrue);
    expect(safe['standardDashboardUsesLiveProjection'], isTrue);
    expect(safe['singleSnapshotMustDriveEverySubscribedSurface'], isTrue);
    expect(safe['surfaceSpecificTripIdsAllowed'], isFalse);
    expect(safe['liveProjectionRequiresDeviceLocalSource'], isTrue);
    expect(safe['liveProjectionRequiresOwnershipValidation'], isTrue);
    expect(safe['odometerIsGlobalTruth'], isTrue);
    expect(safe['physicalOdometerRequiredForOfficialMileage'], isTrue);
    expect(safe['confirmedOdometerOverridesExternalMileage'], isTrue);
    expect(safe['externalMileageCannotBecomeGlobalTruth'], isTrue);
    expect(safe['gpsDistanceCanOnlyAdviseMileageReview'], isTrue);
    expect(safe['mapMatchingCanOnlyAdviseMileageReview'], isTrue);
    expect(safe['optimizationCannotChangeOfficialMileage'], isTrue);
    expect(safe['matchingVehicleProfileRequired'], isTrue);
    expect(safe['projectionRevisionMustIncrease'], isTrue);
    expect(safe['displayValueValidated'], isTrue);
    expect(safe['confirmedDisplayValueValidated'], isTrue);
    final validation = TripLiveOdometerRenderSummaryValidation.fromSummary(
      safe,
    );
    expect(validation.isRenderable, isTrue);
    expect(validation.shouldNotifyListeners, isTrue);
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
      expect(safe['odometerIsGlobalTruth'], isTrue);
      expect(safe['writesConfirmedOdometer'], isFalse);
      expect(safe['gpsCanReplaceOdometer'], isFalse);
      expect(safe['liveRenderCanSetGlobalTruth'], isFalse);
      expect(safe['liveRenderCanChangeOfficialMileage'], isFalse);
      expect(safe['staleProjectionCanCommitMileage'], isFalse);
      expect(safe['staleProjectionCanNotifyAsFresh'], isFalse);
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
    expect(safe['blockedProjectionSuppressesNotify'], isTrue);
    expect(
      TripLiveOdometerRenderSummaryValidation.fromSummary(
        safe,
      ).shouldNotifyListeners,
      isFalse,
    );
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

  test('future live update is blocked across every dashboard surface', () {
    final decision = TripLiveOdometerRenderPolicy.evaluate(
      snapshot: LiveOdometerDisplaySnapshot(
        confirmedReading: 1000,
        displayReading: 1006,
        isLive: true,
        liveUpdatedAt: now.add(const Duration(minutes: 4)),
        projectionRevision: 5,
      ),
      now: now,
      activeTripId: 'trip_future',
      expectedTripId: 'trip_future',
      subscribedSurfaces: TripLiveOdometerRenderSurface.values,
    );
    final safe = decision.toSafeUiMap();

    expect(decision.status, TripLiveOdometerRenderStatus.blocked);
    expect(decision.shouldRender, isFalse);
    expect(decision.displayValue, isNull);
    expect(decision.reasonCodes, contains('live_update_time_in_future'));
    expect(safe['futureProjectionBlocked'], isTrue);
    expect(safe['futureProjectionCanRender'], isFalse);
    expect(safe['writesConfirmedOdometer'], isFalse);
  });

  test('out-of-range live odometer display blocks every dashboard surface', () {
    final decision = TripLiveOdometerRenderPolicy.evaluate(
      snapshot: LiveOdometerDisplaySnapshot(
        confirmedReading: 9999998,
        displayReading: 10000000,
        isLive: true,
        liveUpdatedAt: now,
        projectionRevision: 6,
      ),
      now: now,
      activeTripId: 'trip_range',
      expectedTripId: 'trip_range',
      subscribedSurfaces: TripLiveOdometerRenderSurface.values,
    );
    final safe = decision.toSafeUiMap();

    expect(decision.status, TripLiveOdometerRenderStatus.blocked);
    expect(decision.shouldNotifyListeners, isFalse);
    expect(decision.reasonCodes, contains('odometer_display_out_of_range'));
    expect(safe['odometerDisplayOutOfRangeBlocked'], isTrue);
    expect(safe['displayValueValidated'], isTrue);
  });

  test('impossible live odometer jump is blocked without repainting UI', () {
    final decision = TripLiveOdometerRenderPolicy.evaluate(
      snapshot: LiveOdometerDisplaySnapshot(
        confirmedReading: 1000,
        displayReading: 5000,
        isLive: true,
        liveUpdatedAt: now,
        projectionRevision: 6,
      ),
      now: now,
      activeTripId: 'trip_jump',
      expectedTripId: 'trip_jump',
      subscribedSurfaces: const {
        TripLiveOdometerRenderSurface.dashboard,
        TripLiveOdometerRenderSurface.activeVehicleBlock,
      },
    );
    final safe = decision.toSafeUiMap();

    expect(decision.status, TripLiveOdometerRenderStatus.blocked);
    expect(decision.shouldNotifyListeners, isFalse);
    expect(decision.reasonCodes, contains('live_projection_delta_too_large'));
    expect(safe['impossibleProjectionDeltaBlocked'], isTrue);
    expect(safe['impossibleProjectionCanRender'], isFalse);
    expect(safe['confirmedOdometerRemainsCanonical'], isTrue);
    expect(safe['odometerIsGlobalTruth'], isTrue);
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
      expect(
        decision.toSafeUiMap()['surfaceSubscriptionRequiredForNotify'],
        isTrue,
      );
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
      expect(safe['liveRenderCanSetGlobalTruth'], isFalse);
      expect(safe['mapboxCanIncreaseLiveMileage'], isFalse);
      expect(safe.toString(), isNot(contains('pk.')));
      expect(safe.toString(), isNot(contains('sk.')));
    },
  );

  test(
    'safe UI summary validation rejects forged surface-specific mileage',
    () {
      final safe = TripLiveOdometerRenderPolicy.evaluate(
        snapshot: LiveOdometerDisplaySnapshot(
          confirmedReading: 1000,
          displayReading: 1002,
          isLive: true,
          liveUpdatedAt: now,
        ),
        now: now,
        activeTripId: 'trip_safe',
        expectedTripId: 'trip_safe',
        subscribedSurfaces: TripLiveOdometerRenderSurface.values,
      ).toSafeUiMap();

      expect(
        TripLiveOdometerRenderSummaryValidation.fromSummary({
          ...safe,
          'surfaceSpecificMileageCalculationAllowed': true,
          'activeVehicleBlockMustNotCacheProjection': false,
          'allDashboardSurfacesUseSameProjectionRevision': false,
        }).isRenderable,
        isFalse,
      );
      expect(
        TripLiveOdometerRenderSummaryValidation.fromSummary({
          ...safe,
          'writesConfirmedOdometer': true,
          'mapboxCanIncreaseLiveMileage': true,
          'calibrationCanCommitWithoutReview': true,
          'staleProjectionCanNotifyAsFresh': true,
        }).isRenderable,
        isFalse,
      );
      expect(
        TripLiveOdometerRenderSummaryValidation.fromSummary({
          ...safe,
          'firestoreCanOverrideLiveDisplay': true,
        }).isRenderable,
        isFalse,
      );
      expect(
        TripLiveOdometerRenderSummaryValidation.fromSummary({
          ...safe,
          'debug': '35.123456,-80.123456 token=sk.secret',
        }).isRenderable,
        isFalse,
      );
    },
  );

  test('safe UI summary validation rejects malformed display values', () {
    final safe = TripLiveOdometerRenderPolicy.evaluate(
      snapshot: const LiveOdometerDisplaySnapshot(
        confirmedReading: 1000,
        displayReading: 1000,
        isLive: false,
      ),
      now: now,
      activeTripId: null,
      expectedTripId: 'trip_confirmed',
      subscribedSurfaces: TripLiveOdometerRenderSurface.values,
    ).toSafeUiMap();

    expect(
      TripLiveOdometerRenderSummaryValidation.fromSummary({
        ...safe,
        'displayValue': '1000',
      }).reasons,
      contains('invalid_display_value'),
    );
    expect(
      TripLiveOdometerRenderSummaryValidation.fromSummary({
        ...safe,
        'surfaces': ['dashboard', 'unknownSurface'],
      }).reasons,
      contains('invalid_render_surfaces'),
    );
  });
}
