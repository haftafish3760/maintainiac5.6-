import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_odometer_calibration_prompt_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_calibration.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18, 12);

  test('disabled and snoozed calibration assist stays hidden', () {
    final disabled = evaluate(
      now: now,
      userEnabledCalibrationAssist: false,
      signal: signal(status: TripOdometerCalibrationStatus.reviewRecommended),
    );
    final snoozed = evaluate(
      now: now,
      snoozedUntilUtc: now.add(const Duration(days: 1)),
      signal: signal(status: TripOdometerCalibrationStatus.reviewRecommended),
    );

    expect(disabled.surface, TripOdometerCalibrationPromptSurface.hidden);
    expect(disabled.reason, TripOdometerCalibrationPromptReason.disabledByUser);
    expect(snoozed.surface, TripOdometerCalibrationPromptSurface.hidden);
    expect(snoozed.reason, TripOdometerCalibrationPromptReason.snoozed);
  });

  test('partial reviewed history can show a quiet learning chip only', () {
    final decision = evaluate(
      now: now,
      signal: signal(
        status: TripOdometerCalibrationStatus.insufficientHistory,
        eligibleSampleCount: 4,
      ),
    );

    expect(decision.surface, TripOdometerCalibrationPromptSurface.quietChip);
    expect(
      decision.reason,
      TripOdometerCalibrationPromptReason.needsMoreReviewedDays,
    );
    expect(decision.canApplyAutomatically, isFalse);
  });

  test('persistent drift shows tire or speedometer review banner', () {
    final decision = evaluate(
      now: now,
      signal: signal(
        status: TripOdometerCalibrationStatus.reviewRecommended,
        averageDifferencePercent: 5.2,
        averageGpsToOdometerRatio: 1.06,
      ),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.surface, TripOdometerCalibrationPromptSurface.reviewBanner);
    expect(
      decision.reason,
      TripOdometerCalibrationPromptReason.tireOrSpeedometerReview,
    );
    expect(safe['tireSizeReviewSuggested'], isTrue);
    expect(safe['speedometerCalibrationReviewSuggested'], isTrue);
  });

  test('stable calibration remains hidden after validation', () {
    final decision = evaluate(
      now: now,
      signal: signal(status: TripOdometerCalibrationStatus.stable),
    );

    expect(decision.surface, TripOdometerCalibrationPromptSurface.hidden);
    expect(decision.reason, TripOdometerCalibrationPromptReason.noPromptNeeded);
  });

  test('malformed calibration signal cannot surface a review banner', () {
    final malformed = evaluate(
      now: now,
      signal: const TripOdometerCalibrationSignal(
        status: TripOdometerCalibrationStatus.reviewRecommended,
        eligibleSampleCount: -1,
        averageGpsToOdometerRatio: double.nan,
        averageDifferencePercent: double.infinity,
        reasonCode: 'token=sk.secret lat=35.1',
      ),
    );
    final excessiveHistory = evaluate(
      now: now,
      signal: signal(
        status: TripOdometerCalibrationStatus.reviewRecommended,
        eligibleSampleCount: 500,
      ),
    );

    expect(malformed.surface, TripOdometerCalibrationPromptSurface.hidden);
    expect(malformed.reason, TripOdometerCalibrationPromptReason.invalidSignal);
    expect(malformed.shouldShow, isFalse);
    expect(
      malformed.toSafeDashboardMap()['messageToken'],
      'calibration_signal_invalid',
    );
    expect(
      malformed.toSafeDashboardMap().toString(),
      isNot(contains('sk.secret')),
    );
    expect(
      excessiveHistory.surface,
      TripOdometerCalibrationPromptSurface.hidden,
    );
    expect(
      excessiveHistory.reason,
      TripOdometerCalibrationPromptReason.invalidSignal,
    );
  });

  test('safe prompt summary never grants silent calibration authority', () {
    final safe = evaluate(
      now: now,
      signal: signal(
        status: TripOdometerCalibrationStatus.reviewRecommended,
        averageDifferencePercent: 6,
      ),
    ).toSafeDashboardMap();

    expect(safe['calibrationRequiresUserOptIn'], isTrue);
    expect(safe['continuousCalibrationAverageRequired'], isTrue);
    expect(safe['singleDayCalibrationRejected'], isTrue);
    expect(safe['calibrationRequiresReviewedLocalHistory'], isTrue);
    expect(safe['calibrationRequiresVehicleMatchedHistory'], isTrue);
    expect(safe['calibrationRequiresOwnershipValidation'], isTrue);
    expect(safe['calibrationRequiresDaytimeLocalSource'], isTrue);
    expect(safe['calibrationRequiresManualUserConfirmation'], isTrue);
    expect(safe['calibrationPromptRequiresFreshLocalEvaluation'], isTrue);
    expect(safe['calibrationCanReplaceConfirmedOdometer'], isFalse);
    expect(safe['calibrationCanLowerConfirmedOdometer'], isFalse);
    expect(safe['calibrationCanCreateMaintenanceRecord'], isFalse);
    expect(safe['gpsCanReplaceOdometerSilently'], isFalse);
    expect(safe['mapboxCanReplaceOdometerSilently'], isFalse);
    expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
    expect(safe['tirePromptIsAdvisoryOnly'], isTrue);
    expect(safe['tirePromptDoesNotCreateMaintenanceEntry'], isTrue);
    expect(safe['authenticationAloneAuthorizesCalibration'], isFalse);
    expect(safe['firestoreCanApplyCalibration'], isFalse);
    expect(safe['cloudFunctionCanApplyCalibration'], isFalse);
    expect(safe['mapboxCanApplyCalibration'], isFalse);
    expect(safe['importedFileCanApplyCalibration'], isFalse);
    expect(safe['remoteCalibrationCanEnableSetting'], isFalse);
    expect(safe['remoteCalibrationCanResetPrompt'], isFalse);
    expect(safe['mapboxCanTriggerTirePrompt'], isFalse);
    expect(safe['gpsCanAutoApplyCalibration'], isFalse);
    expect(safe['rawReviewedTripsIncluded'], isFalse);
    expect(safe['preciseLocationIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
    expect(safe.toString(), isNot(contains('pk.')));
    expect(safe.toString(), isNot(contains('sk.')));
  });

  test('safe prompt summary validates local reviewed-history boundary', () {
    final validation =
        TripOdometerCalibrationPromptSummaryValidation.fromSummary(
          evaluate(
            now: now,
            signal: signal(
              status: TripOdometerCalibrationStatus.reviewRecommended,
              averageDifferencePercent: 6,
            ),
          ).toSafeDashboardMap(),
        );

    expect(validation.isRenderable, isTrue);
    expect(validation.reasons, isEmpty);
  });

  test('forged prompt summaries cannot grant calibration authority', () {
    final validation =
        TripOdometerCalibrationPromptSummaryValidation.fromSummary(
          evaluate(
            now: now,
            signal: signal(
              status: TripOdometerCalibrationStatus.reviewRecommended,
              averageDifferencePercent: 6,
            ),
          ).toSafeDashboardMap()..addAll({
            'canApplyAutomatically': true,
            'calibrationRequiresUserOptIn': false,
            'calibrationRequiresMultipleReviewedTrips': false,
            'continuousCalibrationAverageRequired': false,
            'singleDayCalibrationRejected': false,
            'calibrationRequiresReviewedLocalHistory': false,
            'calibrationRequiresVehicleMatchedHistory': false,
            'calibrationRequiresOwnershipValidation': false,
            'calibrationRequiresDaytimeLocalSource': false,
            'calibrationRequiresManualUserConfirmation': false,
            'calibrationPromptRequiresFreshLocalEvaluation': false,
            'calibrationAppliesToFutureGpsAssistanceOnly': false,
            'calibrationCanRewritePastTrips': true,
            'calibrationCanReplaceConfirmedOdometer': true,
            'calibrationCanLowerConfirmedOdometer': true,
            'calibrationCanCreateMaintenanceRecord': true,
            'gpsCanReplaceOdometerSilently': true,
            'mapboxCanReplaceOdometerSilently': true,
            'odometerRemainsOfficialMileageTruth': false,
            'tirePromptIsAdvisoryOnly': false,
            'tirePromptDoesNotCreateMaintenanceEntry': false,
            'remoteHistoryCanTriggerPromptWithoutLocalValidation': true,
            'authenticationAloneAuthorizesCalibration': true,
            'firestoreCanApplyCalibration': true,
            'cloudFunctionCanApplyCalibration': true,
            'mapboxCanApplyCalibration': true,
            'importedFileCanApplyCalibration': true,
            'remoteCalibrationCanEnableSetting': true,
            'remoteCalibrationCanResetPrompt': true,
            'mapboxCanTriggerTirePrompt': true,
            'gpsCanAutoApplyCalibration': true,
            'rawReviewedTripsIncluded': true,
            'rawGpsIncluded': true,
            'preciseLocationIncluded': true,
            'tokensIncluded': true,
            'debug': 'sk.secret 35.123456,-80.123456',
          }),
        );

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('calibration_review_boundary_missing'));
    expect(validation.reasons, contains('calibration_can_replace_odometer'));
    expect(validation.reasons, contains('remote_can_apply_calibration'));
    expect(
      validation.reasons,
      contains('summary_contains_sensitive_calibration_material'),
    );
  });

  test('forged prompt summaries cannot bypass local ownership validation', () {
    final summary =
        evaluate(
          now: now,
          signal: signal(
            status: TripOdometerCalibrationStatus.reviewRecommended,
            averageDifferencePercent: 6,
          ),
        ).toSafeDashboardMap()..addAll({
          'calibrationRequiresOwnershipValidation': false,
          'calibrationRequiresDaytimeLocalSource': false,
          'authenticationAloneAuthorizesCalibration': true,
        });

    final validation =
        TripOdometerCalibrationPromptSummaryValidation.fromSummary(summary);

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('calibration_review_boundary_missing'));
    expect(validation.reasons, contains('remote_can_apply_calibration'));
  });
}

TripOdometerCalibrationPromptDecision evaluate({
  required DateTime now,
  required TripOdometerCalibrationSignal signal,
  bool userEnabledCalibrationAssist = true,
  bool userDismissedPrompt = false,
  DateTime? snoozedUntilUtc,
}) {
  return TripOdometerCalibrationPromptPolicy.evaluate(
    signal: signal,
    userEnabledCalibrationAssist: userEnabledCalibrationAssist,
    userDismissedPrompt: userDismissedPrompt,
    snoozedUntilUtc: snoozedUntilUtc,
    nowUtc: now,
  );
}

TripOdometerCalibrationSignal signal({
  required TripOdometerCalibrationStatus status,
  int eligibleSampleCount = 7,
  double averageGpsToOdometerRatio = 1.05,
  double averageDifferencePercent = 5,
}) {
  return TripOdometerCalibrationSignal(
    status: status,
    eligibleSampleCount: eligibleSampleCount,
    averageGpsToOdometerRatio: averageGpsToOdometerRatio,
    averageDifferencePercent: averageDifferencePercent,
    reasonCode: status == TripOdometerCalibrationStatus.reviewRecommended
        ? 'persistent_gps_odometer_drift'
        : status == TripOdometerCalibrationStatus.stable
        ? 'calibration_stable'
        : 'needs_more_reviewed_days',
  );
}
