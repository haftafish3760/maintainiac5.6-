import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_odometer_calibration_prompt_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_odometer_end_review_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_calibration.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_reconciliation.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_usage_anomaly.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final day = DateTime.utc(2026, 7, 18, 8);

  test(
    'reconciliation summaries reject remote and mapbox odometer authority',
    () {
      final summary = TripOdometerReconciliation.compare(
        review: review(day: day),
        confirmedEndingOdometer: 1040,
      ).toSafeDashboardMap();

      expect(summary['shouldPromptUser'], isTrue);
      expect(summary['remoteTotalsCanConfirmOdometer'], isFalse);
      expect(summary['mapboxRouteCanConfirmOdometer'], isFalse);
      expect(summary['remoteTotalsCanBecomeCanonical'], isFalse);
      expect(summary['firestoreCanOverrideOdometerTruth'], isFalse);
      expect(summary['tokensIncluded'], isFalse);
    },
  );

  test(
    'entry validation requires user typed odometer for official mileage',
    () {
      final summary = TripOdometerEntryValidation.validate(
        startingOdometer: 1000,
        endingOdometer: 1008,
        previousConfirmedEndingOdometer: 1000,
        averageDailyMiles: 120,
      ).toSafeDashboardMap();

      expect(summary['manualReviewRequired'], isTrue);
      expect(summary['remoteEntryCanConfirmOdometer'], isFalse);
      expect(summary['userTypedOdometerRequiredForOfficialMileage'], isTrue);
      expect(summary['gpsCanCorrectEntryAutomatically'], isFalse);
      expect(summary['mapboxCanCorrectEntryAutomatically'], isFalse);
      expect(summary['tokensIncluded'], isFalse);
    },
  );

  test('continuity gaps stay manual review only and token safe', () {
    final previous = review(
      day: day.subtract(const Duration(days: 1)),
      id: 'previous_trip',
      starting: 1000,
      estimated: 1020,
      confirmed: 1020,
    );
    final next = review(
      day: day,
      id: 'next_trip',
      starting: 1100,
      estimated: 1120,
    );
    final summary = TripOdometerContinuityCheck.betweenReviews(
      previous: previous,
      next: next,
    ).toSafeDashboardMap();

    expect(summary['manualReviewRequired'], isTrue);
    expect(summary['remoteContinuityCanConfirmOdometer'], isFalse);
    expect(summary['userReviewRequiredBeforeGapAcceptance'], isTrue);
    expect(summary['gpsCanFillGapAutomatically'], isFalse);
    expect(summary['mapboxCanFillGapAutomatically'], isFalse);
    expect(summary['tokensIncluded'], isFalse);
  });

  test('usage anomaly can suggest review but cannot block or autocorrect', () {
    final history = [
      for (var index = 1; index <= 7; index += 1)
        review(
          day: day.subtract(Duration(days: index)),
          id: 'history_$index',
          starting: 1000 + (index * 20),
          estimated: 1020 + (index * 20),
          confirmed: 1020 + (index * 20),
        ),
    ];
    final summary = TripOdometerUsageAnomalySignal.evaluate(
      currentOdometerMiles: 200,
      history: history,
      nowUtc: day.add(const Duration(hours: 2)),
    ).toSafeDashboardMap();

    expect(summary['shouldPromptUser'], isTrue);
    expect(summary['canAutoCorrectOdometer'], isFalse);
    expect(summary['firestoreCanCreateUsageAnomaly'], isFalse);
    expect(summary['mapboxCanCreateUsageAnomaly'], isFalse);
    expect(summary['usageAnomalyCanBlockWithoutUserReview'], isFalse);
    expect(summary['remoteTotalsCanReplaceOdometer'], isFalse);
  });

  test('end review acknowledgement never rewrites odometer by itself', () {
    final decision = TripOdometerEndReviewPolicy.evaluate(
      entryValidation: TripOdometerEntryValidation.validate(
        startingOdometer: 1000,
        endingOdometer: 1040,
        previousConfirmedEndingOdometer: 1000,
        averageDailyMiles: 20,
      ),
      reconciliation: TripOdometerReconciliation.compare(
        review: review(day: day),
        confirmedEndingOdometer: 1040,
      ),
      calibrationPrompt: TripOdometerCalibrationPromptPolicy.evaluate(
        signal: const TripOdometerCalibrationSignal(
          status: TripOdometerCalibrationStatus.insufficientHistory,
          eligibleSampleCount: 0,
          averageGpsToOdometerRatio: 1,
          averageDifferencePercent: 0,
          reasonCode: 'needs_more_reviewed_days',
        ),
        userEnabledCalibrationAssist: true,
        userDismissedPrompt: false,
        snoozedUntilUtc: null,
        nowUtc: day,
      ),
      userAcknowledgedReviewPrompt: true,
    );
    final summary = decision.toSafeDashboardMap();

    expect(decision.status, TripOdometerEndReviewStatus.readyToConfirm);
    expect(summary['userAcknowledgementCannotRewriteOdometer'], isTrue);
    expect(summary['reviewAcknowledgementOnlyAllowsManualConfirm'], isTrue);
    expect(summary['remoteReviewAcknowledgementRejected'], isTrue);
    expect(summary['confirmedMileageRequiresUserAction'], isTrue);
    expect(summary['gpsCanConfirmOdometer'], isFalse);
    expect(summary['mapboxCanConfirmOdometer'], isFalse);
  });
}

TripTrackingReviewRecord review({
  required DateTime day,
  String id = 'trip_review_boundary',
  int starting = 1000,
  int estimated = 1020,
  int? confirmed,
}) {
  return TripTrackingReviewRecord(
    id: id,
    vehicleId: 'vehicle_1',
    startingOdometer: starting,
    estimatedEndingOdometer: estimated,
    profile: TripTrackingProfile.deliveryVehicle,
    startedAt: day,
    finishedAt: day.add(const Duration(hours: 1)),
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 32186.88,
      walkingReviewSuggested: false,
      vehicleMovementObserved: true,
    ),
    confirmedEndingOdometer: confirmed,
    odometerConfirmedAt: confirmed == null
        ? null
        : day.add(const Duration(hours: 2)),
  );
}
