import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_route_history_capture_policy.dart';

void main() {
  test('GPS assisted tracking works without maps or route history', () {
    final decision = evaluate(userOptedIntoMaps: false);
    final safe = decision.toSafeSummary();

    expect(decision.plan, TripRouteHistoryPlan.textOnlyAnchors);
    expect(decision.reason, TripRouteHistoryReason.mapsDisabled);
    expect(safe['gpsAssistedTrackingAvailableWithoutMaps'], isTrue);
    expect(safe['mapsRequiredForTripTracking'], isFalse);
    expect(safe['textTripLogStillWritten'], isTrue);
    expect(safe['textTripLogCanContinueAtLowStorage'], isTrue);
  });

  test('route history requires separate explicit opt in', () {
    final decision = evaluate(
      userOptedIntoMaps: true,
      userOptedIntoRouteHistory: false,
    );

    expect(decision.plan, TripRouteHistoryPlan.textOnlyAnchors);
    expect(decision.reason, TripRouteHistoryReason.userNotOptedIn);
    expect(decision.canCaptureRouteHistory, isFalse);
  });

  test('free users are bounded to compact trace cadence and point caps', () {
    final decision = evaluate(
      userOptedIntoMaps: true,
      userOptedIntoRouteHistory: true,
      requestedDailyBudgetMb: 0.5,
      requestedSampleIntervalSeconds: 1,
    );
    final safe = decision.toSafeSummary();

    expect(decision.plan, TripRouteHistoryPlan.compactGpsTrace);
    expect(decision.recommendedSampleIntervalSeconds, 15);
    expect(decision.maximumRetainedPointsPerDay, lessThanOrEqualTo(2500));
    expect(safe['oneToThreeSecondRawPingStorageAllowed'], isFalse);
    expect(safe['rawHighFrequencyPingsRetained'], isFalse);
  });

  test(
    'paid users can choose tighter cadence but still have bounded history',
    () {
      final decision = evaluate(
        accountTier: TripRouteHistoryAccountTier.paid,
        userOptedIntoMaps: true,
        userOptedIntoRouteHistory: true,
        requestedDailyBudgetMb: 3,
        requestedSampleIntervalSeconds: 2,
      );

      expect(decision.plan, TripRouteHistoryPlan.compactGpsTrace);
      expect(decision.recommendedSampleIntervalSeconds, 5);
      expect(decision.maximumRetainedPointsPerDay, lessThanOrEqualTo(12000));
    },
  );

  test('low storage and tiny budget degrade to text-only trip logging', () {
    final lowStorage = evaluate(
      userOptedIntoMaps: true,
      userOptedIntoRouteHistory: true,
      availableStorageMb: 250,
      requestedDailyBudgetMb: 2,
    );
    final tinyBudget = evaluate(
      userOptedIntoMaps: true,
      userOptedIntoRouteHistory: true,
      requestedDailyBudgetMb: 0.1,
    );
    final criticalStorage = evaluate(
      userOptedIntoMaps: true,
      userOptedIntoRouteHistory: true,
      availableStorageMb: 20,
      requestedDailyBudgetMb: 2,
    );

    expect(lowStorage.plan, TripRouteHistoryPlan.textOnlyAnchors);
    expect(
      lowStorage.reason,
      TripRouteHistoryReason.storageTooLowForRouteHistory,
    );
    expect(tinyBudget.reason, TripRouteHistoryReason.dailyBudgetTooSmall);
    expect(
      criticalStorage.reason,
      TripRouteHistoryReason.storageCriticallyLowTextOnly,
    );
    expect(
      criticalStorage.toSafeSummary()['criticalStorageTextOnlyFloorMb'],
      25,
    );
  });

  test('safe summary keeps route history advisory and token free', () {
    final safe = evaluate(
      accountTier: TripRouteHistoryAccountTier.beta,
      userOptedIntoMaps: true,
      userOptedIntoRouteHistory: true,
      requestedDailyBudgetMb: 1,
    ).toSafeSummary();

    expect(safe['routeHistoryCanConfirmMileage'], isFalse);
    expect(safe['mapboxCanReplaceOdometer'], isFalse);
    expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
    expect(safe['rawCoordinatesIncluded'], isFalse);
    expect(safe['routeGeometryIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
    expect(safe['durableStorageRemainsSharedAcrossModules'], isTrue);
    expect(safe['routeHistoryCleanupRequiresExplicitUserAction'], isTrue);
    expect(safe['mapboxFailureStopsTextTripLog'], isFalse);
    expect(safe['firestoreCanEnableMapsWithoutUserOptIn'], isFalse);
    expect(safe['remoteConfigCanIncreaseSamplingCadence'], isFalse);
    expect(safe['remoteConfigCanExceedDailyBudget'], isFalse);
    expect(safe.toString(), isNot(contains('pk.')));
    expect(safe.toString(), isNot(contains('sk.')));
  });

  test('route history summary validates only bounded advisory payloads', () {
    final validation = TripRouteHistorySummaryValidation.fromSummary(
      evaluate(
        accountTier: TripRouteHistoryAccountTier.beta,
        userOptedIntoMaps: true,
        userOptedIntoRouteHistory: true,
        requestedDailyBudgetMb: 1,
      ).toSafeSummary(),
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.plan, TripRouteHistoryPlan.compactGpsTrace);
    expect(validation.reasons, isEmpty);
  });

  test(
    'route history summary rejects map, remote, and storage authority drift',
    () {
      final validation = TripRouteHistorySummaryValidation.fromSummary(
        evaluate(
          accountTier: TripRouteHistoryAccountTier.beta,
          userOptedIntoMaps: true,
          userOptedIntoRouteHistory: true,
          requestedDailyBudgetMb: 1,
        ).toSafeSummary()..addAll({
          'mapsRequiredForTripTracking': true,
          'freeGpsTripTrackerRemainsFree': false,
          'mapboxFailureStopsTextTripLog': true,
          'firestoreCanEnableMapsWithoutUserOptIn': true,
          'userCanDisableMapRouteHistoryAnytime': false,
          'oneToThreeSecondRawPingStorageAllowed': true,
          'remoteConfigCanIncreaseSamplingCadence': true,
          'remoteConfigCanExceedDailyBudget': true,
          'mapboxCanReplaceTripLog': true,
          'mapboxCanReplaceOdometer': true,
          'routeHistoryCanConfirmMileage': true,
          'durableStorageRemainsSharedAcrossModules': false,
          'routeHistoryCleanupRequiresExplicitUserAction': false,
          'rawCoordinatesIncluded': true,
          'routeGeometryIncluded': true,
          'tokensIncluded': true,
          'debug': 'pk.token 35.123456,-80.123456',
        }),
      );

      expect(validation.isRenderable, isFalse);
      expect(validation.reasons, contains('gps_text_log_boundary_missing'));
      expect(
        validation.reasons,
        contains('route_history_opt_in_boundary_missing'),
      );
      expect(
        validation.reasons,
        contains('route_history_budget_boundary_missing'),
      );
      expect(validation.reasons, contains('map_route_claims_trip_truth'));
      expect(
        validation.reasons,
        contains('storage_authority_boundary_missing'),
      );
      expect(
        validation.reasons,
        contains('summary_contains_sensitive_route_material'),
      );
    },
  );
}

TripRouteHistoryCaptureDecision evaluate({
  TripRouteHistoryAccountTier accountTier = TripRouteHistoryAccountTier.free,
  bool gpsAssistedTrackingEnabled = true,
  bool userOptedIntoMaps = true,
  bool userOptedIntoRouteHistory = true,
  bool mapboxRuntimeAvailable = true,
  double requestedDailyBudgetMb = 1,
  int availableStorageMb = 5000,
  int requestedSampleIntervalSeconds = 15,
}) {
  return TripRouteHistoryCapturePolicy.evaluate(
    accountTier: accountTier,
    gpsAssistedTrackingEnabled: gpsAssistedTrackingEnabled,
    userOptedIntoMaps: userOptedIntoMaps,
    userOptedIntoRouteHistory: userOptedIntoRouteHistory,
    mapboxRuntimeAvailable: mapboxRuntimeAvailable,
    requestedDailyBudgetMb: requestedDailyBudgetMb,
    availableStorageMb: availableStorageMb,
    requestedSampleIntervalSeconds: requestedSampleIntervalSeconds,
  );
}
