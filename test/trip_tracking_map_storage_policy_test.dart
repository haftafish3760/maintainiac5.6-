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
    expect(summary['tokensIncluded'], isFalse);
  });
}
