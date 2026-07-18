import 'trip_tracking_settings_store.dart';

class TripTrackingMapStorageEstimate {
  const TripTrackingMapStorageEstimate({
    required this.enabled,
    required this.allowedToPersistRoute,
    required this.reasonCode,
    required this.sampleIntervalSeconds,
    required this.dailyBudgetMb,
    required this.estimatedSamplesPerDay,
    required this.estimatedDailyMb,
  });

  final bool enabled;
  final bool allowedToPersistRoute;
  final String reasonCode;
  final int sampleIntervalSeconds;
  final double dailyBudgetMb;
  final int estimatedSamplesPerDay;
  final double estimatedDailyMb;

  bool get exceedsDailyBudget =>
      enabled && dailyBudgetMb > 0 && estimatedDailyMb > dailyBudgetMb;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'mapStorageEnabled':
        enabled && _safeMapStorageReason(reasonCode) != 'maps_not_enabled',
    'allowedToPersistRoute': _safeAllowedToPersistRoute(
      allowedToPersistRoute: allowedToPersistRoute,
      reasonCode: reasonCode,
      estimatedDailyMb: estimatedDailyMb,
      dailyBudgetMb: dailyBudgetMb,
    ),
    'reasonCode': _safeMapStorageReason(reasonCode),
    'sampleIntervalSeconds': _safeSampleIntervalSeconds(sampleIntervalSeconds),
    'dailyBudgetMb': _safeDailyBudgetMb(dailyBudgetMb),
    'estimatedSamplesPerDay': _safePersistedPoints(estimatedSamplesPerDay),
    'estimatedDailyMb': _safeMb(estimatedDailyMb),
    'exceedsDailyBudget': exceedsDailyBudget,
    'gpsTrackingCanRunWithoutMaps': true,
    'mapsRequireSeparateOptIn': true,
    'routeHistoryRequiresSeparateOptIn': true,
    'mapsOptInDoesNotEnableRouteHistory': true,
    'routeHistoryRequiresLocalSettings': true,
    'userControlsDailyBudget': true,
    'freePlanMaxDailyBudgetMb': 2,
    'freePlanBudgetCannotBeRaisedRemotely': true,
    'compactRoutePointBytes': TripTrackingMapStoragePolicy.compactBytesPerPoint,
    'oneToThreeSecondRawPingStorageDiscouraged': true,
    'routeStorageAdvisoryOnly': true,
    'mapPreviewCanRunWithoutRouteHistory': true,
    'routeStorageCanPauseWithoutStoppingGps': true,
    'storageBudgetExhaustionCanOnlyPauseRouteHistory': true,
    'userCanDisableRouteHistoryWithoutDisablingGps': true,
    'mapboxResponseCanBypassBudget': false,
    'mapboxFailureCanCorruptTripLog': false,
    'mapboxTimeoutCanStopGpsTracking': false,
    'mapboxRouteCanReplaceGpsDistance': false,
    'mapboxCanOverrideRouteBudget': false,
    'remoteRouteSummaryCanOverrideLocalTrip': false,
    'routeStorageTrustedAfterValidationOnly': true,
    'malformedRouteStoragePayloadFailsSafe': true,
    'canSilentlyDeleteRouteHistory': false,
    'routeStorageCannotDeleteTextTripLog': true,
    'routeStorageCannotUploadRawPingsToFirestore': true,
    'localTripLogProtected': true,
    'purgeRequiresConfirmedBackupOrUserAction': true,
    'odometerIsGlobalTruth': true,
    'odometerRemainsCanonical': true,
    'routeStorageCanCreateCalibration': false,
    'routeStorageCanApplyCalibration': false,
    'routePointCanCreateCalibration': false,
    'routePointCanApplyCalibration': false,
    'routeStorageCanBecomeCalibrationProof': false,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'rawCoordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'mapboxGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripTrackingMapRoutePointDecision {
  const TripTrackingMapRoutePointDecision({
    required this.allowedToPersistPoint,
    required this.reasonCode,
    required this.persistedPointsToday,
    required this.maxRoutePointsPerDay,
    required this.remainingPointsToday,
    required this.dailyBudgetMb,
    required this.estimatedStoredMbAfterPoint,
  });

  final bool allowedToPersistPoint;
  final String reasonCode;
  final int persistedPointsToday;
  final int maxRoutePointsPerDay;
  final int remainingPointsToday;
  final double dailyBudgetMb;
  final double estimatedStoredMbAfterPoint;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'allowedToPersistPoint': _safeAllowedToPersistPoint(
      allowedToPersistPoint: allowedToPersistPoint,
      reasonCode: reasonCode,
      persistedPointsToday: persistedPointsToday,
      maxRoutePointsPerDay: maxRoutePointsPerDay,
    ),
    'reasonCode': _safeMapStorageReason(reasonCode),
    'persistedPointsToday': _safePersistedPoints(persistedPointsToday),
    'maxRoutePointsPerDay': _safePersistedPoints(maxRoutePointsPerDay),
    'remainingPointsToday': _safePersistedPoints(remainingPointsToday),
    'dailyBudgetMb': _safeDailyBudgetMb(dailyBudgetMb),
    'estimatedStoredMbAfterPoint': _safeMb(estimatedStoredMbAfterPoint),
    'gpsTrackingCanContinueWithoutMaps': true,
    'mapStorageFailureStopsGpsTracking': false,
    'freePlanMaxDailyBudgetMb': 2,
    'freePlanBudgetCannotBeRaisedRemotely': true,
    'compactRoutePointBytes': TripTrackingMapStoragePolicy.compactBytesPerPoint,
    'oneToThreeSecondRawPingStorageDiscouraged': true,
    'routeStorageAdvisoryOnly': true,
    'mapPreviewCanRunWithoutRouteHistory': true,
    'routeStorageCanPauseWithoutStoppingGps': true,
    'storageBudgetExhaustionCanOnlyPauseRouteHistory': true,
    'userCanDisableRouteHistoryWithoutDisablingGps': true,
    'mapboxResponseCanBypassBudget': false,
    'mapboxFailureCanCorruptTripLog': false,
    'mapboxTimeoutCanStopGpsTracking': false,
    'mapboxRouteCanReplaceGpsDistance': false,
    'mapboxCanOverrideRouteBudget': false,
    'remoteRouteSummaryCanOverrideLocalTrip': false,
    'routeStorageTrustedAfterValidationOnly': true,
    'malformedRouteStoragePayloadFailsSafe': true,
    'canSilentlyDeleteRouteHistory': false,
    'routeStorageCannotDeleteTextTripLog': true,
    'routeStorageCannotUploadRawPingsToFirestore': true,
    'localTripLogProtected': true,
    'purgeRequiresConfirmedBackupOrUserAction': true,
    'odometerIsGlobalTruth': true,
    'odometerRemainsCanonical': true,
    'routeStorageCanCreateCalibration': false,
    'routeStorageCanApplyCalibration': false,
    'routePointCanCreateCalibration': false,
    'routePointCanApplyCalibration': false,
    'routeStorageCanBecomeCalibrationProof': false,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'rawCoordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'mapboxGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripTrackingMapStoragePolicy {
  const TripTrackingMapStoragePolicy._();

  static const defaultDrivingSecondsPerDay = 8 * 60 * 60;
  static const compactBytesPerPoint = 96;
  static const maxSafeRoutePointsPerDay = 1000000;

  static TripTrackingMapStorageEstimate estimate({
    required TripTrackingSettings settings,
    int drivingSecondsPerDay = defaultDrivingSecondsPerDay,
    int bytesPerPoint = compactBytesPerPoint,
  }) {
    final safeDrivingSeconds = _safeDrivingSeconds(drivingSecondsPerDay);
    final safeBytesPerPoint = _safeBytesPerPoint(bytesPerPoint);
    final sampleInterval = _safeSampleIntervalSeconds(
      settings.mapRouteHistorySampleIntervalSeconds,
    );
    final dailyBudgetMb = _safeDailyBudgetMb(
      settings.mapRouteHistoryDailyBudgetMb,
    );
    final samples = (safeDrivingSeconds / sampleInterval).ceil();
    final estimatedMb = _roundMb(samples * safeBytesPerPoint / (1024 * 1024));
    if (!settings.gpsAssistedTrackingEnabled) {
      return TripTrackingMapStorageEstimate(
        enabled: false,
        allowedToPersistRoute: false,
        reasonCode: 'gps_tracking_disabled',
        sampleIntervalSeconds: sampleInterval,
        dailyBudgetMb: dailyBudgetMb,
        estimatedSamplesPerDay: samples,
        estimatedDailyMb: estimatedMb,
      );
    }
    if (!settings.mapPreviewEnabled) {
      return TripTrackingMapStorageEstimate(
        enabled: false,
        allowedToPersistRoute: false,
        reasonCode: 'maps_not_enabled',
        sampleIntervalSeconds: sampleInterval,
        dailyBudgetMb: dailyBudgetMb,
        estimatedSamplesPerDay: samples,
        estimatedDailyMb: estimatedMb,
      );
    }
    if (!settings.mapRouteHistorySavingEnabled) {
      return TripTrackingMapStorageEstimate(
        enabled: false,
        allowedToPersistRoute: false,
        reasonCode: 'map_route_history_not_enabled',
        sampleIntervalSeconds: sampleInterval,
        dailyBudgetMb: dailyBudgetMb,
        estimatedSamplesPerDay: samples,
        estimatedDailyMb: estimatedMb,
      );
    }
    if (dailyBudgetMb <= 0) {
      return TripTrackingMapStorageEstimate(
        enabled: true,
        allowedToPersistRoute: false,
        reasonCode: 'map_route_history_budget_missing',
        sampleIntervalSeconds: sampleInterval,
        dailyBudgetMb: 0,
        estimatedSamplesPerDay: samples,
        estimatedDailyMb: estimatedMb,
      );
    }
    return TripTrackingMapStorageEstimate(
      enabled: true,
      allowedToPersistRoute: estimatedMb <= dailyBudgetMb,
      reasonCode: estimatedMb <= dailyBudgetMb
          ? 'map_route_history_within_budget'
          : 'map_route_history_budget_exceeded',
      sampleIntervalSeconds: sampleInterval,
      dailyBudgetMb: dailyBudgetMb,
      estimatedSamplesPerDay: samples,
      estimatedDailyMb: estimatedMb,
    );
  }

  static TripTrackingMapRoutePointDecision canPersistNextRoutePoint({
    required TripTrackingSettings settings,
    required int persistedPointsToday,
    int bytesPerPoint = compactBytesPerPoint,
  }) {
    final safeBytesPerPoint = _safeBytesPerPoint(bytesPerPoint);
    final safePersistedPoints = _safePersistedPoints(persistedPointsToday);
    final storageEstimate = estimate(
      settings: settings,
      bytesPerPoint: safeBytesPerPoint,
    );
    final maxPoints = _maxRoutePointsPerDay(
      storageEstimate.dailyBudgetMb,
      safeBytesPerPoint,
    );
    if (!storageEstimate.allowedToPersistRoute) {
      return TripTrackingMapRoutePointDecision(
        allowedToPersistPoint: false,
        reasonCode: storageEstimate.reasonCode,
        persistedPointsToday: safePersistedPoints,
        maxRoutePointsPerDay: maxPoints,
        remainingPointsToday: _remainingPoints(maxPoints, safePersistedPoints),
        dailyBudgetMb: storageEstimate.dailyBudgetMb,
        estimatedStoredMbAfterPoint: _storedMb(
          safePersistedPoints,
          safeBytesPerPoint,
        ),
      );
    }
    if (safePersistedPoints >= maxPoints) {
      return TripTrackingMapRoutePointDecision(
        allowedToPersistPoint: false,
        reasonCode: 'map_route_history_live_budget_exhausted',
        persistedPointsToday: safePersistedPoints,
        maxRoutePointsPerDay: maxPoints,
        remainingPointsToday: 0,
        dailyBudgetMb: storageEstimate.dailyBudgetMb,
        estimatedStoredMbAfterPoint: _storedMb(
          safePersistedPoints,
          safeBytesPerPoint,
        ),
      );
    }
    return TripTrackingMapRoutePointDecision(
      allowedToPersistPoint: true,
      reasonCode: 'map_route_history_point_within_live_budget',
      persistedPointsToday: safePersistedPoints,
      maxRoutePointsPerDay: maxPoints,
      remainingPointsToday: _remainingPoints(
        maxPoints,
        safePersistedPoints + 1,
      ),
      dailyBudgetMb: storageEstimate.dailyBudgetMb,
      estimatedStoredMbAfterPoint: _storedMb(
        safePersistedPoints + 1,
        safeBytesPerPoint,
      ),
    );
  }
}

class TripTrackingMapStorageSummaryValidation {
  const TripTrackingMapStorageSummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripTrackingMapStorageSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    final reasonCode = _safeMapStorageReason(
      summary['reasonCode']?.toString() ?? '',
    );
    if (summary['reasonCode'] != reasonCode) {
      reasons.add('invalid_map_storage_reason');
    }
    for (final key in const [
      'gpsTrackingCanRunWithoutMaps',
      'gpsTrackingCanContinueWithoutMaps',
      'mapsRequireSeparateOptIn',
      'routeHistoryRequiresSeparateOptIn',
      'mapsOptInDoesNotEnableRouteHistory',
      'routeHistoryRequiresLocalSettings',
      'userControlsDailyBudget',
      'freePlanBudgetCannotBeRaisedRemotely',
      'oneToThreeSecondRawPingStorageDiscouraged',
      'routeStorageAdvisoryOnly',
      'mapPreviewCanRunWithoutRouteHistory',
      'routeStorageCanPauseWithoutStoppingGps',
      'storageBudgetExhaustionCanOnlyPauseRouteHistory',
      'userCanDisableRouteHistoryWithoutDisablingGps',
      'mapboxResponseCanBypassBudget',
      'mapboxFailureCanCorruptTripLog',
      'mapboxTimeoutCanStopGpsTracking',
      'mapboxRouteCanReplaceGpsDistance',
      'mapboxCanOverrideRouteBudget',
      'remoteRouteSummaryCanOverrideLocalTrip',
      'routeStorageTrustedAfterValidationOnly',
      'malformedRouteStoragePayloadFailsSafe',
      'canSilentlyDeleteRouteHistory',
      'routeStorageCannotDeleteTextTripLog',
      'routeStorageCannotUploadRawPingsToFirestore',
      'localTripLogProtected',
      'purgeRequiresConfirmedBackupOrUserAction',
      'odometerIsGlobalTruth',
      'odometerRemainsCanonical',
      'routeStorageCanCreateCalibration',
      'routeStorageCanApplyCalibration',
      'routeStorageCanBecomeCalibrationProof',
      'calibrationRequiresTrustedGpsWindow',
      'poorGpsDaysExcludedFromCalibration',
      'rawCoordinatesIncluded',
      'routeGeometryIncluded',
      'mapboxGeometryIncluded',
      'tokensIncluded',
    ]) {
      if (summary.containsKey(key) && summary[key] is! bool) {
        reasons.add('${key}_not_bool');
      }
    }
    if ((summary['gpsTrackingCanRunWithoutMaps'] == false) ||
        (summary['gpsTrackingCanContinueWithoutMaps'] == false) ||
        summary['routeStorageAdvisoryOnly'] != true ||
        summary['routeStorageCanPauseWithoutStoppingGps'] != true ||
        summary['storageBudgetExhaustionCanOnlyPauseRouteHistory'] != true ||
        summary['userCanDisableRouteHistoryWithoutDisablingGps'] != true ||
        summary['mapsOptInDoesNotEnableRouteHistory'] == false ||
        summary['routeHistoryRequiresLocalSettings'] == false ||
        summary['localTripLogProtected'] != true) {
      reasons.add('map_storage_blocks_gps_trip_log');
    }
    if (summary['mapboxResponseCanBypassBudget'] != false ||
        summary['mapboxFailureCanCorruptTripLog'] != false ||
        summary['mapboxTimeoutCanStopGpsTracking'] != false ||
        summary['mapboxRouteCanReplaceGpsDistance'] != false ||
        summary['mapboxCanOverrideRouteBudget'] != false ||
        summary['remoteRouteSummaryCanOverrideLocalTrip'] != false) {
      reasons.add('mapbox_or_remote_can_override_trip');
    }
    if (summary['canSilentlyDeleteRouteHistory'] != false ||
        summary['routeStorageCannotDeleteTextTripLog'] != true ||
        summary['routeStorageCannotUploadRawPingsToFirestore'] != true ||
        summary['purgeRequiresConfirmedBackupOrUserAction'] != true) {
      reasons.add('route_history_can_be_silently_deleted');
    }
    if (summary['freePlanBudgetCannotBeRaisedRemotely'] == false) {
      reasons.add('free_plan_budget_boundary_missing');
    }
    if (summary['odometerIsGlobalTruth'] != true ||
        summary['odometerRemainsCanonical'] != true ||
        summary['routeStorageCanCreateCalibration'] != false ||
        summary['routeStorageCanApplyCalibration'] != false ||
        summary['routeStorageCanBecomeCalibrationProof'] != false ||
        summary['calibrationRequiresTrustedGpsWindow'] != true ||
        summary['poorGpsDaysExcludedFromCalibration'] != true ||
        summary['rawCoordinatesIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['mapboxGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_map_material');
    }

    return TripTrackingMapStorageSummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
}

int _safeDrivingSeconds(int value) => value.clamp(60, 24 * 60 * 60);

int _safeBytesPerPoint(int value) => value.clamp(32, 512);

int _safeSampleIntervalSeconds(int value) => value.clamp(15, 300);

double _safeDailyBudgetMb(double value) {
  if (!value.isFinite || value <= 0) return 0;
  return value > 2 ? 2 : _roundMb(value);
}

double _roundMb(double value) => double.parse(value.toStringAsFixed(3));

double _safeMb(double value) {
  if (!value.isFinite || value < 0) return 0;
  return _roundMb(value > 2 ? 2 : value);
}

int _safePersistedPoints(int value) {
  if (value < 0) return 0;
  if (value > TripTrackingMapStoragePolicy.maxSafeRoutePointsPerDay) {
    return TripTrackingMapStoragePolicy.maxSafeRoutePointsPerDay;
  }
  return value;
}

int _maxRoutePointsPerDay(double dailyBudgetMb, int bytesPerPoint) {
  if (!dailyBudgetMb.isFinite || dailyBudgetMb <= 0) return 0;
  return (dailyBudgetMb * 1024 * 1024 / bytesPerPoint).floor();
}

int _remainingPoints(int maxPoints, int persistedPoints) =>
    (maxPoints - persistedPoints).clamp(0, maxPoints);

double _storedMb(int points, int bytesPerPoint) =>
    _roundMb(points * bytesPerPoint / (1024 * 1024));

bool _safeAllowedToPersistRoute({
  required bool allowedToPersistRoute,
  required String reasonCode,
  required double estimatedDailyMb,
  required double dailyBudgetMb,
}) {
  if (!allowedToPersistRoute) return false;
  if (_safeMapStorageReason(reasonCode) != 'map_route_history_within_budget') {
    return false;
  }
  final safeDailyBudget = _safeDailyBudgetMb(dailyBudgetMb);
  final safeEstimate = _safeMb(estimatedDailyMb);
  return safeDailyBudget > 0 && safeEstimate <= safeDailyBudget;
}

bool _safeAllowedToPersistPoint({
  required bool allowedToPersistPoint,
  required String reasonCode,
  required int persistedPointsToday,
  required int maxRoutePointsPerDay,
}) {
  if (!allowedToPersistPoint) return false;
  if (_safeMapStorageReason(reasonCode) !=
      'map_route_history_point_within_live_budget') {
    return false;
  }
  final maxPoints = _safePersistedPoints(maxRoutePointsPerDay);
  if (maxPoints <= 0) return false;
  return _safePersistedPoints(persistedPointsToday) < maxPoints;
}

String _safeMapStorageReason(String value) {
  return switch (value.trim()) {
    'gps_tracking_disabled' => 'gps_tracking_disabled',
    'maps_not_enabled' => 'maps_not_enabled',
    'map_route_history_not_enabled' => 'map_route_history_not_enabled',
    'map_route_history_budget_missing' => 'map_route_history_budget_missing',
    'map_route_history_within_budget' => 'map_route_history_within_budget',
    'map_route_history_budget_exceeded' => 'map_route_history_budget_exceeded',
    'map_route_history_live_budget_exhausted' =>
      'map_route_history_live_budget_exhausted',
    'map_route_history_point_within_live_budget' =>
      'map_route_history_point_within_live_budget',
    _ => 'maps_not_enabled',
  };
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
