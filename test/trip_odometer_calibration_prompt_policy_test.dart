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

  test('safe prompt summary never grants silent calibration authority', () {
    final safe = evaluate(
      now: now,
      signal: signal(
        status: TripOdometerCalibrationStatus.reviewRecommended,
        averageDifferencePercent: 6,
      ),
    ).toSafeDashboardMap();

    expect(safe['calibrationRequiresUserOptIn'], isTrue);
    expect(safe['calibrationCanReplaceConfirmedOdometer'], isFalse);
    expect(safe['gpsCanReplaceOdometerSilently'], isFalse);
    expect(safe['mapboxCanReplaceOdometerSilently'], isFalse);
    expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
    expect(safe['firestoreCanApplyCalibration'], isFalse);
    expect(safe['mapboxCanApplyCalibration'], isFalse);
    expect(safe['rawReviewedTripsIncluded'], isFalse);
    expect(safe['preciseLocationIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
    expect(safe.toString(), isNot(contains('pk.')));
    expect(safe.toString(), isNot(contains('sk.')));
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
