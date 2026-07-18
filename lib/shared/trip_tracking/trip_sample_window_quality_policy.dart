import 'dart:math' as math;

export 'trip_sample_window_quality_summary_validation.dart';

import 'trip_route_history_capture_policy.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_signal_quality.dart';

part 'trip_sample_window_quality_helpers.dart';

enum TripSampleWindowQualityStatus {
  noSamples,
  usableForTracking,
  degradedTrackingOnly,
  routeStoragePaused,
  unsafeRejected,
}

class TripSampleWindowQualityDecision {
  const TripSampleWindowQualityDecision({
    required this.status,
    required this.reasonCode,
    required this.validSampleCount,
    required this.rejectedSampleCount,
    required this.acceptedSegmentCount,
    required this.rejectedGapSegmentCount,
    required this.rejectedJumpSegmentCount,
    required this.rejectedSpeedSegmentCount,
    required this.maximumConsecutiveRejectedSegments,
    required this.acceptedDistanceMeters,
    required this.maximumGapSeconds,
    required this.canFeedLiveOdometerProjection,
    required this.canPersistCompactRoutePoint,
  });

  final TripSampleWindowQualityStatus status;
  final String reasonCode;
  final int validSampleCount;
  final int rejectedSampleCount;
  final int acceptedSegmentCount;
  final int rejectedGapSegmentCount;
  final int rejectedJumpSegmentCount;
  final int rejectedSpeedSegmentCount;
  final int maximumConsecutiveRejectedSegments;
  final double acceptedDistanceMeters;
  final int maximumGapSeconds;
  final bool canFeedLiveOdometerProjection;
  final bool canPersistCompactRoutePoint;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'validSampleCount': _safeCount(validSampleCount),
    'rejectedSampleCount': _safeCount(rejectedSampleCount),
    'acceptedSegmentCount': _safeCount(acceptedSegmentCount),
    'rejectedGapSegmentCount': _safeCount(rejectedGapSegmentCount),
    'rejectedJumpSegmentCount': _safeCount(rejectedJumpSegmentCount),
    'rejectedSpeedSegmentCount': _safeCount(rejectedSpeedSegmentCount),
    'maximumConsecutiveRejectedSegments': _safeCount(
      maximumConsecutiveRejectedSegments,
    ),
    'acceptedDistanceBucket': _distanceBucket(acceptedDistanceMeters),
    'maximumGapSeconds': _safeGap(maximumGapSeconds),
    'canFeedLiveOdometerProjection': canFeedLiveOdometerProjection,
    'canPersistCompactRoutePoint': canPersistCompactRoutePoint,
    'gpsAssistedTrackingAvailableWithoutMaps': true,
    'mapsRequiredForGpsTracking': false,
    'routeStorageOptional': true,
    'routeStorageCanPauseWithoutStoppingTrip': true,
    'sampleWindowRequiresTrustedGpsSignal': true,
    'poorGpsPausesLiveProjection': true,
    'interruptedGpsPausesLiveProjection': true,
    'missingGpsPausesLiveProjection': true,
    'unsafeGpsBlocksSampleWindow': true,
    'projectionPausesOnSparseOrBrokenWindow': true,
    'segmentRejectionReasonsCounted': true,
    'sampleWindowRequiresLocalDeviceSource': true,
    'sampleWindowRequiresOwnershipValidation': true,
    'sampleWindowRequiresIntakeGuardBeforeEvaluation': true,
    'sampleWindowRequiresDeviceCapabilityContext': true,
    'sampleWindowRequiresMonotonicSampleOrder': true,
    'sampleWindowRequiresMovementCorroboration': true,
    'sampleWindowRequiresPermissionContinuity': true,
    'simulatorWindowRequiresExplicitTestHarness': true,
    'simulatorWindowCannotWriteProductionHistory': true,
    'authenticationAloneAuthorizesWindowUse': false,
    'sampleWindowCanConfirmOdometer': false,
    'sampleWindowCanSetGlobalTruth': false,
    'sampleWindowCanChangeOfficialMileage': false,
    'sampleWindowCanCreateOfficialStop': false,
    'sampleWindowCanBypassStopDebounce': false,
    'sampleWindowCanAutocorrectCalibration': false,
    'sampleWindowCanDeleteTripData': false,
    'mapboxCanOverrideWindowQuality': false,
    'firestoreCanOverrideWindowQuality': false,
    'remoteWindowCanOverrideLocalTrip': false,
    'remoteWindowCanRepairInvalidSamples': false,
    'mapboxCanFillSampleGaps': false,
    'cloudFunctionCanRepairSampleWindow': false,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'sampleTimestampsValidated': true,
    'duplicateOrOutOfOrderSegmentsRejected': true,
    'futureSamplesRejected': true,
    'staleSamplesRejectedWhenEvaluationClockProvided': true,
    'rawSamplesIncluded': false,
    'coordinatesIncluded': false,
    'preciseTimestampsIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripSampleWindowQualityPolicy {
  const TripSampleWindowQualityPolicy._();

  static TripSampleWindowQualityDecision evaluate({
    required List<TripLocationSample> samples,
    required TripRouteHistoryCaptureDecision routeHistoryDecision,
    TripTrackingSignalQuality signalQuality = TripTrackingSignalQuality.healthy,
    DateTime? evaluationNow,
    int persistedRoutePointsToday = 0,
    int maximumAcceptedGapSeconds = 180,
    double maximumAccuracyMeters = 120,
    double maximumPointJumpMeters = 2500,
    Duration maximumSampleAge = const Duration(hours: 18),
    Duration maximumFutureSkew = const Duration(minutes: 2),
  }) {
    final safeGapLimit = _safeGap(maximumAcceptedGapSeconds).clamp(30, 600);
    final safeAccuracy = _safeAccuracy(maximumAccuracyMeters);
    final safeJump = _safeJump(maximumPointJumpMeters);
    final safeNow = evaluationNow?.toUtc();
    final safeMaximumAge = _safeDuration(
      maximumSampleAge,
      fallback: const Duration(hours: 18),
      minimum: const Duration(minutes: 5),
      maximum: const Duration(days: 2),
    );
    final safeFutureSkew = _safeDuration(
      maximumFutureSkew,
      fallback: const Duration(minutes: 2),
      minimum: Duration.zero,
      maximum: const Duration(hours: 1),
    );
    if (signalQuality == TripTrackingSignalQuality.unsafe) {
      return _decision(
        status: TripSampleWindowQualityStatus.unsafeRejected,
        reasonCode: 'sample_window_unsafe_gps_signal',
        validSampleCount: 0,
        rejectedSampleCount: samples.length,
        acceptedSegmentCount: 0,
        rejectedGapSegmentCount: 0,
        rejectedJumpSegmentCount: 0,
        rejectedSpeedSegmentCount: 0,
        maximumConsecutiveRejectedSegments: 0,
        acceptedDistanceMeters: 0,
        maximumGapSeconds: 0,
        canFeedLiveOdometerProjection: false,
        canPersistCompactRoutePoint: false,
      );
    }
    final trustedSignal = _trustedSignalForProjection(signalQuality);
    final sorted = samples.where((sample) {
      return _isIndividuallySafe(
        sample,
        safeAccuracy,
        evaluationNow: safeNow,
        maximumSampleAge: safeMaximumAge,
        maximumFutureSkew: safeFutureSkew,
      );
    }).toList()..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final rejected = samples.length - sorted.length;

    if (samples.isEmpty) {
      return _decision(
        status: TripSampleWindowQualityStatus.noSamples,
        reasonCode: 'sample_window_empty',
        validSampleCount: 0,
        rejectedSampleCount: 0,
        acceptedSegmentCount: 0,
        rejectedGapSegmentCount: 0,
        rejectedJumpSegmentCount: 0,
        rejectedSpeedSegmentCount: 0,
        maximumConsecutiveRejectedSegments: 0,
        acceptedDistanceMeters: 0,
        maximumGapSeconds: 0,
        canFeedLiveOdometerProjection: false,
        canPersistCompactRoutePoint: false,
      );
    }
    if (sorted.length < 2) {
      return _decision(
        status: TripSampleWindowQualityStatus.degradedTrackingOnly,
        reasonCode: 'sample_window_needs_more_valid_points',
        validSampleCount: sorted.length,
        rejectedSampleCount: rejected,
        acceptedSegmentCount: 0,
        rejectedGapSegmentCount: 0,
        rejectedJumpSegmentCount: 0,
        rejectedSpeedSegmentCount: 0,
        maximumConsecutiveRejectedSegments: 0,
        acceptedDistanceMeters: 0,
        maximumGapSeconds: 0,
        canFeedLiveOdometerProjection: false,
        canPersistCompactRoutePoint: false,
      );
    }

    var acceptedDistance = 0.0;
    var acceptedSegments = 0;
    var rejectedSegments = 0;
    var rejectedGapSegments = 0;
    var rejectedJumpSegments = 0;
    var rejectedSpeedSegments = 0;
    var consecutiveRejectedSegments = 0;
    var maximumConsecutiveRejectedSegments = 0;
    var maximumGap = 0;
    for (var index = 1; index < sorted.length; index += 1) {
      final previous = sorted[index - 1];
      final current = sorted[index];
      final gapSeconds = current.recordedAt
          .toUtc()
          .difference(previous.recordedAt.toUtc())
          .inSeconds;
      maximumGap = math.max(maximumGap, gapSeconds);
      final distance = _distanceMeters(previous, current);
      final rejectedForGap = gapSeconds <= 0 || gapSeconds > safeGapLimit;
      final rejectedForJump = distance > safeJump;
      final rejectedForSpeed = _impossibleSegmentSpeed(distance, gapSeconds);
      if (rejectedForGap || rejectedForJump || rejectedForSpeed) {
        rejectedSegments += 1;
        if (rejectedForGap) rejectedGapSegments += 1;
        if (rejectedForJump) rejectedJumpSegments += 1;
        if (rejectedForSpeed) rejectedSpeedSegments += 1;
        consecutiveRejectedSegments += 1;
        maximumConsecutiveRejectedSegments = math.max(
          maximumConsecutiveRejectedSegments,
          consecutiveRejectedSegments,
        );
        continue;
      }
      acceptedSegments += 1;
      consecutiveRejectedSegments = 0;
      acceptedDistance += distance;
    }

    if (rejectedSegments >= sorted.length - 1) {
      return _decision(
        status: TripSampleWindowQualityStatus.unsafeRejected,
        reasonCode: 'sample_window_segments_rejected',
        validSampleCount: sorted.length,
        rejectedSampleCount: rejected + rejectedSegments,
        acceptedSegmentCount: acceptedSegments,
        rejectedGapSegmentCount: rejectedGapSegments,
        rejectedJumpSegmentCount: rejectedJumpSegments,
        rejectedSpeedSegmentCount: rejectedSpeedSegments,
        maximumConsecutiveRejectedSegments: maximumConsecutiveRejectedSegments,
        acceptedDistanceMeters: 0,
        maximumGapSeconds: maximumGap,
        canFeedLiveOdometerProjection: false,
        canPersistCompactRoutePoint: false,
      );
    }

    final routePointAllowed = _routePointAllowed(
      routeHistoryDecision,
      persistedRoutePointsToday,
    );
    final stationaryContradiction = _reportedStationaryContradictsDistance(
      sorted,
      acceptedDistance,
    );
    final projectionSafe =
        _canFeedProjection(
          acceptedSegments: acceptedSegments,
          rejectedSegments: rejectedSegments,
          maximumConsecutiveRejectedSegments:
              maximumConsecutiveRejectedSegments,
          maximumGap: maximumGap,
          safeGapLimit: safeGapLimit,
          acceptedDistanceMeters: acceptedDistance,
        ) &&
        !stationaryContradiction &&
        trustedSignal;
    if (!routePointAllowed && routeHistoryDecision.canCaptureRouteHistory) {
      return _decision(
        status: TripSampleWindowQualityStatus.routeStoragePaused,
        reasonCode: 'route_storage_budget_paused',
        validSampleCount: sorted.length,
        rejectedSampleCount: rejected + rejectedSegments,
        acceptedSegmentCount: acceptedSegments,
        rejectedGapSegmentCount: rejectedGapSegments,
        rejectedJumpSegmentCount: rejectedJumpSegments,
        rejectedSpeedSegmentCount: rejectedSpeedSegments,
        maximumConsecutiveRejectedSegments: maximumConsecutiveRejectedSegments,
        acceptedDistanceMeters: acceptedDistance,
        maximumGapSeconds: maximumGap,
        canFeedLiveOdometerProjection: projectionSafe,
        canPersistCompactRoutePoint: false,
      );
    }

    final degraded =
        maximumGap > safeGapLimit || rejectedSegments > 0 || rejected > 0;
    final sparseOrBroken = acceptedDistance > 0 && !projectionSafe;
    return _decision(
      status: degraded
          ? TripSampleWindowQualityStatus.degradedTrackingOnly
          : TripSampleWindowQualityStatus.usableForTracking,
      reasonCode: sparseOrBroken
          ? 'sample_window_projection_paused'
          : stationaryContradiction
          ? 'sample_window_projection_paused'
          : degraded
          ? 'sample_window_degraded_but_usable'
          : 'sample_window_usable',
      validSampleCount: sorted.length,
      rejectedSampleCount: rejected + rejectedSegments,
      acceptedSegmentCount: acceptedSegments,
      rejectedGapSegmentCount: rejectedGapSegments,
      rejectedJumpSegmentCount: rejectedJumpSegments,
      rejectedSpeedSegmentCount: rejectedSpeedSegments,
      maximumConsecutiveRejectedSegments: maximumConsecutiveRejectedSegments,
      acceptedDistanceMeters: acceptedDistance,
      maximumGapSeconds: maximumGap,
      canFeedLiveOdometerProjection: projectionSafe,
      canPersistCompactRoutePoint:
          routePointAllowed && trustedSignal && !stationaryContradiction,
    );
  }
}

TripSampleWindowQualityDecision _decision({
  required TripSampleWindowQualityStatus status,
  required String reasonCode,
  required int validSampleCount,
  required int rejectedSampleCount,
  required int acceptedSegmentCount,
  required int rejectedGapSegmentCount,
  required int rejectedJumpSegmentCount,
  required int rejectedSpeedSegmentCount,
  required int maximumConsecutiveRejectedSegments,
  required double acceptedDistanceMeters,
  required int maximumGapSeconds,
  required bool canFeedLiveOdometerProjection,
  required bool canPersistCompactRoutePoint,
}) {
  return TripSampleWindowQualityDecision(
    status: status,
    reasonCode: reasonCode,
    validSampleCount: _safeCount(validSampleCount),
    rejectedSampleCount: _safeCount(rejectedSampleCount),
    acceptedSegmentCount: _safeCount(acceptedSegmentCount),
    rejectedGapSegmentCount: _safeCount(rejectedGapSegmentCount),
    rejectedJumpSegmentCount: _safeCount(rejectedJumpSegmentCount),
    rejectedSpeedSegmentCount: _safeCount(rejectedSpeedSegmentCount),
    maximumConsecutiveRejectedSegments: _safeCount(
      maximumConsecutiveRejectedSegments,
    ),
    acceptedDistanceMeters: acceptedDistanceMeters.isFinite
        ? acceptedDistanceMeters.clamp(0, 1000000).toDouble()
        : 0,
    maximumGapSeconds: _safeGap(maximumGapSeconds),
    canFeedLiveOdometerProjection: canFeedLiveOdometerProjection,
    canPersistCompactRoutePoint: canPersistCompactRoutePoint,
  );
}
