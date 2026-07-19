part of 'trip_gps_dependability_rollup_policy.dart';

class TripGpsDependabilityRollupSummaryValidation {
  const TripGpsDependabilityRollupSummaryValidation._({
    required this.isRenderable,
    required this.status,
    required this.reasons,
  });

  factory TripGpsDependabilityRollupSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final status = _safeStatus(summary['status']);
    if (summary['schemaVersion'] != 1) reasons.add('unsupported_schema');
    if (status == null) reasons.add('invalid_gps_rollup_status');
    if (_safeReasonValue(summary['reasonCode']) == null) {
      reasons.add('invalid_gps_rollup_reason');
    }
    for (final key in _rollupCountKeys) {
      if (summary[key] is! int || (summary[key] as int) < 0) {
        reasons.add('${key}_invalid');
      }
    }
    for (final key in _rollupBoolKeys) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['oneGoodWindowCannotClearBadDay'] != true ||
        summary['poorWindowExcludesCalibrationDay'] != true ||
        summary['interruptedWindowExcludesCalibrationDay'] != true ||
        summary['unsafeWindowExcludesCalibrationDay'] != true ||
        summary['duplicateWindowExcludesCalibrationDay'] != true ||
        summary['calibrationRequiresSustainedDailyGpsQuality'] != true ||
        summary['calibrationRequiresReviewedOdometerTruth'] != true) {
      reasons.add('gps_rollup_calibration_boundary_missing');
    }
    if (summary['gpsRollupCanReplaceOdometer'] != false ||
        summary['gpsRollupCanConfirmOfficialMileage'] != false ||
        summary['gpsRollupCanCreateOfficialStop'] != false ||
        summary['odometerIsGlobalTruth'] != true) {
      reasons.add('gps_rollup_can_create_trip_truth');
    }
    if (summary['mapboxCanOverrideGpsRollup'] != false ||
        summary['firestoreCanOverrideGpsRollup'] != false ||
        summary['cloudFunctionCanOverrideGpsRollup'] != false ||
        summary['hiveRemainsOperationalSourceOfTruth'] != true) {
      reasons.add('remote_can_override_gps_rollup');
    }
    if (summary['rawSamplesIncluded'] != false ||
        summary['coordinatesIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false) {
      reasons.add('summary_contains_sensitive_trip_material');
    }
    reasons.addAll(_rollupStatusBoundaryRisks(summary, status));
    if (summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_text');
    }

    return TripGpsDependabilityRollupSummaryValidation._(
      isRenderable: reasons.isEmpty,
      status: reasons.isEmpty ? status : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final TripGpsDependabilityRollupStatus? status;
  final List<String> reasons;
}

const _rollupCountKeys = [
  'windowCount',
  'readyWindowCount',
  'reviewOnlyWindowCount',
  'pausedWindowCount',
  'unsafeWindowCount',
];

const _rollupBoolKeys = [
  'canUseForLiveAssist',
  'canUseForCalibrationEvidence',
  'requiresUserReview',
  'oneGoodWindowCannotClearBadDay',
  'poorWindowExcludesCalibrationDay',
  'interruptedWindowExcludesCalibrationDay',
  'unsafeWindowExcludesCalibrationDay',
  'duplicateWindowExcludesCalibrationDay',
  'calibrationRequiresSustainedDailyGpsQuality',
  'calibrationRequiresReviewedOdometerTruth',
  'gpsRollupCanReplaceOdometer',
  'gpsRollupCanConfirmOfficialMileage',
  'gpsRollupCanCreateOfficialStop',
  'mapboxCanOverrideGpsRollup',
  'firestoreCanOverrideGpsRollup',
  'cloudFunctionCanOverrideGpsRollup',
  'hiveRemainsOperationalSourceOfTruth',
  'odometerIsGlobalTruth',
  'rawSamplesIncluded',
  'coordinatesIncluded',
  'routeGeometryIncluded',
  'tokensIncluded',
];

List<String> _rollupStatusBoundaryRisks(
  Map<String, Object?> summary,
  TripGpsDependabilityRollupStatus? status,
) {
  if (status == null) return const [];
  final reason = _safeReasonValue(summary['reasonCode']);
  final windowCount = _intField(summary, 'windowCount');
  final ready = _intField(summary, 'readyWindowCount');
  final reviewOnly = _intField(summary, 'reviewOnlyWindowCount');
  final paused = _intField(summary, 'pausedWindowCount');
  final unsafe = _intField(summary, 'unsafeWindowCount');
  final canUseForLiveAssist = _boolField(summary, 'canUseForLiveAssist');
  final canUseForCalibrationEvidence = _boolField(
    summary,
    'canUseForCalibrationEvidence',
  );
  final requiresUserReview = _boolField(summary, 'requiresUserReview');
  if (reason == null ||
      windowCount == null ||
      ready == null ||
      reviewOnly == null ||
      paused == null ||
      unsafe == null ||
      canUseForLiveAssist == null ||
      canUseForCalibrationEvidence == null ||
      requiresUserReview == null) {
    return const [];
  }
  final risks = <String>[];
  if (ready + reviewOnly + paused + unsafe != windowCount) {
    risks.add('gps_rollup_window_counts_mismatch');
  }
  if (canUseForCalibrationEvidence &&
      (status != TripGpsDependabilityRollupStatus.reliable ||
          reason != 'gps_rollup_reliable')) {
    risks.add('gps_rollup_calibration_authority_mismatch');
  }

  switch (status) {
    case TripGpsDependabilityRollupStatus.noWindows:
      if (reason != 'gps_rollup_waiting_for_windows' ||
          windowCount != 0 ||
          ready != 0 ||
          reviewOnly != 0 ||
          paused != 0 ||
          unsafe != 0 ||
          canUseForLiveAssist ||
          canUseForCalibrationEvidence ||
          requiresUserReview) {
        risks.add('gps_rollup_no_windows_authority_mismatch');
      }
    case TripGpsDependabilityRollupStatus.reliable:
      if (reason != 'gps_rollup_reliable' ||
          windowCount <= 0 ||
          ready <= 0 ||
          reviewOnly != 0 ||
          paused != 0 ||
          unsafe != 0 ||
          !canUseForLiveAssist ||
          !canUseForCalibrationEvidence ||
          requiresUserReview) {
        risks.add('gps_rollup_reliable_authority_mismatch');
      }
    case TripGpsDependabilityRollupStatus.reviewOnly:
      if ((reason != 'gps_rollup_review_only_window_present' &&
              reason != 'gps_rollup_needs_more_ready_windows') ||
          windowCount <= 0 ||
          paused != 0 ||
          unsafe != 0 ||
          !canUseForLiveAssist ||
          canUseForCalibrationEvidence) {
        risks.add('gps_rollup_review_only_authority_mismatch');
      }
    case TripGpsDependabilityRollupStatus.excludedFromCalibration:
      if (reason != 'gps_rollup_projection_paused_window_present' ||
          windowCount <= 0 ||
          paused <= 0 ||
          unsafe != 0 ||
          canUseForCalibrationEvidence) {
        risks.add('gps_rollup_excluded_calibration_authority_mismatch');
      }
    case TripGpsDependabilityRollupStatus.unsafe:
      if ((reason != 'gps_rollup_unsafe_window_present' &&
              reason != 'gps_rollup_duplicate_window_rejected' &&
              reason != 'gps_rollup_incomplete_window_identity') ||
          windowCount <= 0 ||
          canUseForLiveAssist ||
          canUseForCalibrationEvidence ||
          !requiresUserReview) {
        risks.add('gps_rollup_unsafe_authority_mismatch');
      }
  }
  return risks;
}

TripGpsDependabilityRollupStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripGpsDependabilityRollupStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

String? _safeReasonValue(Object? value) {
  if (value is! String) return null;
  final safe = _safeReason(value);
  return safe == value ? safe : null;
}

int? _intField(Map<String, Object?> summary, String key) {
  final value = summary[key];
  return value is int && value >= 0 ? value : null;
}

bool? _boolField(Map<String, Object?> summary, String key) {
  final value = summary[key];
  return value is bool ? value : null;
}
