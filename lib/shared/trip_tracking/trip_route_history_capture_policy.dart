enum TripRouteHistoryPlan { disabled, textOnlyAnchors, compactGpsTrace }

enum TripRouteHistoryReason {
  userNotOptedIn,
  mapsDisabled,
  gpsOnlyFreeTracker,
  storageTooLowForRouteHistory,
  storageCriticallyLowTextOnly,
  dailyBudgetTooSmall,
  compactTraceAllowed,
}

enum TripRouteHistoryAccountTier { free, beta, paid }

class TripRouteHistoryCaptureDecision {
  const TripRouteHistoryCaptureDecision({
    required this.plan,
    required this.reason,
    required this.recommendedSampleIntervalSeconds,
    required this.maximumRetainedPointsPerDay,
    required this.dailyBudgetMb,
    required this.canUseMapbox,
    required this.canCaptureRouteHistory,
  });

  final TripRouteHistoryPlan plan;
  final TripRouteHistoryReason reason;
  final int recommendedSampleIntervalSeconds;
  final int maximumRetainedPointsPerDay;
  final double dailyBudgetMb;
  final bool canUseMapbox;
  final bool canCaptureRouteHistory;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'plan': plan.name,
    'reason': reason.name,
    'recommendedSampleIntervalSeconds': recommendedSampleIntervalSeconds,
    'maximumRetainedPointsPerDay': maximumRetainedPointsPerDay,
    'dailyBudgetBucket': _dailyBudgetBucket(dailyBudgetMb),
    'canUseMapbox': canUseMapbox,
    'canCaptureRouteHistory': canCaptureRouteHistory,
    'gpsAssistedTrackingAvailableWithoutMaps': true,
    'mapsRequiredForTripTracking': false,
    'mapRouteHistoryRequiresSeparateOptIn': true,
    'freeGpsTripTrackerRemainsFree': true,
    'routeHistoryCanBeDisabledWithoutStoppingTrip': true,
    'textTripLogStillWritten': true,
    'textTripLogCanContinueAtLowStorage': true,
    'minimumDeviceStorageMbForRouteHistory': 500,
    'criticalStorageTextOnlyFloorMb': 25,
    'storesOnlyBoundedRoutePoints': true,
    'oneToThreeSecondRawPingStorageAllowed': false,
    'rawHighFrequencyPingsRetained': false,
    'mapboxCanReplaceTripLog': false,
    'mapboxCanReplaceOdometer': false,
    'routeHistoryCanConfirmMileage': false,
    'odometerRemainsOfficialMileageTruth': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'rawCoordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripRouteHistoryCapturePolicy {
  const TripRouteHistoryCapturePolicy._();

  static TripRouteHistoryCaptureDecision evaluate({
    required TripRouteHistoryAccountTier accountTier,
    required bool gpsAssistedTrackingEnabled,
    required bool userOptedIntoMaps,
    required bool userOptedIntoRouteHistory,
    required bool mapboxRuntimeAvailable,
    required double requestedDailyBudgetMb,
    required int availableStorageMb,
    required int requestedSampleIntervalSeconds,
  }) {
    final safeBudget = _safeBudget(requestedDailyBudgetMb);
    if (!gpsAssistedTrackingEnabled) {
      return _disabled(TripRouteHistoryReason.gpsOnlyFreeTracker, safeBudget);
    }
    if (!userOptedIntoMaps || !mapboxRuntimeAvailable) {
      return _textOnly(TripRouteHistoryReason.mapsDisabled, safeBudget);
    }
    if (!userOptedIntoRouteHistory) {
      return _textOnly(TripRouteHistoryReason.userNotOptedIn, safeBudget);
    }
    if (availableStorageMb < 25) {
      return _textOnly(
        TripRouteHistoryReason.storageCriticallyLowTextOnly,
        safeBudget,
      );
    }
    if (availableStorageMb < 500) {
      return _textOnly(
        TripRouteHistoryReason.storageTooLowForRouteHistory,
        safeBudget,
      );
    }
    final tierFloor = switch (accountTier) {
      TripRouteHistoryAccountTier.free => 0.25,
      TripRouteHistoryAccountTier.beta => 1.0,
      TripRouteHistoryAccountTier.paid => 2.0,
    };
    if (safeBudget < tierFloor) {
      return _textOnly(TripRouteHistoryReason.dailyBudgetTooSmall, safeBudget);
    }
    final interval = _sampleInterval(
      accountTier: accountTier,
      requestedSeconds: requestedSampleIntervalSeconds,
    );
    return TripRouteHistoryCaptureDecision(
      plan: TripRouteHistoryPlan.compactGpsTrace,
      reason: TripRouteHistoryReason.compactTraceAllowed,
      recommendedSampleIntervalSeconds: interval,
      maximumRetainedPointsPerDay: _maxPointsPerDay(
        interval,
        safeBudget,
        accountTier,
      ),
      dailyBudgetMb: safeBudget,
      canUseMapbox: true,
      canCaptureRouteHistory: true,
    );
  }
}

TripRouteHistoryCaptureDecision _disabled(
  TripRouteHistoryReason reason,
  double dailyBudgetMb,
) {
  return TripRouteHistoryCaptureDecision(
    plan: TripRouteHistoryPlan.disabled,
    reason: reason,
    recommendedSampleIntervalSeconds: 0,
    maximumRetainedPointsPerDay: 0,
    dailyBudgetMb: dailyBudgetMb,
    canUseMapbox: false,
    canCaptureRouteHistory: false,
  );
}

TripRouteHistoryCaptureDecision _textOnly(
  TripRouteHistoryReason reason,
  double dailyBudgetMb,
) {
  return TripRouteHistoryCaptureDecision(
    plan: TripRouteHistoryPlan.textOnlyAnchors,
    reason: reason,
    recommendedSampleIntervalSeconds: 60,
    maximumRetainedPointsPerDay: 0,
    dailyBudgetMb: dailyBudgetMb,
    canUseMapbox: false,
    canCaptureRouteHistory: false,
  );
}

double _safeBudget(double value) {
  if (!value.isFinite || value < 0) return 0;
  if (value > 25) return 25;
  return value;
}

int _sampleInterval({
  required TripRouteHistoryAccountTier accountTier,
  required int requestedSeconds,
}) {
  final minimum = switch (accountTier) {
    TripRouteHistoryAccountTier.free => 15,
    TripRouteHistoryAccountTier.beta => 10,
    TripRouteHistoryAccountTier.paid => 5,
  };
  final maximum = switch (accountTier) {
    TripRouteHistoryAccountTier.free => 60,
    TripRouteHistoryAccountTier.beta => 45,
    TripRouteHistoryAccountTier.paid => 30,
  };
  return requestedSeconds.clamp(minimum, maximum).toInt();
}

int _maxPointsPerDay(
  int sampleIntervalSeconds,
  double dailyBudgetMb,
  TripRouteHistoryAccountTier accountTier,
) {
  final pointCapByTime = (86400 / sampleIntervalSeconds).floor();
  final pointCapByBudget = (dailyBudgetMb * 1024 * 1024 / 96).floor();
  final tierCap = switch (accountTier) {
    TripRouteHistoryAccountTier.free => 2500,
    TripRouteHistoryAccountTier.beta => 6000,
    TripRouteHistoryAccountTier.paid => 12000,
  };
  return [pointCapByTime, pointCapByBudget, tierCap]
      .reduce((value, element) => value < element ? value : element)
      .clamp(0, tierCap)
      .toInt();
}

String _dailyBudgetBucket(double value) {
  if (value <= 0) return 'none';
  if (value < 0.5) return 'under_half_mb';
  if (value < 2) return 'half_to_two_mb';
  if (value < 10) return 'two_to_ten_mb';
  return 'ten_to_twenty_five_mb';
}
