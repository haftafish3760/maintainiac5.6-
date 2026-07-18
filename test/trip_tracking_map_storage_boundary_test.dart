import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_map_storage_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test('route storage budget can pause history without stopping GPS', () {
    final estimate = TripTrackingMapStoragePolicy.estimate(
      settings: const TripTrackingSettings().copyWith(
        gpsAssistedTrackingEnabled: true,
        mapPreviewEnabled: true,
        mapRouteHistorySavingEnabled: true,
        mapRouteHistoryDailyBudgetMb: .25,
        mapRouteHistorySampleIntervalSeconds: 15,
      ),
      drivingSecondsPerDay: 12 * 60 * 60,
      bytesPerPoint: 512,
    );
    final safe = estimate.toSafeDashboardMap();

    expect(estimate.allowedToPersistRoute, isFalse);
    expect(estimate.reasonCode, 'map_route_history_budget_exceeded');
    expect(safe['gpsTrackingCanRunWithoutMaps'], isTrue);
    expect(safe['routeStorageCanPauseWithoutStoppingGps'], isTrue);
    expect(safe['storageBudgetExhaustionCanOnlyPauseRouteHistory'], isTrue);
    expect(safe['userCanDisableRouteHistoryWithoutDisablingGps'], isTrue);
    expect(safe['mapboxResponseCanBypassBudget'], isFalse);
    expect(safe['canSilentlyDeleteRouteHistory'], isFalse);

    final validation = TripTrackingMapStorageSummaryValidation.fromSummary(
      safe,
    );
    expect(validation.isRenderable, isTrue);
    expect(validation.reasons, isEmpty);
  });

  test('live point budget exhaustion only pauses route persistence', () {
    final decision = TripTrackingMapStoragePolicy.canPersistNextRoutePoint(
      settings: const TripTrackingSettings().copyWith(
        gpsAssistedTrackingEnabled: true,
        mapPreviewEnabled: true,
        mapRouteHistorySavingEnabled: true,
        mapRouteHistoryDailyBudgetMb: 1,
      ),
      persistedPointsToday: 32768,
      bytesPerPoint: 32,
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.allowedToPersistPoint, isFalse);
    expect(decision.reasonCode, 'map_route_history_live_budget_exhausted');
    expect(safe['gpsTrackingCanContinueWithoutMaps'], isTrue);
    expect(safe['mapStorageFailureStopsGpsTracking'], isFalse);
    expect(safe['routeStorageCanPauseWithoutStoppingGps'], isTrue);
    expect(safe['storageBudgetExhaustionCanOnlyPauseRouteHistory'], isTrue);
    expect(safe['localTripLogProtected'], isTrue);
    expect(safe['purgeRequiresConfirmedBackupOrUserAction'], isTrue);

    final validation = TripTrackingMapStorageSummaryValidation.fromSummary(
      safe,
    );
    expect(validation.isRenderable, isTrue);
    expect(validation.reasons, isEmpty);
  });

  test('forged map storage summaries cannot override trip truth', () {
    final safe = TripTrackingMapStoragePolicy.estimate(
      settings: const TripTrackingSettings().copyWith(
        gpsAssistedTrackingEnabled: true,
        mapPreviewEnabled: true,
        mapRouteHistorySavingEnabled: true,
        mapRouteHistoryDailyBudgetMb: 1,
      ),
    ).toSafeDashboardMap();
    final validation = TripTrackingMapStorageSummaryValidation.fromSummary(
      safe..addAll({
        'gpsTrackingCanRunWithoutMaps': false,
        'routeStorageAdvisoryOnly': false,
        'routeStorageCanPauseWithoutStoppingGps': false,
        'storageBudgetExhaustionCanOnlyPauseRouteHistory': false,
        'userCanDisableRouteHistoryWithoutDisablingGps': false,
        'localTripLogProtected': false,
        'mapboxResponseCanBypassBudget': true,
        'mapboxFailureCanCorruptTripLog': true,
        'mapboxTimeoutCanStopGpsTracking': true,
        'mapboxRouteCanReplaceGpsDistance': true,
        'mapboxCanOverrideRouteBudget': true,
        'remoteRouteSummaryCanOverrideLocalTrip': true,
        'canSilentlyDeleteRouteHistory': true,
        'purgeRequiresConfirmedBackupOrUserAction': false,
        'odometerRemainsCanonical': false,
        'rawCoordinatesIncluded': true,
        'routeGeometryIncluded': true,
        'mapboxGeometryIncluded': true,
        'tokensIncluded': true,
        'debug': 'pk.public 35.123456,-80.123456',
      }),
    );

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('map_storage_blocks_gps_trip_log'));
    expect(validation.reasons, contains('mapbox_or_remote_can_override_trip'));
    expect(
      validation.reasons,
      contains('route_history_can_be_silently_deleted'),
    );
    expect(
      validation.reasons,
      contains('summary_contains_sensitive_map_material'),
    );
  });
}
