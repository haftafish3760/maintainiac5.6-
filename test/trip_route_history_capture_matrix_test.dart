import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_route_history_capture_policy.dart';

void main() {
  test('route history matrix preserves free GPS tracking without maps', () {
    final cases = <_RouteHistoryCase>[
      _RouteHistoryCase(
        name: 'gps disabled',
        maps: true,
        routeHistory: true,
        mapboxRuntime: true,
        storageMb: 5000,
        budgetMb: 1,
        intervalSeconds: 15,
        expectedPlan: TripRouteHistoryPlan.disabled,
        expectedReason: TripRouteHistoryReason.gpsOnlyFreeTracker,
        gpsEnabled: false,
      ),
      _RouteHistoryCase(
        name: 'maps disabled',
        maps: false,
        routeHistory: true,
        mapboxRuntime: true,
        storageMb: 5000,
        budgetMb: 1,
        intervalSeconds: 15,
        expectedPlan: TripRouteHistoryPlan.textOnlyAnchors,
        expectedReason: TripRouteHistoryReason.mapsDisabled,
      ),
      _RouteHistoryCase(
        name: 'route history not opted in',
        maps: true,
        routeHistory: false,
        mapboxRuntime: true,
        storageMb: 5000,
        budgetMb: 1,
        intervalSeconds: 15,
        expectedPlan: TripRouteHistoryPlan.textOnlyAnchors,
        expectedReason: TripRouteHistoryReason.userNotOptedIn,
      ),
      _RouteHistoryCase(
        name: 'critically low storage',
        maps: true,
        routeHistory: true,
        mapboxRuntime: true,
        storageMb: 20,
        budgetMb: 1,
        intervalSeconds: 15,
        expectedPlan: TripRouteHistoryPlan.textOnlyAnchors,
        expectedReason: TripRouteHistoryReason.storageCriticallyLowTextOnly,
      ),
      _RouteHistoryCase(
        name: 'free compact trace',
        maps: true,
        routeHistory: true,
        mapboxRuntime: true,
        storageMb: 5000,
        budgetMb: .5,
        intervalSeconds: 1,
        expectedPlan: TripRouteHistoryPlan.compactGpsTrace,
        expectedReason: TripRouteHistoryReason.compactTraceAllowed,
      ),
      _RouteHistoryCase(
        name: 'paid compact trace',
        maps: true,
        routeHistory: true,
        mapboxRuntime: true,
        storageMb: 5000,
        budgetMb: 3,
        intervalSeconds: 1,
        tier: TripRouteHistoryAccountTier.paid,
        expectedPlan: TripRouteHistoryPlan.compactGpsTrace,
        expectedReason: TripRouteHistoryReason.compactTraceAllowed,
      ),
    ];

    for (final entry in cases) {
      final decision = TripRouteHistoryCapturePolicy.evaluate(
        accountTier: entry.tier,
        gpsAssistedTrackingEnabled: entry.gpsEnabled,
        userOptedIntoMaps: entry.maps,
        userOptedIntoRouteHistory: entry.routeHistory,
        mapboxRuntimeAvailable: entry.mapboxRuntime,
        requestedDailyBudgetMb: entry.budgetMb,
        availableStorageMb: entry.storageMb,
        requestedSampleIntervalSeconds: entry.intervalSeconds,
      );
      final safe = decision.toSafeSummary();
      final validation = TripRouteHistorySummaryValidation.fromSummary(safe);

      expect(decision.plan, entry.expectedPlan, reason: entry.name);
      expect(decision.reason, entry.expectedReason, reason: entry.name);
      expect(validation.isRenderable, isTrue, reason: entry.name);
      expect(safe['gpsAssistedTrackingAvailableWithoutMaps'], isTrue);
      expect(safe['mapsRequiredForTripTracking'], isFalse);
      expect(safe['textTripLogStillWritten'], isTrue);
      expect(safe['mapboxFailureStopsTextTripLog'], isFalse);
      expect(safe['mapboxCanReplaceOdometer'], isFalse);
      expect(safe['routeHistoryCanConfirmMileage'], isFalse);
      expect(safe['firestoreMirrorOnly'], isTrue);
      expect(safe['rawCoordinatesIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
    }
  });
}

class _RouteHistoryCase {
  const _RouteHistoryCase({
    required this.name,
    required this.maps,
    required this.routeHistory,
    required this.mapboxRuntime,
    required this.storageMb,
    required this.budgetMb,
    required this.intervalSeconds,
    required this.expectedPlan,
    required this.expectedReason,
    this.gpsEnabled = true,
    this.tier = TripRouteHistoryAccountTier.free,
  });

  final String name;
  final bool gpsEnabled;
  final bool maps;
  final bool routeHistory;
  final bool mapboxRuntime;
  final int storageMb;
  final double budgetMb;
  final int intervalSeconds;
  final TripRouteHistoryAccountTier tier;
  final TripRouteHistoryPlan expectedPlan;
  final TripRouteHistoryReason expectedReason;
}
