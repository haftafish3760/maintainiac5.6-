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
}
