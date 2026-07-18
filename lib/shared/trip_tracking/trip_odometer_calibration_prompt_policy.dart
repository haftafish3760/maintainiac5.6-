import 'trip_tracking_odometer_calibration.dart';

enum TripOdometerCalibrationPromptSurface { hidden, quietChip, reviewBanner }

enum TripOdometerCalibrationPromptReason {
  disabledByUser,
  invalidSignal,
  noPromptNeeded,
  snoozed,
  needsMoreReviewedDays,
  tireOrSpeedometerReview,
  gpsAssistReview,
}

class TripOdometerCalibrationPromptDecision {
  const TripOdometerCalibrationPromptDecision({
    required this.surface,
    required this.reason,
    required this.shouldShow,
    required this.canApplyAutomatically,
    required this.canSnooze,
    required this.canDisable,
    required this.messageToken,
  });

  final TripOdometerCalibrationPromptSurface surface;
  final TripOdometerCalibrationPromptReason reason;
  final bool shouldShow;
  final bool canApplyAutomatically;
  final bool canSnooze;
  final bool canDisable;
  final String messageToken;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'surface': surface.name,
    'reason': reason.name,
    'shouldShow': shouldShow,
    'canApplyAutomatically': false,
    'canSnooze': canSnooze,
    'canDisable': canDisable,
    'messageToken': _safeMessage(messageToken),
    'calibrationRequiresUserOptIn': true,
    'calibrationRequiresMultipleReviewedTrips': true,
    'continuousCalibrationAverageRequired': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'calibrationRequiresTrustedGpsWindow': true,
    'singleDayCalibrationRejected': true,
    'calibrationRequiresReviewedLocalHistory': true,
    'calibrationRequiresVehicleMatchedHistory': true,
    'calibrationRequiresOwnershipValidation': true,
    'calibrationRequiresDaytimeLocalSource': true,
    'calibrationRequiresManualUserConfirmation': true,
    'calibrationPromptRequiresFreshLocalEvaluation': true,
    'calibrationAppliesToFutureGpsAssistanceOnly': true,
    'calibrationCanRewritePastTrips': false,
    'calibrationCanSetGlobalTruth': false,
    'calibrationCanChangeGlobalTruth': false,
    'calibrationCanConfirmOfficialMileage': false,
    'calibrationCanReplaceConfirmedOdometer': false,
    'calibrationCanLowerConfirmedOdometer': false,
    'calibrationCanCreateMaintenanceRecord': false,
    'gpsCanReplaceOdometerSilently': false,
    'mapboxCanReplaceOdometerSilently': false,
    'odometerIsGlobalTruth': true,
    'odometerRemainsOfficialMileageTruth': true,
    'physicalOdometerRequiredForOfficialMileage': true,
    'confirmedOdometerOverridesExternalMileage': true,
    'externalMileageCannotBecomeGlobalTruth': true,
    'gpsDistanceCanOnlyAdviseMileageReview': true,
    'mapMatchingCanOnlyAdviseMileageReview': true,
    'optimizationCannotChangeOfficialMileage': true,
    'tirePromptIsAdvisoryOnly': true,
    'tirePromptDoesNotCreateMaintenanceEntry': true,
    'tireSizeReviewSuggested':
        reason == TripOdometerCalibrationPromptReason.tireOrSpeedometerReview,
    'speedometerCalibrationReviewSuggested':
        reason == TripOdometerCalibrationPromptReason.tireOrSpeedometerReview,
    'remoteHistoryCanTriggerPromptWithoutLocalValidation': false,
    'authenticationAloneAuthorizesCalibration': false,
    'firestoreCanApplyCalibration': false,
    'cloudFunctionCanApplyCalibration': false,
    'mapboxCanApplyCalibration': false,
    'importedFileCanApplyCalibration': false,
    'remoteCalibrationCanEnableSetting': false,
    'remoteCalibrationCanResetPrompt': false,
    'mapboxCanTriggerTirePrompt': false,
    'gpsCanAutoApplyCalibration': false,
    'rawReviewedTripsIncluded': false,
    'rawGpsIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };
}

class TripOdometerCalibrationPromptSummaryValidation {
  const TripOdometerCalibrationPromptSummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripOdometerCalibrationPromptSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (_safeSurface(summary['surface']) == null) {
      reasons.add('invalid_prompt_surface');
    }
    if (_safePromptReason(summary['reason']) == null) {
      reasons.add('invalid_prompt_reason');
    }
    for (final key in const [
      'shouldShow',
      'canApplyAutomatically',
      'canSnooze',
      'canDisable',
      'calibrationRequiresUserOptIn',
      'calibrationRequiresMultipleReviewedTrips',
      'continuousCalibrationAverageRequired',
      'poorGpsDaysExcludedFromCalibration',
      'calibrationRequiresTrustedGpsWindow',
      'singleDayCalibrationRejected',
      'calibrationRequiresReviewedLocalHistory',
      'calibrationRequiresVehicleMatchedHistory',
      'calibrationRequiresOwnershipValidation',
      'calibrationRequiresDaytimeLocalSource',
      'calibrationRequiresManualUserConfirmation',
      'calibrationPromptRequiresFreshLocalEvaluation',
      'calibrationAppliesToFutureGpsAssistanceOnly',
      'calibrationCanRewritePastTrips',
      'calibrationCanSetGlobalTruth',
      'calibrationCanChangeGlobalTruth',
      'calibrationCanConfirmOfficialMileage',
      'calibrationCanReplaceConfirmedOdometer',
      'calibrationCanLowerConfirmedOdometer',
      'calibrationCanCreateMaintenanceRecord',
      'gpsCanReplaceOdometerSilently',
      'mapboxCanReplaceOdometerSilently',
      'odometerIsGlobalTruth',
      'odometerRemainsOfficialMileageTruth',
      'physicalOdometerRequiredForOfficialMileage',
      'confirmedOdometerOverridesExternalMileage',
      'externalMileageCannotBecomeGlobalTruth',
      'gpsDistanceCanOnlyAdviseMileageReview',
      'mapMatchingCanOnlyAdviseMileageReview',
      'optimizationCannotChangeOfficialMileage',
      'tirePromptIsAdvisoryOnly',
      'tirePromptDoesNotCreateMaintenanceEntry',
      'tireSizeReviewSuggested',
      'speedometerCalibrationReviewSuggested',
      'remoteHistoryCanTriggerPromptWithoutLocalValidation',
      'authenticationAloneAuthorizesCalibration',
      'firestoreCanApplyCalibration',
      'cloudFunctionCanApplyCalibration',
      'mapboxCanApplyCalibration',
      'importedFileCanApplyCalibration',
      'remoteCalibrationCanEnableSetting',
      'remoteCalibrationCanResetPrompt',
      'mapboxCanTriggerTirePrompt',
      'gpsCanAutoApplyCalibration',
      'rawReviewedTripsIncluded',
      'rawGpsIncluded',
      'preciseLocationIncluded',
      'tokensIncluded',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (_safeMessage(summary['messageToken']?.toString() ?? '') !=
        summary['messageToken']) {
      reasons.add('invalid_prompt_message');
    }
    if (summary['canApplyAutomatically'] != false ||
        summary['calibrationRequiresUserOptIn'] != true ||
        summary['calibrationRequiresMultipleReviewedTrips'] != true ||
        summary['continuousCalibrationAverageRequired'] != true ||
        summary['poorGpsDaysExcludedFromCalibration'] != true ||
        summary['calibrationRequiresTrustedGpsWindow'] != true ||
        summary['singleDayCalibrationRejected'] != true ||
        summary['calibrationRequiresReviewedLocalHistory'] != true ||
        summary['calibrationRequiresVehicleMatchedHistory'] != true ||
        summary['calibrationRequiresOwnershipValidation'] != true ||
        summary['calibrationRequiresDaytimeLocalSource'] != true ||
        summary['calibrationRequiresManualUserConfirmation'] != true ||
        summary['calibrationPromptRequiresFreshLocalEvaluation'] != true ||
        summary['calibrationAppliesToFutureGpsAssistanceOnly'] != true) {
      reasons.add('calibration_review_boundary_missing');
    }
    if (summary['calibrationCanRewritePastTrips'] != false ||
        summary['calibrationCanSetGlobalTruth'] != false ||
        summary['calibrationCanChangeGlobalTruth'] != false ||
        summary['calibrationCanConfirmOfficialMileage'] != false ||
        summary['calibrationCanReplaceConfirmedOdometer'] != false ||
        summary['calibrationCanLowerConfirmedOdometer'] != false ||
        summary['calibrationCanCreateMaintenanceRecord'] != false ||
        summary['gpsCanReplaceOdometerSilently'] != false ||
        summary['mapboxCanReplaceOdometerSilently'] != false ||
        summary['odometerIsGlobalTruth'] != true ||
        summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['physicalOdometerRequiredForOfficialMileage'] != true ||
        summary['confirmedOdometerOverridesExternalMileage'] != true ||
        summary['externalMileageCannotBecomeGlobalTruth'] != true ||
        summary['gpsDistanceCanOnlyAdviseMileageReview'] != true ||
        summary['mapMatchingCanOnlyAdviseMileageReview'] != true ||
        summary['optimizationCannotChangeOfficialMileage'] != true ||
        summary['tirePromptIsAdvisoryOnly'] != true ||
        summary['tirePromptDoesNotCreateMaintenanceEntry'] != true) {
      reasons.add('calibration_can_replace_odometer');
    }
    if (summary['remoteHistoryCanTriggerPromptWithoutLocalValidation'] !=
            false ||
        summary['authenticationAloneAuthorizesCalibration'] != false ||
        summary['firestoreCanApplyCalibration'] != false ||
        summary['cloudFunctionCanApplyCalibration'] != false ||
        summary['mapboxCanApplyCalibration'] != false ||
        summary['importedFileCanApplyCalibration'] != false ||
        summary['remoteCalibrationCanEnableSetting'] != false ||
        summary['remoteCalibrationCanResetPrompt'] != false ||
        summary['mapboxCanTriggerTirePrompt'] != false ||
        summary['gpsCanAutoApplyCalibration'] != false) {
      reasons.add('remote_can_apply_calibration');
    }
    if (summary['rawReviewedTripsIncluded'] != false ||
        summary['rawGpsIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_calibration_material');
    }

    return TripOdometerCalibrationPromptSummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
}

class TripOdometerCalibrationPromptPolicy {
  const TripOdometerCalibrationPromptPolicy._();

  static TripOdometerCalibrationPromptDecision evaluate({
    required TripOdometerCalibrationSignal signal,
    required bool userEnabledCalibrationAssist,
    required bool userDismissedPrompt,
    required DateTime? snoozedUntilUtc,
    required DateTime nowUtc,
    int quietChipMinimumSamples = 3,
  }) {
    final safeQuietChipMinimumSamples = quietChipMinimumSamples.clamp(1, 30);
    if (!userEnabledCalibrationAssist) {
      return _hidden(
        TripOdometerCalibrationPromptReason.disabledByUser,
        'calibration_assist_disabled',
      );
    }
    if (!_safeSignal(signal)) {
      return _hidden(
        TripOdometerCalibrationPromptReason.invalidSignal,
        'calibration_signal_invalid',
      );
    }
    final now = nowUtc.toUtc();
    final snooze = snoozedUntilUtc?.toUtc();
    if (snooze != null && snooze.isAfter(now)) {
      return _hidden(
        TripOdometerCalibrationPromptReason.snoozed,
        'calibration_prompt_snoozed',
      );
    }
    if (userDismissedPrompt &&
        signal.status == TripOdometerCalibrationStatus.stable) {
      return _hidden(
        TripOdometerCalibrationPromptReason.noPromptNeeded,
        'calibration_stable',
      );
    }
    if (signal.status == TripOdometerCalibrationStatus.insufficientHistory) {
      if (signal.eligibleSampleCount >= safeQuietChipMinimumSamples) {
        return const TripOdometerCalibrationPromptDecision(
          surface: TripOdometerCalibrationPromptSurface.quietChip,
          reason: TripOdometerCalibrationPromptReason.needsMoreReviewedDays,
          shouldShow: true,
          canApplyAutomatically: false,
          canSnooze: true,
          canDisable: true,
          messageToken: 'calibration_learning_more_days',
        );
      }
      return _hidden(
        TripOdometerCalibrationPromptReason.needsMoreReviewedDays,
        'calibration_needs_more_reviewed_days',
      );
    }
    if (!signal.shouldPromptUser) {
      return _hidden(
        TripOdometerCalibrationPromptReason.noPromptNeeded,
        'calibration_stable',
      );
    }
    return TripOdometerCalibrationPromptDecision(
      surface: TripOdometerCalibrationPromptSurface.reviewBanner,
      reason: signal.maySuggestTireOrSpeedometerReview
          ? TripOdometerCalibrationPromptReason.tireOrSpeedometerReview
          : TripOdometerCalibrationPromptReason.gpsAssistReview,
      shouldShow: true,
      canApplyAutomatically: false,
      canSnooze: true,
      canDisable: true,
      messageToken: signal.maySuggestTireOrSpeedometerReview
          ? 'review_tires_or_speedometer'
          : 'review_gps_assist_calibration',
    );
  }
}

TripOdometerCalibrationPromptDecision _hidden(
  TripOdometerCalibrationPromptReason reason,
  String messageToken,
) {
  return TripOdometerCalibrationPromptDecision(
    surface: TripOdometerCalibrationPromptSurface.hidden,
    reason: reason,
    shouldShow: false,
    canApplyAutomatically: false,
    canSnooze: false,
    canDisable: true,
    messageToken: messageToken,
  );
}

String _safeMessage(String value) {
  final clean = value.trim();
  return switch (clean) {
    'calibration_assist_disabled' ||
    'calibration_prompt_snoozed' ||
    'calibration_signal_invalid' ||
    'calibration_stable' ||
    'calibration_learning_more_days' ||
    'calibration_needs_more_reviewed_days' ||
    'review_tires_or_speedometer' ||
    'review_gps_assist_calibration' => clean,
    _ => 'calibration_stable',
  };
}

bool _safeSignal(TripOdometerCalibrationSignal signal) {
  if (signal.eligibleSampleCount < 0 || signal.eligibleSampleCount > 366) {
    return false;
  }
  if (!signal.averageGpsToOdometerRatio.isFinite ||
      signal.averageGpsToOdometerRatio <= 0) {
    return false;
  }
  if (!signal.averageDifferencePercent.isFinite ||
      signal.averageDifferencePercent < 0) {
    return false;
  }
  return _safeSignalReason(signal.reasonCode) != 'unknown_calibration_state';
}

String _safeSignalReason(String value) {
  return switch (value.trim()) {
    'invalid_calibration_threshold' => value.trim(),
    'needs_more_reviewed_days' => value.trim(),
    'mixed_vehicle_calibration_history' => value.trim(),
    'persistent_gps_odometer_drift' => value.trim(),
    'calibration_stable' => value.trim(),
    _ => 'unknown_calibration_state',
  };
}

TripOdometerCalibrationPromptSurface? _safeSurface(Object? value) {
  if (value is! String) return null;
  for (final surface in TripOdometerCalibrationPromptSurface.values) {
    if (surface.name == value) return surface;
  }
  return null;
}

TripOdometerCalibrationPromptReason? _safePromptReason(Object? value) {
  if (value is! String) return null;
  for (final reason in TripOdometerCalibrationPromptReason.values) {
    if (reason.name == value) return reason;
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
