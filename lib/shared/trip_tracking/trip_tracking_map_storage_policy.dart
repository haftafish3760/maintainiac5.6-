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
}

int _safeDrivingSeconds(int value) => value.clamp(60, 24 * 60 * 60);

int _safeBytesPerPoint(int value) => value.clamp(32, 512);

double _roundMb(double value) => double.parse(value.toStringAsFixed(3));
