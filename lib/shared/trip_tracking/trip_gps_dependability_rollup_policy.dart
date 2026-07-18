import 'trip_gps_dependability_policy.dart';
import 'trip_tracking_models.dart';

enum TripGpsDependabilityRollupStatus {
  noWindows,
  reliable,
  reviewOnly,
  excludedFromCalibration,
  unsafe,
}

class TripGpsDependabilityRollupDecision {
  const TripGpsDependabilityRollupDecision({
    required this.status,
    required this.reasonCode,
    required this.windowCount,
    required this.readyWindowCount,
    required this.reviewOnlyWindowCount,
    required this.pausedWindowCount,
    required this.unsafeWindowCount,
    required this.canUseForLiveAssist,
    required this.canUseForCalibrationEvidence,
    required this.requiresUserReview,
  });

  final TripGpsDependabilityRollupStatus status;
  final String reasonCode;
  final int windowCount;
  final int readyWindowCount;
  final int reviewOnlyWindowCount;
  final int pausedWindowCount;
  final int unsafeWindowCount;
  final bool canUseForLiveAssist;
  final bool canUseForCalibrationEvidence;
  final bool requiresUserReview;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'windowCount': _safeCount(windowCount),
    'readyWindowCount': _safeCount(readyWindowCount),
    'reviewOnlyWindowCount': _safeCount(reviewOnlyWindowCount),
    'pausedWindowCount': _safeCount(pausedWindowCount),
    'unsafeWindowCount': _safeCount(unsafeWindowCount),
    'canUseForLiveAssist': canUseForLiveAssist,
    'canUseForCalibrationEvidence': canUseForCalibrationEvidence,
    'requiresUserReview': requiresUserReview,
    'oneGoodWindowCannotClearBadDay': true,
    'poorWindowExcludesCalibrationDay': true,
    'interruptedWindowExcludesCalibrationDay': true,
    'unsafeWindowExcludesCalibrationDay': true,
    'calibrationRequiresSustainedDailyGpsQuality': true,
    'calibrationRequiresReviewedOdometerTruth': true,
    'gpsRollupCanReplaceOdometer': false,
    'gpsRollupCanConfirmOfficialMileage': false,
    'gpsRollupCanCreateOfficialStop': false,
    'mapboxCanOverrideGpsRollup': false,
    'firestoreCanOverrideGpsRollup': false,
    'cloudFunctionCanOverrideGpsRollup': false,
    'hiveRemainsOperationalSourceOfTruth': true,
    'odometerIsGlobalTruth': true,
    'rawSamplesIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripGpsDependabilityRollupPolicy {
  const TripGpsDependabilityRollupPolicy._();

  static TripGpsDependabilityRollupDecision evaluate({
    required Iterable<TripGpsDependabilityDecision> windows,
    TripTrackingProfile profile = TripTrackingProfile.roadVehicle,
    int? minimumReadyWindowsForCalibration,
    double? minimumReadyRateForCalibration,
  }) {
    final list = windows.toList(growable: false);
    final windowCount = list.length;
    final ready = list
        .where(
          (window) =>
              window.status == TripGpsDependabilityStatus.readyForAssist,
        )
        .length;
    final reviewOnly = list
        .where(
          (window) => window.status == TripGpsDependabilityStatus.reviewOnly,
        )
        .length;
    final paused = list
        .where(
          (window) =>
              window.status == TripGpsDependabilityStatus.projectionPaused,
        )
        .length;
    final unsafe = list
        .where(
          (window) => window.status == TripGpsDependabilityStatus.unsafeBlocked,
        )
        .length;
    final profileMinimum = _minimumReadyWindowsFor(profile);
    final profileRate = _minimumReadyRateFor(profile);
    final requestedMinimumWindows = minimumReadyWindowsForCalibration;
    final safeMinimumWindows =
        requestedMinimumWindows == null || requestedMinimumWindows <= 0
        ? profileMinimum
        : requestedMinimumWindows;
    final requestedMinimumRate = minimumReadyRateForCalibration;
    final safeMinimumRate =
        requestedMinimumRate != null &&
            requestedMinimumRate.isFinite &&
            requestedMinimumRate > 0 &&
            requestedMinimumRate <= 1
        ? requestedMinimumRate
        : profileRate;

    if (windowCount == 0) {
      return _decision(
        status: TripGpsDependabilityRollupStatus.noWindows,
        reasonCode: 'gps_rollup_waiting_for_windows',
        windowCount: 0,
        readyWindowCount: 0,
        reviewOnlyWindowCount: 0,
        pausedWindowCount: 0,
        unsafeWindowCount: 0,
        canUseForLiveAssist: false,
        canUseForCalibrationEvidence: false,
        requiresUserReview: false,
      );
    }
    if (unsafe > 0) {
      return _decision(
        status: TripGpsDependabilityRollupStatus.unsafe,
        reasonCode: 'gps_rollup_unsafe_window_present',
        windowCount: windowCount,
        readyWindowCount: ready,
        reviewOnlyWindowCount: reviewOnly,
        pausedWindowCount: paused,
        unsafeWindowCount: unsafe,
        canUseForLiveAssist: false,
        canUseForCalibrationEvidence: false,
        requiresUserReview: true,
      );
    }
    if (paused > 0) {
      return _decision(
        status: TripGpsDependabilityRollupStatus.excludedFromCalibration,
        reasonCode: 'gps_rollup_projection_paused_window_present',
        windowCount: windowCount,
        readyWindowCount: ready,
        reviewOnlyWindowCount: reviewOnly,
        pausedWindowCount: paused,
        unsafeWindowCount: 0,
        canUseForLiveAssist: ready > 0 || reviewOnly > 0,
        canUseForCalibrationEvidence: false,
        requiresUserReview: list.any((window) => window.requiresUserReview),
      );
    }
    if (reviewOnly > 0) {
      return _decision(
        status: TripGpsDependabilityRollupStatus.reviewOnly,
        reasonCode: 'gps_rollup_review_only_window_present',
        windowCount: windowCount,
        readyWindowCount: ready,
        reviewOnlyWindowCount: reviewOnly,
        pausedWindowCount: 0,
        unsafeWindowCount: 0,
        canUseForLiveAssist: true,
        canUseForCalibrationEvidence: false,
        requiresUserReview: list.any((window) => window.requiresUserReview),
      );
    }

    final readyRate = ready / windowCount;
    final calibrationReady =
        ready >= safeMinimumWindows && readyRate >= safeMinimumRate;
    return _decision(
      status: calibrationReady
          ? TripGpsDependabilityRollupStatus.reliable
          : TripGpsDependabilityRollupStatus.reviewOnly,
      reasonCode: calibrationReady
          ? 'gps_rollup_reliable'
          : 'gps_rollup_needs_more_ready_windows',
      windowCount: windowCount,
      readyWindowCount: ready,
      reviewOnlyWindowCount: 0,
      pausedWindowCount: 0,
      unsafeWindowCount: 0,
      canUseForLiveAssist: ready > 0,
      canUseForCalibrationEvidence: calibrationReady,
      requiresUserReview: false,
    );
  }
}

TripGpsDependabilityRollupDecision _decision({
  required TripGpsDependabilityRollupStatus status,
  required String reasonCode,
  required int windowCount,
  required int readyWindowCount,
  required int reviewOnlyWindowCount,
  required int pausedWindowCount,
  required int unsafeWindowCount,
  required bool canUseForLiveAssist,
  required bool canUseForCalibrationEvidence,
  required bool requiresUserReview,
}) {
  return TripGpsDependabilityRollupDecision(
    status: status,
    reasonCode: reasonCode,
    windowCount: windowCount,
    readyWindowCount: readyWindowCount,
    reviewOnlyWindowCount: reviewOnlyWindowCount,
    pausedWindowCount: pausedWindowCount,
    unsafeWindowCount: unsafeWindowCount,
    canUseForLiveAssist: canUseForLiveAssist,
    canUseForCalibrationEvidence: canUseForCalibrationEvidence,
    requiresUserReview: requiresUserReview,
  );
}

int _safeCount(int value) {
  if (value < 0) return 0;
  return value > 100000 ? 100000 : value;
}

String _safeReason(String reasonCode) {
  return switch (reasonCode.trim()) {
    'gps_rollup_waiting_for_windows' => 'gps_rollup_waiting_for_windows',
    'gps_rollup_unsafe_window_present' => 'gps_rollup_unsafe_window_present',
    'gps_rollup_projection_paused_window_present' =>
      'gps_rollup_projection_paused_window_present',
    'gps_rollup_review_only_window_present' =>
      'gps_rollup_review_only_window_present',
    'gps_rollup_reliable' => 'gps_rollup_reliable',
    'gps_rollup_needs_more_ready_windows' =>
      'gps_rollup_needs_more_ready_windows',
    _ => 'gps_rollup_unsafe_window_present',
  };
}

int _minimumReadyWindowsFor(TripTrackingProfile profile) {
  return switch (profile) {
    TripTrackingProfile.rideshareVehicle => 8,
    TripTrackingProfile.deliveryVehicle => 6,
    TripTrackingProfile.contractorVehicle => 6,
    TripTrackingProfile.lowSpeedEquipment => 5,
    TripTrackingProfile.roadVehicle => 5,
  };
}

double _minimumReadyRateFor(TripTrackingProfile profile) {
  return switch (profile) {
    TripTrackingProfile.rideshareVehicle => .85,
    TripTrackingProfile.lowSpeedEquipment => .8,
    TripTrackingProfile.deliveryVehicle ||
    TripTrackingProfile.contractorVehicle ||
    TripTrackingProfile.roadVehicle => .75,
  };
}
