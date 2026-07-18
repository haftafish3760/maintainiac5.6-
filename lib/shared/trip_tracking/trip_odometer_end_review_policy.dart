import 'trip_odometer_calibration_prompt_policy.dart';
import 'trip_tracking_odometer_usage_anomaly.dart';
import 'trip_tracking_odometer_reconciliation.dart';

enum TripOdometerEndReviewStatus {
  readyToConfirm,
  reviewRecommended,
  blockedInvalidEntry,
}

class TripOdometerEndReviewDecision {
  const TripOdometerEndReviewDecision({
    required this.status,
    required this.reasonCode,
    required this.entryValidation,
    required this.reconciliation,
    required this.calibrationPrompt,
    this.usageAnomaly,
    required this.canConfirmOdometer,
    required this.shouldShowReviewBeforeConfirm,
  });

  final TripOdometerEndReviewStatus status;
  final String reasonCode;
  final TripOdometerEntryValidation entryValidation;
  final TripOdometerReconciliation reconciliation;
  final TripOdometerCalibrationPromptDecision calibrationPrompt;
  final TripOdometerUsageAnomalySignal? usageAnomaly;
  final bool canConfirmOdometer;
  final bool shouldShowReviewBeforeConfirm;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'canConfirmOdometer': canConfirmOdometer,
    'shouldShowReviewBeforeConfirm': shouldShowReviewBeforeConfirm,
    'entryValidation': entryValidation.toSafeDashboardMap(),
    'reconciliation': reconciliation.toSafeDashboardMap(),
    'calibrationPrompt': calibrationPrompt.toSafeDashboardMap(),
    'usageAnomaly': usageAnomaly?.toSafeDashboardMap(),
    'odometerIsGlobalTruth': true,
    'odometerRemainsOfficialMileageTruth': true,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'calibrationCanCreateOfficialMileage': false,
    'gpsCanSuggestReviewOnly': true,
    'gpsCanConfirmOdometer': false,
    'mapboxCanConfirmOdometer': false,
    'firestoreCanConfirmOdometer': false,
    'cloudFunctionCanConfirmOdometer': false,
    'remoteTotalsCanBecomeCanonical': false,
    'calibrationCanApplySilently': false,
    'confirmedMileageRequiresUserAction': true,
    'userAcknowledgementCannotRewriteOdometer': true,
    'reviewAcknowledgementOnlyAllowsManualConfirm': true,
    'remoteReviewAcknowledgementRejected': true,
    'usageAnomalyCanConfirmOdometer': false,
    'usageAnomalyCanCorrectOdometer': false,
    'usageAnomalyRequiresOptIn': true,
    'usageAnomalyReviewRequiresUserAction':
        usageAnomaly?.shouldPromptUser ?? false,
    'invalidEntryFailsClosed': true,
    'dashboardMayShowLiveProjection': true,
    'dashboardProjectionIsNotOfficialMileage': true,
    'rawTripRecordsIncluded': false,
    'rawLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripOdometerEndReviewPolicy {
  const TripOdometerEndReviewPolicy._();

  static TripOdometerEndReviewDecision evaluate({
    required TripOdometerEntryValidation entryValidation,
    required TripOdometerReconciliation reconciliation,
    required TripOdometerCalibrationPromptDecision calibrationPrompt,
    TripOdometerUsageAnomalySignal? usageAnomaly,
    bool userAcknowledgedReviewPrompt = false,
    bool userAcknowledgedUsageAnomaly = false,
  }) {
    if (entryValidation.shouldBlockConfirmation ||
        reconciliation.status == TripOdometerReconciliationStatus.invalid ||
        usageAnomaly?.status == TripOdometerUsageAnomalyStatus.invalid) {
      return _decision(
        status: TripOdometerEndReviewStatus.blockedInvalidEntry,
        reasonCode: _blockedReason(
          entryValidation: entryValidation,
          reconciliation: reconciliation,
          usageAnomaly: usageAnomaly,
        ),
        entryValidation: entryValidation,
        reconciliation: reconciliation,
        calibrationPrompt: calibrationPrompt,
        usageAnomaly: usageAnomaly,
        canConfirmOdometer: false,
        shouldShowReviewBeforeConfirm: true,
      );
    }

    final usageReviewNeeded =
        usageAnomaly?.shouldPromptUser == true && !userAcknowledgedUsageAnomaly;
    final reviewNeeded =
        entryValidation.shouldPromptUser ||
        reconciliation.shouldPromptUser ||
        calibrationPrompt.shouldShow ||
        usageReviewNeeded;
    if (reviewNeeded && !userAcknowledgedReviewPrompt) {
      return _decision(
        status: TripOdometerEndReviewStatus.reviewRecommended,
        reasonCode: _reviewReason(
          entryValidation,
          reconciliation,
          calibrationPrompt,
          usageAnomaly,
          usageReviewNeeded,
        ),
        entryValidation: entryValidation,
        reconciliation: reconciliation,
        calibrationPrompt: calibrationPrompt,
        usageAnomaly: usageAnomaly,
        canConfirmOdometer: true,
        shouldShowReviewBeforeConfirm: true,
      );
    }

    return _decision(
      status: TripOdometerEndReviewStatus.readyToConfirm,
      reasonCode: userAcknowledgedReviewPrompt
          ? 'review_acknowledged_ready_to_confirm'
          : 'odometer_ready_to_confirm',
      entryValidation: entryValidation,
      reconciliation: reconciliation,
      calibrationPrompt: calibrationPrompt,
      usageAnomaly: usageAnomaly,
      canConfirmOdometer: true,
      shouldShowReviewBeforeConfirm: false,
    );
  }
}

TripOdometerEndReviewDecision _decision({
  required TripOdometerEndReviewStatus status,
  required String reasonCode,
  required TripOdometerEntryValidation entryValidation,
  required TripOdometerReconciliation reconciliation,
  required TripOdometerCalibrationPromptDecision calibrationPrompt,
  TripOdometerUsageAnomalySignal? usageAnomaly,
  required bool canConfirmOdometer,
  required bool shouldShowReviewBeforeConfirm,
}) {
  return TripOdometerEndReviewDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    entryValidation: entryValidation,
    reconciliation: reconciliation,
    calibrationPrompt: calibrationPrompt,
    usageAnomaly: usageAnomaly,
    canConfirmOdometer: canConfirmOdometer,
    shouldShowReviewBeforeConfirm: shouldShowReviewBeforeConfirm,
  );
}

String _blockedReason({
  required TripOdometerEntryValidation entryValidation,
  required TripOdometerReconciliation reconciliation,
  TripOdometerUsageAnomalySignal? usageAnomaly,
}) {
  if (entryValidation.shouldBlockConfirmation) {
    return entryValidation.reasonCode;
  }
  if (reconciliation.status == TripOdometerReconciliationStatus.invalid) {
    return 'invalid_gps_odometer_reconciliation';
  }
  if (usageAnomaly?.status == TripOdometerUsageAnomalyStatus.invalid) {
    return 'invalid_usage_anomaly_input';
  }
  return 'invalid_odometer_entry_input';
}

String _reviewReason(
  TripOdometerEntryValidation entryValidation,
  TripOdometerReconciliation reconciliation,
  TripOdometerCalibrationPromptDecision calibrationPrompt,
  TripOdometerUsageAnomalySignal? usageAnomaly,
  bool usageReviewNeeded,
) {
  if (entryValidation.shouldPromptUser) {
    return entryValidation.reasonCode;
  }
  if (usageReviewNeeded && usageAnomaly != null) {
    return usageAnomaly.reasonCode;
  }
  if (reconciliation.shouldPromptUser) {
    return 'gps_odometer_difference_review';
  }
  if (calibrationPrompt.shouldShow) return 'calibration_prompt_review';
  return 'odometer_ready_to_confirm';
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'invalid_odometer_entry_input' => 'invalid_odometer_entry_input',
    'ending_odometer_below_starting_odometer' =>
      'ending_odometer_below_starting_odometer',
    'starting_odometer_below_previous_confirmed_ending' =>
      'starting_odometer_below_previous_confirmed_ending',
    'large_untracked_odometer_gap' => 'large_untracked_odometer_gap',
    'unusually_high_odometer_delta' => 'unusually_high_odometer_delta',
    'unusually_low_odometer_delta' => 'unusually_low_odometer_delta',
    'invalid_usage_anomaly_input' => 'invalid_usage_anomaly_input',
    'needs_more_reviewed_days_for_usage_anomaly' =>
      'needs_more_reviewed_days_for_usage_anomaly',
    'odometer_usage_within_review_threshold' =>
      'odometer_usage_within_review_threshold',
    'gps_odometer_difference_review' => 'gps_odometer_difference_review',
    'calibration_prompt_review' => 'calibration_prompt_review',
    'invalid_gps_odometer_reconciliation' =>
      'invalid_gps_odometer_reconciliation',
    'review_acknowledged_ready_to_confirm' =>
      'review_acknowledged_ready_to_confirm',
    'odometer_ready_to_confirm' => 'odometer_ready_to_confirm',
    _ => 'invalid_odometer_entry_input',
  };
}
