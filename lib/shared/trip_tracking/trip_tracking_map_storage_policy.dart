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
    'mapStorageEnabled': enabled,
    'allowedToPersistRoute': allowedToPersistRoute,
    'reasonCode': reasonCode,
    'sampleIntervalSeconds': sampleIntervalSeconds,
    'dailyBudgetMb': dailyBudgetMb,
    'estimatedSamplesPerDay': estimatedSamplesPerDay,
    'estimatedDailyMb': estimatedDailyMb,
    'exceedsDailyBudget': exceedsDailyBudget,
    'gpsTrackingCanRunWithoutMaps': true,
    'mapsRequireSeparateOptIn': true,
    'routeHistoryRequiresSeparateOptIn': true,
    'userControlsDailyBudget': true,
    'odometerRemainsCanonical': true,
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
    'allowedToPersistPoint': allowedToPersistPoint,
    'reasonCode': reasonCode,
    'persistedPointsToday': persistedPointsToday,
    'maxRoutePointsPerDay': maxRoutePointsPerDay,
    'remainingPointsToday': remainingPointsToday,
    'dailyBudgetMb': dailyBudgetMb,
    'estimatedStoredMbAfterPoint': estimatedStoredMbAfterPoint,
    'gpsTrackingCanContinueWithoutMaps': true,
    'mapStorageFailureStopsGpsTracking': false,
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

  static TripTrackingMapStorageEstimate estimate({
    required TripTrackingSettings settings,
    int drivingSecondsPerDay = defaultDrivingSecondsPerDay,
    int bytesPerPoint = compactBytesPerPoint,
  }) {
    final safeDrivingSeconds = _safeDrivingSeconds(drivingSecondsPerDay);
    final safeBytesPerPoint = _safeBytesPerPoint(bytesPerPoint);
    final sampleInterval = settings.mapRouteHistorySampleIntervalSeconds;
    final samples = (safeDrivingSeconds / sampleInterval).ceil();
    final estimatedMb = _roundMb(samples * safeBytesPerPoint / (1024 * 1024));
    if (!settings.gpsAssistedTrackingEnabled) {
      return TripTrackingMapStorageEstimate(
        enabled: false,
        allowedToPersistRoute: false,
        reasonCode: 'gps_tracking_disabled',
        sampleIntervalSeconds: sampleInterval,
        dailyBudgetMb: settings.mapRouteHistoryDailyBudgetMb,
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
        dailyBudgetMb: settings.mapRouteHistoryDailyBudgetMb,
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
        dailyBudgetMb: settings.mapRouteHistoryDailyBudgetMb,
        estimatedSamplesPerDay: samples,
        estimatedDailyMb: estimatedMb,
      );
    }
    if (settings.mapRouteHistoryDailyBudgetMb <= 0) {
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
      allowedToPersistRoute:
          estimatedMb <= settings.mapRouteHistoryDailyBudgetMb,
      reasonCode: estimatedMb <= settings.mapRouteHistoryDailyBudgetMb
          ? 'map_route_history_within_budget'
          : 'map_route_history_budget_exceeded',
      sampleIntervalSeconds: sampleInterval,
      dailyBudgetMb: settings.mapRouteHistoryDailyBudgetMb,
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

int _safeDrivingSeconds(int value) => value.clamp(60, 24 * 60 * 60);

int _safeBytesPerPoint(int value) => value.clamp(32, 512);

double _roundMb(double value) => double.parse(value.toStringAsFixed(3));

int _safePersistedPoints(int value) => value < 0 ? 0 : value;

int _maxRoutePointsPerDay(double dailyBudgetMb, int bytesPerPoint) {
  if (!dailyBudgetMb.isFinite || dailyBudgetMb <= 0) return 0;
  return (dailyBudgetMb * 1024 * 1024 / bytesPerPoint).floor();
}

int _remainingPoints(int maxPoints, int persistedPoints) =>
    (maxPoints - persistedPoints).clamp(0, maxPoints);

double _storedMb(int points, int bytesPerPoint) =>
    _roundMb(points * bytesPerPoint / (1024 * 1024));
