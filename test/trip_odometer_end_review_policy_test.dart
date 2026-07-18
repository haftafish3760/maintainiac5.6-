import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_odometer_calibration_prompt_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_odometer_end_review_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_reconciliation.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_usage_anomaly.dart';

void main() {
  const aligned = TripOdometerReconciliation(
    status: TripOdometerReconciliationStatus.aligned,
    confirmedOdometerDeltaMiles: 120,
    filteredGpsMiles: 118,
    absoluteDifferenceMiles: 2,
    differencePercent: 1.7,
  );
  const reviewDiff = TripOdometerReconciliation(
    status: TripOdometerReconciliationStatus.reviewRecommended,
    confirmedOdometerDeltaMiles: 120,
    filteredGpsMiles: 100,
    absoluteDifferenceMiles: 20,
    differencePercent: 16.7,
  );
  const invalidRecon = TripOdometerReconciliation(
    status: TripOdometerReconciliationStatus.invalid,
    confirmedOdometerDeltaMiles: 0,
    filteredGpsMiles: 0,
    absoluteDifferenceMiles: 0,
    differencePercent: 0,
  );

  TripOdometerCalibrationPromptDecision prompt({bool visible = false}) {
    return visible
        ? const TripOdometerCalibrationPromptDecision(
            surface: TripOdometerCalibrationPromptSurface.reviewBanner,
            reason: TripOdometerCalibrationPromptReason.tireOrSpeedometerReview,
            shouldShow: true,
            canApplyAutomatically: false,
            canSnooze: true,
            canDisable: true,
            messageToken: 'review_tires_or_speedometer',
          )
        : const TripOdometerCalibrationPromptDecision(
            surface: TripOdometerCalibrationPromptSurface.hidden,
            reason: TripOdometerCalibrationPromptReason.noPromptNeeded,
            shouldShow: false,
            canApplyAutomatically: false,
            canSnooze: false,
            canDisable: true,
            messageToken: 'calibration_stable',
          );
  }

  test('valid odometer and aligned GPS is ready for user confirmation', () {
    final entry = TripOdometerEntryValidation.validate(
      startingOdometer: 1000,
      endingOdometer: 1120,
      previousConfirmedEndingOdometer: 1000,
      averageDailyMiles: 110,
    );
    final decision = TripOdometerEndReviewPolicy.evaluate(
      entryValidation: entry,
      reconciliation: aligned,
      calibrationPrompt: prompt(),
    );

    expect(decision.status, TripOdometerEndReviewStatus.readyToConfirm);
    expect(decision.canConfirmOdometer, isTrue);
    expect(decision.shouldShowReviewBeforeConfirm, isFalse);
  });

  test('ending odometer below starting blocks confirmation closed', () {
    final entry = TripOdometerEntryValidation.validate(
      startingOdometer: 1120,
      endingOdometer: 1100,
      previousConfirmedEndingOdometer: 1000,
    );
    final decision = TripOdometerEndReviewPolicy.evaluate(
      entryValidation: entry,
      reconciliation: aligned,
      calibrationPrompt: prompt(),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripOdometerEndReviewStatus.blockedInvalidEntry);
    expect(decision.canConfirmOdometer, isFalse);
    expect(safe['invalidEntryFailsClosed'], isTrue);
    expect(safe['gpsCanConfirmOdometer'], isFalse);
  });

  test('GPS difference recommends review but still leaves user in control', () {
    final entry = TripOdometerEntryValidation.validate(
      startingOdometer: 1000,
      endingOdometer: 1120,
      previousConfirmedEndingOdometer: 1000,
      averageDailyMiles: 120,
    );
    final decision = TripOdometerEndReviewPolicy.evaluate(
      entryValidation: entry,
      reconciliation: reviewDiff,
      calibrationPrompt: prompt(),
    );

    expect(decision.status, TripOdometerEndReviewStatus.reviewRecommended);
    expect(decision.reasonCode, 'gps_odometer_difference_review');
    expect(decision.canConfirmOdometer, isTrue);
    expect(decision.shouldShowReviewBeforeConfirm, isTrue);
  });

  test(
    'acknowledged review becomes ready without letting GPS rewrite miles',
    () {
      final entry = TripOdometerEntryValidation.validate(
        startingOdometer: 1000,
        endingOdometer: 1120,
        previousConfirmedEndingOdometer: 1000,
        averageDailyMiles: 120,
      );
      final decision = TripOdometerEndReviewPolicy.evaluate(
        entryValidation: entry,
        reconciliation: reviewDiff,
        calibrationPrompt: prompt(visible: true),
        userAcknowledgedReviewPrompt: true,
      );
      final safe = decision.toSafeDashboardMap();

      expect(decision.status, TripOdometerEndReviewStatus.readyToConfirm);
      expect(decision.reasonCode, 'review_acknowledged_ready_to_confirm');
      expect(safe['remoteTotalsCanBecomeCanonical'], isFalse);
      expect(safe['calibrationCanApplySilently'], isFalse);
    },
  );

  test('calibration prompt asks review but cannot apply automatically', () {
    final entry = TripOdometerEntryValidation.validate(
      startingOdometer: 1000,
      endingOdometer: 1120,
      previousConfirmedEndingOdometer: 1000,
      averageDailyMiles: 120,
    );
    final decision = TripOdometerEndReviewPolicy.evaluate(
      entryValidation: entry,
      reconciliation: aligned,
      calibrationPrompt: prompt(visible: true),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripOdometerEndReviewStatus.reviewRecommended);
    expect(decision.reasonCode, 'calibration_prompt_review');
    expect(safe['calibrationCanApplySilently'], isFalse);
    expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
  });

  test('invalid reconciliation blocks remote or GPS canonical totals', () {
    final entry = TripOdometerEntryValidation.validate(
      startingOdometer: 1000,
      endingOdometer: 1120,
      previousConfirmedEndingOdometer: 1000,
    );
    final decision = TripOdometerEndReviewPolicy.evaluate(
      entryValidation: entry,
      reconciliation: invalidRecon,
      calibrationPrompt: prompt(),
    );

    expect(decision.status, TripOdometerEndReviewStatus.blockedInvalidEntry);
    expect(decision.reasonCode, 'invalid_gps_odometer_reconciliation');
    expect(decision.canConfirmOdometer, isFalse);
  });

  test('usage anomaly recommends review before confirm without correcting', () {
    final entry = TripOdometerEntryValidation.validate(
      startingOdometer: 1000,
      endingOdometer: 1180,
      previousConfirmedEndingOdometer: 1000,
      averageDailyMiles: 40,
    );
    final decision = TripOdometerEndReviewPolicy.evaluate(
      entryValidation: entry,
      reconciliation: aligned,
      calibrationPrompt: prompt(),
      usageAnomaly: usageSignal(
        status: TripOdometerUsageAnomalyStatus.reviewRecommended,
        reasonCode: 'unusually_high_odometer_delta',
      ),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripOdometerEndReviewStatus.reviewRecommended);
    expect(decision.reasonCode, 'unusually_high_odometer_delta');
    expect(decision.canConfirmOdometer, isTrue);
    expect(decision.shouldShowReviewBeforeConfirm, isTrue);
    expect(safe['usageAnomalyCanConfirmOdometer'], isFalse);
    expect(safe['usageAnomalyCanCorrectOdometer'], isFalse);
    expect(safe['usageAnomalyReviewRequiresUserAction'], isTrue);
    expect(
      (safe['usageAnomaly'] as Map<String, Object?>)['rawLocationIncluded'],
      isFalse,
    );
  });

  test('acknowledged usage anomaly can proceed without silent correction', () {
    final entry = TripOdometerEntryValidation.validate(
      startingOdometer: 1000,
      endingOdometer: 1180,
      previousConfirmedEndingOdometer: 1000,
      averageDailyMiles: 40,
    );
    final decision = TripOdometerEndReviewPolicy.evaluate(
      entryValidation: entry,
      reconciliation: aligned,
      calibrationPrompt: prompt(),
      usageAnomaly: usageSignal(
        status: TripOdometerUsageAnomalyStatus.reviewRecommended,
        reasonCode: 'unusually_high_odometer_delta',
      ),
      userAcknowledgedReviewPrompt: true,
      userAcknowledgedUsageAnomaly: true,
    );

    expect(decision.status, TripOdometerEndReviewStatus.readyToConfirm);
    expect(decision.reasonCode, 'review_acknowledged_ready_to_confirm');
    expect(decision.canConfirmOdometer, isTrue);
    expect(decision.shouldShowReviewBeforeConfirm, isFalse);
    expect(
      decision.toSafeDashboardMap()['usageAnomalyCanCorrectOdometer'],
      isFalse,
    );
  });

  test('invalid usage anomaly fails closed at the review boundary', () {
    final entry = TripOdometerEntryValidation.validate(
      startingOdometer: 1000,
      endingOdometer: 1120,
      previousConfirmedEndingOdometer: 1000,
    );
    final decision = TripOdometerEndReviewPolicy.evaluate(
      entryValidation: entry,
      reconciliation: aligned,
      calibrationPrompt: prompt(),
      usageAnomaly: usageSignal(
        status: TripOdometerUsageAnomalyStatus.invalid,
        reasonCode: 'invalid_usage_anomaly_input',
      ),
      userAcknowledgedReviewPrompt: true,
      userAcknowledgedUsageAnomaly: true,
    );

    expect(decision.status, TripOdometerEndReviewStatus.blockedInvalidEntry);
    expect(decision.reasonCode, 'invalid_usage_anomaly_input');
    expect(decision.canConfirmOdometer, isFalse);
  });

  test(
    'safe summary does not expose raw trips, locations, routes, or tokens',
    () {
      final entry = TripOdometerEntryValidation.validate(
        startingOdometer: 1000,
        endingOdometer: 1120,
        previousConfirmedEndingOdometer: 1000,
      );
      final safe = TripOdometerEndReviewPolicy.evaluate(
        entryValidation: entry,
        reconciliation: aligned,
        calibrationPrompt: prompt(),
      ).toSafeDashboardMap();

      expect(safe['rawTripRecordsIncluded'], isFalse);
      expect(safe['rawLocationIncluded'], isFalse);
      expect(safe['routeGeometryIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
      expect(safe['confirmedMileageRequiresUserAction'], isTrue);
    },
  );
}

TripOdometerUsageAnomalySignal usageSignal({
  required TripOdometerUsageAnomalyStatus status,
  required String reasonCode,
}) {
  return TripOdometerUsageAnomalySignal(
    status: status,
    reviewedDayCount:
        status == TripOdometerUsageAnomalyStatus.insufficientHistory ? 3 : 7,
    currentOdometerMiles: 180,
    averageDailyMiles: 40,
    reviewThresholdMiles: 100,
    ignoredHistoryRecordCount: 0,
    anomalyAlertsEnabled: true,
    reasonCode: reasonCode,
  );
}
