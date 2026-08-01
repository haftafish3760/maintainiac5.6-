part of 'trip_tracking_calibration_apply_guard.dart';

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
    final safeReasons = _safeReasonCodes(reasonCodes);
    if (safeReasons == null) reasons.add('invalid_calibration_reason_codes');
    if (summary['canApplyToFutureGpsProjection'] == true &&
        status != TripTrackingCalibrationApplyStatus.readyForFutureProjection) {
      reasons.add('unsafe_future_projection_apply_claim');
    }
    final trustedGpsWindowCount = _safeSummaryCount(
      summary['trustedGpsWindowCount'],
    );
    if (trustedGpsWindowCount == null) {
      reasons.add('invalid_trusted_gps_window_count');
    }
    final excludedPoorGpsDayCount = _safeSummaryCount(
      summary['excludedPoorGpsDayCount'],
    );
    if (excludedPoorGpsDayCount == null) {
      reasons.add('invalid_excluded_poor_gps_day_count');
    }
    _validateTruthMutationClaims(summary, reasons);
    _validateRemoteApplyClaims(summary, reasons);
    _validateReviewBoundaryClaims(summary, reasons);
    _validateOdometerTruthClaims(summary, reasons);
    final truthValidation = TripTrackingOdometerTruthPolicy.validateSummary(
      summary,
    );
    reasons.addAll(truthValidation.reasons);
    _validatePromptControlClaims(summary, reasons);
    _validateSensitiveSummaryClaims(summary, reasons);
    reasons.addAll(
      _calibrationStatusBoundaryRisks(
        status: status,
        reasonCodes: safeReasons,
        canApplyToFutureGpsProjection:
            summary['canApplyToFutureGpsProjection'] == true,
        trustedGpsWindowCount: trustedGpsWindowCount,
        excludedPoorGpsDayCount: excludedPoorGpsDayCount,
        multiplier: multiplier,
      ),
    );

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

void _validateTruthMutationClaims(
  Map<String, Object?> summary,
  List<String> reasons,
) {
  if (summary['appliesToPastTrips'] != false ||
      summary['calibrationCanSetGlobalTruth'] != false ||
      summary['calibrationCanChangeGlobalTruth'] != false ||
      summary['calibrationCanConfirmOfficialMileage'] != false ||
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
}

void _validateRemoteApplyClaims(
  Map<String, Object?> summary,
  List<String> reasons,
) {
  if (summary['mapboxRouteDistanceCanBecomeOfficial'] != false ||
      summary['firestoreCanApplyCalibration'] != false ||
      summary['mapboxCanApplyCalibration'] != false ||
      summary['cloudFunctionCanApplyCalibration'] != false ||
      summary['importedFileCanApplyCalibration'] != false ||
      summary['dashboardCacheCanApplyCalibration'] != false ||
      summary['remoteCalibrationCanOverrideLocalState'] != false) {
    reasons.add('remote_or_map_can_apply_calibration');
  }
}

void _validateReviewBoundaryClaims(
  Map<String, Object?> summary,
  List<String> reasons,
) {
  if (summary['gpsAssistedTrackingConsentRequired'] != true ||
      summary['separateCalibrationOptInRequired'] != false ||
      summary['reviewAcceptanceRequiredForAdvisoryProjection'] != false ||
      summary['automaticLocalAdvisoryCalibrationEnabledByGpsConsent'] != true ||
      summary['requiresMultipleReviewedOdometerDays'] != true ||
      summary['continuousCalibrationAverageRequired'] != true ||
      summary['poorGpsDaysExcludedFromCalibration'] != true ||
      summary['calibrationRequiresTrustedGpsWindow'] != true ||
      summary['excludedPoorGpsDayCountIncluded'] != true ||
      summary['poorGpsExcludedDayCountTrustedAfterValidationOnly'] != true ||
      summary['gpsDependabilityRollupRequiredForCalibration'] != true ||
      summary['oneGoodGpsWindowCannotClearBadCalibrationDay'] != true ||
      summary['poorGpsWindowExcludesCalibrationDay'] != true ||
      summary['interruptedGpsWindowExcludesCalibrationDay'] != true ||
      summary['unsafeGpsWindowExcludesCalibrationDay'] != true ||
      summary['poorGpsDaysCannotCountAsTrustedWindow'] != true ||
      summary['unknownSignalDiagnosticsCannotCountAsTrustedWindow'] != true ||
      summary['unknownSignalDiagnosticsExcludedByDefault'] != true ||
      summary['excludedPoorGpsCannotBecomeCalibrationProof'] != true ||
      summary['singleDayCalibrationRejected'] != true ||
      summary['calibrationAverageVehicleScoped'] != true ||
      summary['latestReviewTimestampRequired'] != true ||
      summary['staleCalibrationReviewRejected'] != true ||
      summary['excessiveHistoryCountRejected'] != true ||
      summary['settingsCanDisableCalibrationAssist'] != true ||
      summary['settingsCanResetCalibrationPrompt'] != true) {
    reasons.add('calibration_review_boundary_missing');
  }
}

void _validateOdometerTruthClaims(
  Map<String, Object?> summary,
  List<String> reasons,
) {
  if (summary['odometerIsGlobalTruth'] != true ||
      summary['odometerRemainsCanonical'] != true ||
      summary['physicalOdometerIsCanonical'] != true ||
      summary['userConfirmedOdometerReviewCanSetTruth'] != true ||
      summary['firebaseMirrorCanOverrideOdometer'] != false ||
      summary['cloudFunctionCanOverrideOdometer'] != false ||
      summary['mapboxCanOverrideOdometer'] != false ||
      summary['gpsCanOverrideOdometer'] != false ||
      summary['importedFileCanOverrideOdometer'] != false ||
      summary['localCacheCanOverrideOdometer'] != false ||
      summary['sensorFusionCanOverrideOdometer'] != false ||
      summary['calibrationAppliesToFutureGpsProjectionOnly'] != true ||
      summary['calibrationRequiresAcceptedReview'] != true ||
      summary['gpsEstimateRemainsNonCanonical'] != true ||
      summary['tireOrSpeedometerReviewIsAdvisory'] != true ||
      summary['tireChangeDoesNotCreateMaintenanceEntry'] != true ||
      summary['calibrationCanLowerConfirmedOdometer'] != false ||
      summary['calibrationCanCreateMaintenanceRecord'] != false) {
    reasons.add('odometer_truth_boundary_missing');
  }
}

void _validatePromptControlClaims(
  Map<String, Object?> summary,
  List<String> reasons,
) {
  if (summary['remoteCalibrationCanEnableSetting'] != false ||
      summary['remoteCalibrationCanResetPrompt'] != false ||
      summary['mapboxCanTriggerTirePrompt'] != false ||
      summary['gpsCanAutoApplyCalibration'] != false) {
    reasons.add('remote_or_sensor_can_control_prompt');
  }
}

void _validateSensitiveSummaryClaims(
  Map<String, Object?> summary,
  List<String> reasons,
) {
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
}

List<String> _calibrationStatusBoundaryRisks({
  required TripTrackingCalibrationApplyStatus? status,
  required List<String>? reasonCodes,
  required bool canApplyToFutureGpsProjection,
  required int? trustedGpsWindowCount,
  required int? excludedPoorGpsDayCount,
  required Object? multiplier,
}) {
  if (status == null ||
      reasonCodes == null ||
      trustedGpsWindowCount == null ||
      excludedPoorGpsDayCount == null ||
      multiplier is! num) {
    return const [];
  }
  final risks = <String>[];
  if (excludedPoorGpsDayCount > 0 && canApplyToFutureGpsProjection) {
    risks.add('excluded_poor_gps_cannot_apply_calibration');
  }
  switch (status) {
    case TripTrackingCalibrationApplyStatus.disabled:
      if (canApplyToFutureGpsProjection ||
          !reasonCodes.contains('calibration_user_opt_in_required')) {
        risks.add('calibration_disabled_authority_mismatch');
      }
    case TripTrackingCalibrationApplyStatus.waitingForHistory:
      if (canApplyToFutureGpsProjection ||
          !reasonCodes.contains('more_reviewed_odometer_days_required')) {
        risks.add('calibration_waiting_authority_mismatch');
      }
    case TripTrackingCalibrationApplyStatus.reviewRequired:
      if (canApplyToFutureGpsProjection ||
          !reasonCodes.contains('user_must_accept_calibration_review')) {
        risks.add('calibration_review_required_authority_mismatch');
      }
    case TripTrackingCalibrationApplyStatus.readyForFutureProjection:
      if (!canApplyToFutureGpsProjection ||
          trustedGpsWindowCount <= 0 ||
          multiplier < 0.8 ||
          multiplier > 1.25) {
        risks.add('calibration_ready_authority_mismatch');
      }
    case TripTrackingCalibrationApplyStatus.rejected:
      if (canApplyToFutureGpsProjection || reasonCodes.isEmpty) {
        risks.add('calibration_rejected_authority_mismatch');
      }
  }
  return risks;
}

TripTrackingCalibrationApplyStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripTrackingCalibrationApplyStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

List<String>? _safeReasonCodes(Object? value) {
  if (value is! List) return null;
  final safe = <String>[];
  for (final reason in value) {
    final code = _safeApplyReason(reason);
    if (code == null) return null;
    safe.add(code);
  }
  return List.unmodifiable(safe);
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
    'inconsistent_calibration_review_signal' => value,
    'calibration_review_difference_too_small' => value,
    'inconsistent_stable_calibration_signal' => value,
    'inconsistent_insufficient_history_signal' => value,
    'future_review_timestamp' => value,
    'missing_latest_review_timestamp' => value,
    'stale_review_timestamp' => value,
    'local_reviewed_odometer_history_required' => value,
    'gps_dependability_rollup_required_for_calibration' => value,
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

int? _safeSummaryCount(Object? value) {
  return value is int && value >= 0 && value <= 366 ? value : null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
