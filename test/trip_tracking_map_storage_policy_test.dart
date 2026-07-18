import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_map_storage_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test('GPS assisted tracking can run without maps or route history', () {
    final estimate = TripTrackingMapStoragePolicy.estimate(
      settings: const TripTrackingSettings().copyWith(
        gpsAssistedTrackingEnabled: true,
      ),
    );
    final summary = estimate.toSafeDashboardMap();

    expect(estimate.enabled, isFalse);
    expect(estimate.allowedToPersistRoute, isFalse);
    expect(estimate.reasonCode, 'maps_not_enabled');
    expect(summary['gpsTrackingCanRunWithoutMaps'], isTrue);
    expect(summary['mapsRequireSeparateOptIn'], isTrue);
    expect(summary['routeHistoryRequiresSeparateOptIn'], isTrue);
    expect(summary['freePlanMaxDailyBudgetMb'], 2);
    expect(summary['compactRoutePointBytes'], 96);
    expect(summary['oneToThreeSecondRawPingStorageDiscouraged'], isTrue);
    expect(summary['routeStorageAdvisoryOnly'], isTrue);
    expect(summary['mapPreviewCanRunWithoutRouteHistory'], isTrue);
    expect(summary['mapboxResponseCanBypassBudget'], isFalse);
    expect(summary['mapboxFailureCanCorruptTripLog'], isFalse);
    expect(summary['mapboxTimeoutCanStopGpsTracking'], isFalse);
    expect(summary['mapboxRouteCanReplaceGpsDistance'], isFalse);
    expect(summary['mapboxCanOverrideRouteBudget'], isFalse);
    expect(summary['remoteRouteSummaryCanOverrideLocalTrip'], isFalse);
    expect(summary['routeStorageTrustedAfterValidationOnly'], isTrue);
    expect(summary['malformedRouteStoragePayloadFailsSafe'], isTrue);
    expect(summary['canSilentlyDeleteRouteHistory'], isFalse);
    expect(summary['localTripLogProtected'], isTrue);
    expect(summary['purgeRequiresConfirmedBackupOrUserAction'], isTrue);
    expect(summary['rawCoordinatesIncluded'], isFalse);
    expect(summary['routeGeometryIncluded'], isFalse);
    expect(summary['mapboxGeometryIncluded'], isFalse);
    expect(summary['tokensIncluded'], isFalse);
  });

  test('route history requires map preview and explicit storage budget', () {
    final noMapPreview = TripTrackingMapStoragePolicy.estimate(
      settings: const TripTrackingSettings().copyWith(
        gpsAssistedTrackingEnabled: true,
        mapRouteHistorySavingEnabled: true,
        mapRouteHistoryDailyBudgetMb: 1,
      ),
    );
    final noBudget = TripTrackingMapStoragePolicy.estimate(
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        mapPreviewEnabled: true,
        mapRouteHistorySavingEnabled: true,
        mapRouteHistoryDailyBudgetMb: 0,
      ),
    );

    expect(noMapPreview.allowedToPersistRoute, isFalse);
    expect(noMapPreview.reasonCode, 'maps_not_enabled');
    expect(noBudget.allowedToPersistRoute, isFalse);
    expect(noBudget.reasonCode, 'map_route_history_budget_missing');
  });

  test(
    'route history estimate gates one-to-three second style ping volume',
    () {
      final fastRoute = TripTrackingMapStoragePolicy.estimate(
        settings: const TripTrackingSettings().copyWith(
          gpsAssistedTrackingEnabled: true,
          mapPreviewEnabled: true,
          mapRouteHistorySavingEnabled: true,
          mapRouteHistoryDailyBudgetMb: 1,
          mapRouteHistorySampleIntervalSeconds: 15,
        ),
        drivingSecondsPerDay: 12 * 60 * 60,
        bytesPerPoint: 512,
      );
      final compactRoute = TripTrackingMapStoragePolicy.estimate(
        settings: const TripTrackingSettings().copyWith(
          gpsAssistedTrackingEnabled: true,
          mapPreviewEnabled: true,
          mapRouteHistorySavingEnabled: true,
          mapRouteHistoryDailyBudgetMb: 1,
          mapRouteHistorySampleIntervalSeconds: 60,
        ),
        drivingSecondsPerDay: 8 * 60 * 60,
        bytesPerPoint: 96,
      );

      expect(fastRoute.estimatedSamplesPerDay, 2880);
      expect(fastRoute.estimatedDailyMb, greaterThan(1));
      expect(fastRoute.allowedToPersistRoute, isFalse);
      expect(fastRoute.reasonCode, 'map_route_history_budget_exceeded');
      expect(compactRoute.estimatedSamplesPerDay, 480);
      expect(compactRoute.estimatedDailyMb, lessThan(1));
      expect(compactRoute.allowedToPersistRoute, isTrue);
      expect(compactRoute.reasonCode, 'map_route_history_within_budget');
    },
  );

  test('malformed estimate inputs are bounded before dashboard use', () {
    final estimate = TripTrackingMapStoragePolicy.estimate(
      settings: const TripTrackingSettings().copyWith(
        gpsAssistedTrackingEnabled: true,
        mapPreviewEnabled: true,
        mapRouteHistorySavingEnabled: true,
        mapRouteHistoryDailyBudgetMb: 2,
        mapRouteHistorySampleIntervalSeconds: 15,
      ),
      drivingSecondsPerDay: 999999,
      bytesPerPoint: 999999,
    );

    expect(estimate.estimatedSamplesPerDay, 5760);
    expect(estimate.estimatedDailyMb, 2.813);
    expect(estimate.allowedToPersistRoute, isFalse);
    expect(estimate.toSafeDashboardMap()['exceedsDailyBudget'], isTrue);
  });

  test(
    'direct settings values cannot create invalid route budget summaries',
    () {
      final malformed = TripTrackingMapStoragePolicy.estimate(
        settings: const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          mapPreviewEnabled: true,
          mapRouteHistorySavingEnabled: true,
          mapRouteHistoryDailyBudgetMb: double.nan,
          mapRouteHistorySampleIntervalSeconds: 0,
        ),
      );
      final oversized = TripTrackingMapStoragePolicy.estimate(
        settings: const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          mapPreviewEnabled: true,
          mapRouteHistorySavingEnabled: true,
          mapRouteHistoryDailyBudgetMb: 99,
          mapRouteHistorySampleIntervalSeconds: 1,
        ),
        drivingSecondsPerDay: 60,
        bytesPerPoint: 32,
      );

      expect(malformed.allowedToPersistRoute, isFalse);
      expect(malformed.reasonCode, 'map_route_history_budget_missing');
      expect(malformed.dailyBudgetMb, 0);
      expect(malformed.sampleIntervalSeconds, 15);
      expect(malformed.toSafeDashboardMap().toString(), isNot(contains('NaN')));
      expect(oversized.dailyBudgetMb, 2);
      expect(oversized.toSafeDashboardMap()['freePlanMaxDailyBudgetMb'], 2);
      expect(oversized.sampleIntervalSeconds, 15);
      expect(oversized.allowedToPersistRoute, isTrue);
    },
  );

  test('live route point persistence stops at the user daily budget', () {
    final settings = const TripTrackingSettings().copyWith(
      gpsAssistedTrackingEnabled: true,
      mapPreviewEnabled: true,
      mapRouteHistorySavingEnabled: true,
      mapRouteHistoryDailyBudgetMb: 1,
      mapRouteHistorySampleIntervalSeconds: 60,
    );
    final nearLimit = TripTrackingMapStoragePolicy.canPersistNextRoutePoint(
      settings: settings,
      persistedPointsToday: 32767,
      bytesPerPoint: 32,
    );
    final exhausted = TripTrackingMapStoragePolicy.canPersistNextRoutePoint(
      settings: settings,
      persistedPointsToday: 32768,
      bytesPerPoint: 32,
    );

    expect(nearLimit.allowedToPersistPoint, isTrue);
    expect(nearLimit.reasonCode, 'map_route_history_point_within_live_budget');
    expect(nearLimit.maxRoutePointsPerDay, 32768);
    expect(nearLimit.remainingPointsToday, 0);
    expect(exhausted.allowedToPersistPoint, isFalse);
    expect(exhausted.reasonCode, 'map_route_history_live_budget_exhausted');
    expect(
      exhausted.toSafeDashboardMap()['mapStorageFailureStopsGpsTracking'],
      isFalse,
    );
    expect(
      exhausted.toSafeDashboardMap()['canSilentlyDeleteRouteHistory'],
      isFalse,
    );
    expect(exhausted.toSafeDashboardMap()['localTripLogProtected'], isTrue);
    expect(
      exhausted.toSafeDashboardMap()['mapboxResponseCanBypassBudget'],
      isFalse,
    );
    expect(exhausted.toSafeDashboardMap()['routeStorageAdvisoryOnly'], isTrue);
    expect(
      exhausted
          .toSafeDashboardMap()['purgeRequiresConfirmedBackupOrUserAction'],
      isTrue,
    );
    expect(exhausted.toSafeDashboardMap()['rawCoordinatesIncluded'], isFalse);
  });

  test('route point persistence fails gracefully while GPS can continue', () {
    final decision = TripTrackingMapStoragePolicy.canPersistNextRoutePoint(
      settings: const TripTrackingSettings().copyWith(
        gpsAssistedTrackingEnabled: true,
        mapPreviewEnabled: false,
        mapRouteHistorySavingEnabled: true,
        mapRouteHistoryDailyBudgetMb: 1,
      ),
      persistedPointsToday: -5,
    );
    final summary = decision.toSafeDashboardMap();

    expect(decision.allowedToPersistPoint, isFalse);
    expect(decision.persistedPointsToday, 0);
    expect(decision.reasonCode, 'maps_not_enabled');
    expect(summary['gpsTrackingCanContinueWithoutMaps'], isTrue);
    expect(summary['mapPreviewCanRunWithoutRouteHistory'], isTrue);
    expect(summary['oneToThreeSecondRawPingStorageDiscouraged'], isTrue);
    expect(summary['tokensIncluded'], isFalse);
  });

  test('direct map estimate summaries sanitize malformed public fields', () {
    const estimate = TripTrackingMapStorageEstimate(
      enabled: true,
      allowedToPersistRoute: true,
      reasonCode: 'token=sk.secret lat=35.1',
      sampleIntervalSeconds: 0,
      dailyBudgetMb: double.infinity,
      estimatedSamplesPerDay: -100,
      estimatedDailyMb: double.nan,
    );
    final summary = estimate.toSafeDashboardMap();

    expect(summary['reasonCode'], 'maps_not_enabled');
    expect(summary['mapStorageEnabled'], isFalse);
    expect(summary['allowedToPersistRoute'], isFalse);
    expect(summary['sampleIntervalSeconds'], 15);
    expect(summary['dailyBudgetMb'], 0);
    expect(summary['estimatedSamplesPerDay'], 0);
    expect(summary['estimatedDailyMb'], 0);
    expect(summary['mapboxFailureCanCorruptTripLog'], isFalse);
    expect(summary['mapboxCanOverrideRouteBudget'], isFalse);
    expect(summary['remoteRouteSummaryCanOverrideLocalTrip'], isFalse);
    expect(summary['routeStorageTrustedAfterValidationOnly'], isTrue);
    expect(summary['malformedRouteStoragePayloadFailsSafe'], isTrue);
    expect(summary.toString(), isNot(contains('sk.secret')));
    expect(summary.toString(), isNot(contains('35.1')));
  });

  test('direct route point summaries clamp counters and isolate Mapbox', () {
    const decision = TripTrackingMapRoutePointDecision(
      allowedToPersistPoint: true,
      reasonCode: 'mapbox_timeout_at_-80',
      persistedPointsToday: -10,
      maxRoutePointsPerDay: -5,
      remainingPointsToday: -1,
      dailyBudgetMb: 99,
      estimatedStoredMbAfterPoint: double.infinity,
    );
    final summary = decision.toSafeDashboardMap();

    expect(summary['reasonCode'], 'maps_not_enabled');
    expect(summary['allowedToPersistPoint'], isFalse);
    expect(summary['persistedPointsToday'], 0);
    expect(summary['maxRoutePointsPerDay'], 0);
    expect(summary['remainingPointsToday'], 0);
    expect(summary['dailyBudgetMb'], 2);
    expect(summary['estimatedStoredMbAfterPoint'], 0);
    expect(summary['gpsTrackingCanContinueWithoutMaps'], isTrue);
    expect(summary['mapStorageFailureStopsGpsTracking'], isFalse);
    expect(summary['mapboxTimeoutCanStopGpsTracking'], isFalse);
    expect(summary['mapboxRouteCanReplaceGpsDistance'], isFalse);
    expect(summary['mapboxCanOverrideRouteBudget'], isFalse);
    expect(summary['remoteRouteSummaryCanOverrideLocalTrip'], isFalse);
    expect(summary['routeStorageTrustedAfterValidationOnly'], isTrue);
    expect(summary['malformedRouteStoragePayloadFailsSafe'], isTrue);
  });

  test('direct route summaries cannot forge budget authorization', () {
    const estimate = TripTrackingMapStorageEstimate(
      enabled: true,
      allowedToPersistRoute: true,
      reasonCode: 'map_route_history_budget_exceeded',
      sampleIntervalSeconds: 15,
      dailyBudgetMb: 1,
      estimatedSamplesPerDay: 90000,
      estimatedDailyMb: 2,
    );
    const decision = TripTrackingMapRoutePointDecision(
      allowedToPersistPoint: true,
      reasonCode: 'map_route_history_live_budget_exhausted',
      persistedPointsToday: 32768,
      maxRoutePointsPerDay: 32768,
      remainingPointsToday: 0,
      dailyBudgetMb: 1,
      estimatedStoredMbAfterPoint: 1,
    );

    expect(estimate.toSafeDashboardMap()['allowedToPersistRoute'], isFalse);
    expect(decision.toSafeDashboardMap()['allowedToPersistPoint'], isFalse);
  });

  test('route point counters are capped before storage math', () {
    final decision = TripTrackingMapStoragePolicy.canPersistNextRoutePoint(
      settings: const TripTrackingSettings().copyWith(
        gpsAssistedTrackingEnabled: true,
        mapPreviewEnabled: true,
        mapRouteHistorySavingEnabled: true,
        mapRouteHistoryDailyBudgetMb: 2,
        mapRouteHistorySampleIntervalSeconds: 60,
      ),
      persistedPointsToday: 999999999999,
      bytesPerPoint: 512,
    );
    final summary = decision.toSafeDashboardMap();

    expect(decision.persistedPointsToday, 1000000);
    expect(summary['persistedPointsToday'], 1000000);
    expect(summary['allowedToPersistPoint'], isFalse);
    expect(summary['mapStorageFailureStopsGpsTracking'], isFalse);
    expect(summary['mapboxResponseCanBypassBudget'], isFalse);
    expect(summary['localTripLogProtected'], isTrue);
  });
}
