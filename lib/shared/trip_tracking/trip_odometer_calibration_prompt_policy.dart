import 'trip_tracking_odometer_calibration.dart';

enum TripOdometerCalibrationPromptSurface { hidden, quietChip, reviewBanner }

enum TripOdometerCalibrationPromptReason {
  disabledByUser,
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
    'calibrationAppliesToFutureGpsAssistanceOnly': true,
    'calibrationCanRewritePastTrips': false,
    'calibrationCanReplaceConfirmedOdometer': false,
    'gpsCanReplaceOdometerSilently': false,
    'mapboxCanReplaceOdometerSilently': false,
    'odometerRemainsOfficialMileageTruth': true,
    'tireSizeReviewSuggested':
        reason == TripOdometerCalibrationPromptReason.tireOrSpeedometerReview,
    'speedometerCalibrationReviewSuggested':
        reason == TripOdometerCalibrationPromptReason.tireOrSpeedometerReview,
    'remoteHistoryCanTriggerPromptWithoutLocalValidation': false,
    'firestoreCanApplyCalibration': false,
    'mapboxCanApplyCalibration': false,
    'rawReviewedTripsIncluded': false,
    'rawGpsIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };
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
    if (!userEnabledCalibrationAssist) {
      return _hidden(
        TripOdometerCalibrationPromptReason.disabledByUser,
        'calibration_assist_disabled',
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
      if (signal.eligibleSampleCount >= quietChipMinimumSamples) {
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
    'calibration_stable' ||
    'calibration_learning_more_days' ||
    'calibration_needs_more_reviewed_days' ||
    'review_tires_or_speedometer' ||
    'review_gps_assist_calibration' => clean,
    _ => 'calibration_stable',
  };
}
