import 'trip_tracking_calibration_state.dart';
import 'trip_tracking_odometer_calibration.dart';

enum TripTrackingCalibrationApplyStatus {
  disabled,
  waitingForHistory,
  reviewRequired,
  readyForFutureProjection,
  rejected,
}

enum TripTrackingCalibrationHistorySource {
  localReviewedOdometerHistory,
  firestoreMirror,
  cloudFunction,
  importedFile,
  mapbox,
  dashboardCache,
}

class TripTrackingCalibrationApplyGuard {
  const TripTrackingCalibrationApplyGuard._({
    required this.status,
    required this.multiplier,
    required this.reasonCodes,
    required this.trustedGpsWindowCount,
    required this.excludedPoorGpsDayCount,
  });

  factory TripTrackingCalibrationApplyGuard.evaluate({
    required TripOdometerCalibrationSignal signal,
    required bool userOptedIn,
    required bool userAcceptedLatestReview,
    required int minimumReviewedDays,
    required DateTime? latestReviewedAtUtc,
    required DateTime nowUtc,
    String? activeVehicleId,
    String? reviewedVehicleId,
    Iterable<String> reviewedVehicleIds = const <String>[],
    String? currentUserId,
    String? calibrationOwnerUserId,
    bool explicitSharedVehicleAccess = false,
    bool fleetObserverMode = false,
    TripTrackingCalibrationHistorySource historySource =
        TripTrackingCalibrationHistorySource.localReviewedOdometerHistory,
    Duration maximumCalibrationReviewAge = const Duration(days: 30),
  }) {
    final reasons = <String>[];
    final now = nowUtc.toUtc();
    final latestReviewed = latestReviewedAtUtc?.toUtc();
    final activeVehicle = activeVehicleId?.trim();
    final reviewedVehicle = reviewedVehicleId?.trim();
    final currentUser = _safeUserToken(currentUserId);
    final calibrationOwner = _safeUserToken(calibrationOwnerUserId);
    final reviewedVehicles = reviewedVehicleIds
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (minimumReviewedDays <= 0) reasons.add('invalid_minimum_reviewed_days');
    if (signal.eligibleSampleCount < 0) reasons.add('negative_sample_count');
    if (signal.eligibleSampleCount > 366) reasons.add('excessive_sample_count');
    final trustedGpsWindowCount =
        signal.trustedGpsWindowCount ?? signal.eligibleSampleCount;
    if (trustedGpsWindowCount < 0) {
      reasons.add('negative_trusted_gps_window_count');
    }
    if (trustedGpsWindowCount > 366) {
      reasons.add('excessive_trusted_gps_window_count');
    }
    if (trustedGpsWindowCount < signal.eligibleSampleCount) {
      reasons.add('trusted_gps_window_count_below_eligible_days');
    }
    if (signal.excludedPoorGpsDayCount < 0) {
      reasons.add('negative_excluded_poor_gps_day_count');
    }
    if (signal.excludedPoorGpsDayCount > 366) {
      reasons.add('excessive_excluded_poor_gps_day_count');
    }
    if (!signal.averageGpsToOdometerRatio.isFinite ||
        signal.averageGpsToOdometerRatio <= 0) {
      reasons.add('invalid_gps_odometer_ratio');
    }
    if (!signal.averageDifferencePercent.isFinite ||
        signal.averageDifferencePercent < 0) {
      reasons.add('invalid_difference_percent');
    }
    if (_safeReason(signal.reasonCode) == 'unknown_calibration_state') {
      reasons.add('unknown_signal_reason');
    }
    if (historySource !=
        TripTrackingCalibrationHistorySource.localReviewedOdometerHistory) {
      reasons.add('local_reviewed_odometer_history_required');
    }
    if (fleetObserverMode) reasons.add('fleet_observer_read_only');
    if (currentUserId != null && currentUser == null) {
      reasons.add('unsafe_current_user_id');
    }
    if (calibrationOwnerUserId != null && calibrationOwner == null) {
      reasons.add('unsafe_calibration_owner_user_id');
    }
    if (currentUser != null &&
        calibrationOwner != null &&
        currentUser != calibrationOwner &&
        !explicitSharedVehicleAccess) {
      reasons.add('calibration_owner_or_explicit_access_required');
    }
    if (latestReviewed != null && latestReviewed.isAfter(now)) {
      reasons.add('future_review_timestamp');
    }
    if (signal.status == TripOdometerCalibrationStatus.reviewRecommended &&
        latestReviewed == null) {
      reasons.add('missing_latest_review_timestamp');
    }
    if (latestReviewed != null &&
        latestReviewed.isBefore(
          now.subtract(_safeReviewAge(maximumCalibrationReviewAge)),
        )) {
      reasons.add('stale_review_timestamp');
    }
    if (activeVehicle != null && !_isSafeVehicleToken(activeVehicle)) {
      reasons.add('unsafe_active_vehicle_id');
    }
    if (reviewedVehicle != null && !_isSafeVehicleToken(reviewedVehicle)) {
      reasons.add('unsafe_reviewed_vehicle_id');
    }
    if (reviewedVehicles.any((value) => !_isSafeVehicleToken(value))) {
      reasons.add('unsafe_reviewed_vehicle_id');
    }
    if (reviewedVehicles.length > 1) {
      reasons.add('mixed_vehicle_calibration_history');
    }
    if (activeVehicle != null &&
        reviewedVehicle != null &&
        activeVehicle != reviewedVehicle) {
      reasons.add('calibration_vehicle_mismatch');
    }
    if (activeVehicle != null &&
        reviewedVehicles.isNotEmpty &&
        !reviewedVehicles.contains(activeVehicle)) {
      reasons.add('calibration_vehicle_mismatch');
    }
    if (reasons.isNotEmpty) {
      return TripTrackingCalibrationApplyGuard._(
        status: TripTrackingCalibrationApplyStatus.rejected,
        multiplier: 1,
        reasonCodes: List.unmodifiable(reasons),
        trustedGpsWindowCount: _safeEvidenceCount(trustedGpsWindowCount),
        excludedPoorGpsDayCount: _safeEvidenceCount(
          signal.excludedPoorGpsDayCount,
        ),
      );
    }
    if (!userOptedIn) {
      return TripTrackingCalibrationApplyGuard._(
        status: TripTrackingCalibrationApplyStatus.disabled,
        multiplier: 1,
        reasonCodes: const ['calibration_user_opt_in_required'],
        trustedGpsWindowCount: _safeEvidenceCount(trustedGpsWindowCount),
        excludedPoorGpsDayCount: _safeEvidenceCount(
          signal.excludedPoorGpsDayCount,
        ),
      );
    }
    if (signal.eligibleSampleCount < minimumReviewedDays ||
        trustedGpsWindowCount < minimumReviewedDays ||
        signal.status == TripOdometerCalibrationStatus.insufficientHistory) {
      return TripTrackingCalibrationApplyGuard._(
        status: TripTrackingCalibrationApplyStatus.waitingForHistory,
        multiplier: 1,
        reasonCodes: const ['more_reviewed_odometer_days_required'],
        trustedGpsWindowCount: _safeEvidenceCount(trustedGpsWindowCount),
        excludedPoorGpsDayCount: _safeEvidenceCount(
          signal.excludedPoorGpsDayCount,
        ),
      );
    }
    if (signal.status == TripOdometerCalibrationStatus.reviewRecommended &&
        !userAcceptedLatestReview) {
      return TripTrackingCalibrationApplyGuard._(
        status: TripTrackingCalibrationApplyStatus.reviewRequired,
        multiplier: 1,
        reasonCodes: const ['user_must_accept_calibration_review'],
        trustedGpsWindowCount: _safeEvidenceCount(trustedGpsWindowCount),
        excludedPoorGpsDayCount: _safeEvidenceCount(
          signal.excludedPoorGpsDayCount,
        ),
      );
    }
    if (signal.status == TripOdometerCalibrationStatus.stable) {
      return TripTrackingCalibrationApplyGuard._(
        status: TripTrackingCalibrationApplyStatus.readyForFutureProjection,
        multiplier: 1,
        reasonCodes: const ['calibration_stable_neutral_multiplier'],
        trustedGpsWindowCount: _safeEvidenceCount(trustedGpsWindowCount),
        excludedPoorGpsDayCount: _safeEvidenceCount(
          signal.excludedPoorGpsDayCount,
        ),
      );
    }
    return TripTrackingCalibrationApplyGuard._(
      status: TripTrackingCalibrationApplyStatus.readyForFutureProjection,
      multiplier: TripTrackingCalibrationState.safeMultiplier(
        signal.gpsAssistanceCalibrationMultiplier,
      ),
      reasonCodes: const ['calibration_review_accepted_future_projection_only'],
      trustedGpsWindowCount: _safeEvidenceCount(trustedGpsWindowCount),
      excludedPoorGpsDayCount: _safeEvidenceCount(
        signal.excludedPoorGpsDayCount,
      ),
    );
  }

  final TripTrackingCalibrationApplyStatus status;
  final double multiplier;
  final List<String> reasonCodes;
  final int trustedGpsWindowCount;
  final int excludedPoorGpsDayCount;

  bool get canApplyToFutureGpsProjection =>
      status == TripTrackingCalibrationApplyStatus.readyForFutureProjection;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'multiplier': _safeRoundedMultiplier(multiplier),
    'reasonCodes': reasonCodes,
    'canApplyToFutureGpsProjection': canApplyToFutureGpsProjection,
    'appliesToPastTrips': false,
    'canRewriteConfirmedOdometer': false,
    'canApplySilently': false,
    'calibrationCanChangeDisplayedConfirmedMiles': false,
    'calibrationCanMutateTripLog': false,
    'calibrationCanPurgeLocalDataAfterBackup': false,
    'calibrationCanBypassVehicleProfile': false,
    'calibrationCanApplyAcrossVehicles': false,
    'calibrationRequiresSingleVehicleHistory': true,
    'calibrationRequiresLocalReviewedOdometerHistory': true,
    'calibrationRequiresOwnershipOrExplicitAccess': true,
    'fleetObserverCanApplyCalibration': false,
    'calibrationVehicleIdIncluded': false,
    'rawVehicleIdsIncluded': false,
    'remoteCalibrationCanRewritePastTrips': false,
    'mapboxRouteDistanceCanBecomeOfficial': false,
    'userOptInRequired': true,
    'reviewAcceptanceRequired': true,
    'requiresMultipleReviewedOdometerDays': true,
    'continuousCalibrationAverageRequired': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'calibrationRequiresTrustedGpsWindow': true,
    'trustedGpsWindowCount': trustedGpsWindowCount,
    'excludedPoorGpsDayCount': excludedPoorGpsDayCount,
    'excludedPoorGpsDayCountIncluded': true,
    'poorGpsExcludedDayCountTrustedAfterValidationOnly': true,
    'singleDayCalibrationRejected': true,
    'calibrationAverageVehicleScoped': true,
    'latestReviewTimestampRequired': true,
    'staleCalibrationReviewRejected': true,
    'excessiveHistoryCountRejected': true,
    'tireOrSpeedometerReviewIsAdvisory': true,
    'tireChangeDoesNotCreateMaintenanceEntry': true,
    'settingsCanDisableCalibrationAssist': true,
    'settingsCanResetCalibrationPrompt': true,
    'odometerIsGlobalTruth': true,
    'odometerRemainsCanonical': true,
    'gpsEstimateRemainsNonCanonical': true,
    'remoteCalibrationCanOverrideLocalState': false,
    'firestoreCanApplyCalibration': false,
    'mapboxCanApplyCalibration': false,
    'cloudFunctionCanApplyCalibration': false,
    'importedFileCanApplyCalibration': false,
    'dashboardCacheCanApplyCalibration': false,
    'remoteCalibrationCanEnableSetting': false,
    'remoteCalibrationCanResetPrompt': false,
    'mapboxCanTriggerTirePrompt': false,
    'gpsCanAutoApplyCalibration': false,
    'calibrationCanLowerConfirmedOdometer': false,
    'calibrationCanCreateMaintenanceRecord': false,
    'rawReviewedTripsIncluded': false,
    'rawGpsIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };
}

class TripTrackingCalibrationApplySummaryValidation {
  const TripTrackingCalibrationApplySummaryValidation._({
    required this.isRenderable,
    required this.status,
    required this.reasons,
  });

  factory TripTrackingCalibrationApplySummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final status = _safeStatus(summary['status']);
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (status == null) reasons.add('invalid_calibration_apply_status');
    final multiplier = summary['multiplier'];
    if (multiplier is! num ||
        !multiplier.isFinite ||
        multiplier < 0.8 ||
        multiplier > 1.25) {
      reasons.add('invalid_calibration_multiplier');
    }
    final reasonCodes = summary['reasonCodes'];
    if (reasonCodes is! List ||
        reasonCodes.any((reason) => _safeApplyReason(reason) == null)) {
      reasons.add('invalid_calibration_reason_codes');
    }
    if (summary['canApplyToFutureGpsProjection'] == true &&
        status != TripTrackingCalibrationApplyStatus.readyForFutureProjection) {
      reasons.add('unsafe_future_projection_apply_claim');
    }
    final trustedGpsWindowCount = summary['trustedGpsWindowCount'];
    if (trustedGpsWindowCount is! int ||
        trustedGpsWindowCount < 0 ||
        trustedGpsWindowCount > 366) {
      reasons.add('invalid_trusted_gps_window_count');
    }
    final excludedPoorGpsDayCount = summary['excludedPoorGpsDayCount'];
    if (excludedPoorGpsDayCount is! int ||
        excludedPoorGpsDayCount < 0 ||
        excludedPoorGpsDayCount > 366) {
      reasons.add('invalid_excluded_poor_gps_day_count');
    }
    if (summary['appliesToPastTrips'] != false ||
        summary['canRewriteConfirmedOdometer'] != false ||
        summary['canApplySilently'] != false ||
        summary['calibrationCanChangeDisplayedConfirmedMiles'] != false ||
        summary['calibrationCanMutateTripLog'] != false ||
        summary['calibrationCanPurgeLocalDataAfterBackup'] != false ||
        summary['calibrationCanBypassVehicleProfile'] != false ||
        summary['calibrationCanApplyAcrossVehicles'] != false ||
        summary['calibrationRequiresSingleVehicleHistory'] != true ||
        summary['calibrationRequiresLocalReviewedOdometerHistory'] != true ||
        summary['calibrationRequiresOwnershipOrExplicitAccess'] != true ||
        summary['fleetObserverCanApplyCalibration'] != false ||
        summary['remoteCalibrationCanRewritePastTrips'] != false) {
      reasons.add('calibration_can_mutate_trip_truth');
    }
    if (summary['mapboxRouteDistanceCanBecomeOfficial'] != false ||
        summary['firestoreCanApplyCalibration'] != false ||
        summary['mapboxCanApplyCalibration'] != false ||
        summary['cloudFunctionCanApplyCalibration'] != false ||
        summary['importedFileCanApplyCalibration'] != false ||
        summary['dashboardCacheCanApplyCalibration'] != false ||
        summary['remoteCalibrationCanOverrideLocalState'] != false) {
      reasons.add('remote_or_map_can_apply_calibration');
    }
    if (summary['userOptInRequired'] != true ||
        summary['reviewAcceptanceRequired'] != true ||
        summary['requiresMultipleReviewedOdometerDays'] != true ||
        summary['continuousCalibrationAverageRequired'] != true ||
        summary['poorGpsDaysExcludedFromCalibration'] != true ||
        summary['calibrationRequiresTrustedGpsWindow'] != true ||
        summary['excludedPoorGpsDayCountIncluded'] != true ||
        summary['poorGpsExcludedDayCountTrustedAfterValidationOnly'] != true ||
        summary['singleDayCalibrationRejected'] != true ||
        summary['calibrationAverageVehicleScoped'] != true ||
        summary['latestReviewTimestampRequired'] != true ||
        summary['staleCalibrationReviewRejected'] != true ||
        summary['excessiveHistoryCountRejected'] != true ||
        summary['settingsCanDisableCalibrationAssist'] != true ||
        summary['settingsCanResetCalibrationPrompt'] != true) {
      reasons.add('calibration_review_boundary_missing');
    }
    if (summary['odometerIsGlobalTruth'] != true ||
        summary['odometerRemainsCanonical'] != true ||
        summary['gpsEstimateRemainsNonCanonical'] != true ||
        summary['tireOrSpeedometerReviewIsAdvisory'] != true ||
        summary['tireChangeDoesNotCreateMaintenanceEntry'] != true ||
        summary['calibrationCanLowerConfirmedOdometer'] != false ||
        summary['calibrationCanCreateMaintenanceRecord'] != false) {
      reasons.add('odometer_truth_boundary_missing');
    }
    if (summary['remoteCalibrationCanEnableSetting'] != false ||
        summary['remoteCalibrationCanResetPrompt'] != false ||
        summary['mapboxCanTriggerTirePrompt'] != false ||
        summary['gpsCanAutoApplyCalibration'] != false) {
      reasons.add('remote_or_sensor_can_control_prompt');
    }
    if (summary['rawReviewedTripsIncluded'] != false ||
        summary['rawGpsIncluded'] != false ||
        summary['calibrationVehicleIdIncluded'] != false ||
        summary['rawVehicleIdsIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['tokensIncluded'] != false) {
      reasons.add('summary_contains_sensitive_calibration_material');
    }
    if (summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_text');
    }

    return TripTrackingCalibrationApplySummaryValidation._(
      isRenderable: reasons.isEmpty,
      status: reasons.isEmpty ? status : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final TripTrackingCalibrationApplyStatus? status;
  final List<String> reasons;
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'invalid_calibration_threshold' => value.trim(),
    'needs_more_reviewed_days' => value.trim(),
    'mixed_vehicle_calibration_history' => value.trim(),
    'persistent_gps_odometer_drift' => value.trim(),
    'calibration_stable' => value.trim(),
    _ => 'unknown_calibration_state',
  };
}

double _safeRoundedMultiplier(double value) {
  final safe = TripTrackingCalibrationState.safeMultiplier(value);
  return double.parse(safe.toStringAsFixed(4));
}

Duration _safeReviewAge(Duration value) {
  if (value <= Duration.zero) return const Duration(days: 1);
  return value > const Duration(days: 90) ? const Duration(days: 90) : value;
}

TripTrackingCalibrationApplyStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripTrackingCalibrationApplyStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

String? _safeApplyReason(Object? value) {
  if (value is! String) return null;
  return switch (value) {
    'invalid_minimum_reviewed_days' => value,
    'negative_sample_count' => value,
    'excessive_sample_count' => value,
    'negative_trusted_gps_window_count' => value,
    'excessive_trusted_gps_window_count' => value,
    'trusted_gps_window_count_below_eligible_days' => value,
    'negative_excluded_poor_gps_day_count' => value,
    'excessive_excluded_poor_gps_day_count' => value,
    'invalid_gps_odometer_ratio' => value,
    'invalid_difference_percent' => value,
    'unknown_signal_reason' => value,
    'future_review_timestamp' => value,
    'missing_latest_review_timestamp' => value,
    'stale_review_timestamp' => value,
    'local_reviewed_odometer_history_required' => value,
    'fleet_observer_read_only' => value,
    'unsafe_current_user_id' => value,
    'unsafe_calibration_owner_user_id' => value,
    'calibration_owner_or_explicit_access_required' => value,
    'unsafe_active_vehicle_id' => value,
    'unsafe_reviewed_vehicle_id' => value,
    'mixed_vehicle_calibration_history' => value,
    'calibration_vehicle_mismatch' => value,
    'calibration_user_opt_in_required' => value,
    'more_reviewed_odometer_days_required' => value,
    'user_must_accept_calibration_review' => value,
    'calibration_stable_neutral_multiplier' => value,
    'calibration_review_accepted_future_projection_only' => value,
    _ => null,
  };
}

int _safeEvidenceCount(int value) => value < 0
    ? 0
    : value > 366
    ? 366
    : value;

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}

bool _isSafeVehicleToken(String value) {
  final clean = value.trim();
  return clean.isNotEmpty &&
      clean.length <= 120 &&
      RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(clean);
}

String? _safeUserToken(String? value) {
  final clean = value?.trim();
  if (clean == null || clean.isEmpty || clean.length > 128) return null;
  if (clean.startsWith('pk.') || clean.startsWith('sk.')) return null;
  if (!RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(clean)) return null;
  return clean;
}
