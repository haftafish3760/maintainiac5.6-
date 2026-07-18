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
    'mapsOptInDoesNotEnableRouteHistory': true,
    'routeHistoryRequiresLocalSettings': true,
    'routeHistoryRequiresOwnershipValidation': true,
    'authenticationAloneAuthorizesRouteHistory': false,
    'freeGpsTripTrackerRemainsFree': true,
    'freeTierRouteHistoryBudgetCapped': true,
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
    'mapboxCanCreateOfficialStop': false,
    'mapboxCanReorderOfficialStops': false,
    'routeHistoryCanConfirmMileage': false,
    'routeHistoryCanCreateCalibration': false,
    'routeHistoryCanApplyCalibration': false,
    'routeHistoryCanBecomeCalibrationProof': false,
    'routeHistoryCannotDeleteTextTripLog': true,
    'routeHistoryCannotUploadRawPingsToFirestore': true,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
    'physicalOdometerRequiredForOfficialMileage': true,
    'confirmedOdometerOverridesExternalMileage': true,
    'externalMileageCannotBecomeGlobalTruth': true,
    'gpsDistanceCanOnlyAdviseMileageReview': true,
    'mapMatchingCanOnlyAdviseMileageReview': true,
    'optimizationCannotChangeOfficialMileage': true,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'durableStorageRemainsSharedAcrossModules': true,
    'routeHistoryCleanupRequiresExplicitUserAction': true,
    'mapboxFailureStopsTextTripLog': false,
    'firestoreCanEnableMapsWithoutUserOptIn': false,
    'firestoreCanRestoreDeletedRouteHistory': false,
    'remoteConfigCanIncreaseSamplingCadence': false,
    'remoteConfigCanExceedDailyBudget': false,
    'backgroundTrackingRequiresPlatformPermission': true,
    'userCanDisableMapRouteHistoryAnytime': true,
    'rawCoordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripRouteHistorySummaryValidation {
  const TripRouteHistorySummaryValidation._({
    required this.isRenderable,
    required this.plan,
    required this.reasons,
  });

  factory TripRouteHistorySummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final plan = _safePlan(summary['plan']);
    final reason = _safeReason(summary['reason']);
    if (summary['schemaVersion'] != 1) reasons.add('unsupported_schema');
    if (plan == null) reasons.add('invalid_route_history_plan');
    if (reason == null) reasons.add('invalid_route_history_reason');
    if (!_safeInterval(summary['recommendedSampleIntervalSeconds']) ||
        !_safePointCap(summary['maximumRetainedPointsPerDay'])) {
      reasons.add('invalid_route_history_cadence');
    }
    if (summary['canCaptureRouteHistory'] == true &&
        plan != TripRouteHistoryPlan.compactGpsTrace) {
      reasons.add('capture_enabled_for_non_trace_plan');
    }
    if (summary['gpsAssistedTrackingAvailableWithoutMaps'] != true ||
        summary['mapsRequiredForTripTracking'] != false ||
        summary['freeGpsTripTrackerRemainsFree'] != true ||
        summary['textTripLogStillWritten'] != true ||
        summary['mapboxFailureStopsTextTripLog'] != false) {
      reasons.add('gps_text_log_boundary_missing');
    }
    if (summary['mapRouteHistoryRequiresSeparateOptIn'] != true ||
        summary['mapsOptInDoesNotEnableRouteHistory'] != true ||
        summary['routeHistoryRequiresLocalSettings'] != true ||
        summary['routeHistoryRequiresOwnershipValidation'] != true ||
        summary['authenticationAloneAuthorizesRouteHistory'] != false ||
        summary['userCanDisableMapRouteHistoryAnytime'] != true ||
        summary['firestoreCanEnableMapsWithoutUserOptIn'] != false) {
      reasons.add('route_history_opt_in_boundary_missing');
    }
    if (summary['storesOnlyBoundedRoutePoints'] != true ||
        summary['oneToThreeSecondRawPingStorageAllowed'] != false ||
        summary['rawHighFrequencyPingsRetained'] != false ||
        summary['freeTierRouteHistoryBudgetCapped'] != true ||
        summary['remoteConfigCanIncreaseSamplingCadence'] != false ||
        summary['remoteConfigCanExceedDailyBudget'] != false) {
      reasons.add('route_history_budget_boundary_missing');
    }
    if (summary['mapboxCanReplaceTripLog'] != false ||
        summary['mapboxCanReplaceOdometer'] != false ||
        summary['mapboxCanCreateOfficialStop'] != false ||
        summary['mapboxCanReorderOfficialStops'] != false ||
        summary['routeHistoryCanConfirmMileage'] != false ||
        summary['routeHistoryCanCreateCalibration'] != false ||
        summary['routeHistoryCanApplyCalibration'] != false ||
        summary['routeHistoryCanBecomeCalibrationProof'] != false ||
        summary['routeHistoryCannotDeleteTextTripLog'] != true ||
        summary['routeHistoryCannotUploadRawPingsToFirestore'] != true ||
        summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['odometerIsGlobalTruth'] != true ||
        summary['physicalOdometerRequiredForOfficialMileage'] != true ||
        summary['confirmedOdometerOverridesExternalMileage'] != true ||
        summary['externalMileageCannotBecomeGlobalTruth'] != true ||
        summary['gpsDistanceCanOnlyAdviseMileageReview'] != true ||
        summary['mapMatchingCanOnlyAdviseMileageReview'] != true ||
        summary['optimizationCannotChangeOfficialMileage'] != true ||
        summary['calibrationRequiresTrustedGpsWindow'] != true ||
        summary['poorGpsDaysExcludedFromCalibration'] != true) {
      reasons.add('map_route_claims_trip_truth');
    }
    if (summary['hiveRemainsOperationalSourceOfTruth'] != true ||
        summary['firestoreMirrorOnly'] != true ||
        summary['durableStorageRemainsSharedAcrossModules'] != true ||
        summary['firestoreCanRestoreDeletedRouteHistory'] != false ||
        summary['routeHistoryCleanupRequiresExplicitUserAction'] != true) {
      reasons.add('storage_authority_boundary_missing');
    }
    if (summary['rawCoordinatesIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_route_material');
    }
    return TripRouteHistorySummaryValidation._(
      isRenderable: reasons.isEmpty,
      plan: reasons.isEmpty ? plan : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final TripRouteHistoryPlan? plan;
  final List<String> reasons;
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

bool _safeInterval(Object? value) {
  if (value is! int) return false;
  return value == 0 || (value >= 5 && value <= 60);
}

bool _safePointCap(Object? value) {
  if (value is! int) return false;
  return value >= 0 && value <= 12000;
}

TripRouteHistoryPlan? _safePlan(Object? value) {
  if (value is! String) return null;
  for (final plan in TripRouteHistoryPlan.values) {
    if (plan.name == value) return plan;
  }
  return null;
}

TripRouteHistoryReason? _safeReason(Object? value) {
  if (value is! String) return null;
  for (final reason in TripRouteHistoryReason.values) {
    if (reason.name == value) return reason;
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}').hasMatch(clean);
}
