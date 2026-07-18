import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_usage_anomaly.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'unusually high odometer delta recommends review from driver history',
    () {
      final signal = TripOdometerUsageAnomalySignal.evaluate(
        currentOdometerMiles: 180,
        history: _history(dailyMiles: 40),
        vehicleId: 'vehicle_1',
      );

      expect(signal.status, TripOdometerUsageAnomalyStatus.reviewRecommended);
      expect(signal.shouldPromptUser, isTrue);
      expect(signal.reviewedDayCount, 7);
      expect(signal.averageDailyMiles, 40);
      expect(signal.reviewThresholdMiles, 100);
      expect(signal.reasonCode, 'unusually_high_odometer_delta');
      expect(signal.canAutoCorrectOdometer, isFalse);
      expect(signal.toSafeDashboardMap(), {
        'schemaVersion': 1,
        'status': 'reviewRecommended',
        'reviewedDayCount': 7,
        'ignoredHistoryRecordCount': 0,
        'currentOdometerMiles': 180.0,
        'averageDailyMiles': 40.0,
        'reviewThresholdMiles': 100.0,
        'reasonCode': 'unusually_high_odometer_delta',
        'shouldPromptUser': true,
        'canAutoCorrectOdometer': false,
        'anomalyAlertsEnabled': true,
        'manualReviewRequiredBeforeChange': true,
        'odometerRemainsCanonical': true,
        'odometerIsGlobalTruth': true,
        'gpsCanReplaceOdometer': false,
        'gpsCanSetGlobalTruth': false,
        'gpsCanChangeOfficialMileage': false,
        'mapboxCanReplaceOdometer': false,
        'mapboxCanSetGlobalTruth': false,
        'mapboxCanChangeOfficialMileage': false,
        'remoteTotalsCanReplaceOdometer': false,
        'remoteTotalsCanSetGlobalTruth': false,
        'remoteTotalsCanChangeOfficialMileage': false,
        'firestoreCanCreateUsageAnomaly': false,
        'mapboxCanCreateUsageAnomaly': false,
        'usageAnomalyCanBlockWithoutUserReview': false,
        'anomalyAlertsRequireUserOptIn': true,
        'calibrationAssistRequiresUserOptIn': true,
        'calibrationRequiresMultipleReviewedTrips': true,
        'calibrationCanAutoRewriteConfirmedOdometer': false,
        'calibrationCanBypassVehicleProfile': false,
        'usageAnomalyCanApplyCalibration': false,
        'usageAnomalyCanPurgeLocalDataAfterBackup': false,
        'confirmedHistoryOnly': true,
        'futureConfirmationsIgnored': true,
        'rawHistoryIncluded': false,
        'rawTripRecordsIncluded': false,
        'rawLocationIncluded': false,
        'tokensIncluded': false,
      });
    },
  );

  test('normal odometer delta stays advisory-silent', () {
    final signal = TripOdometerUsageAnomalySignal.evaluate(
      currentOdometerMiles: 85,
      history: _history(dailyMiles: 40),
      vehicleId: 'vehicle_1',
    );

    expect(signal.status, TripOdometerUsageAnomalyStatus.normal);
    expect(signal.shouldPromptUser, isFalse);
    expect(signal.reasonCode, 'odometer_usage_within_review_threshold');
  });

  test('unusually low odometer delta recommends review without correction', () {
    final signal = TripOdometerUsageAnomalySignal.evaluate(
      currentOdometerMiles: 20,
      history: _history(dailyMiles: 100),
      vehicleId: 'vehicle_1',
    );
    final summary = signal.toSafeDashboardMap();

    expect(signal.status, TripOdometerUsageAnomalyStatus.reviewRecommended);
    expect(signal.shouldPromptUser, isTrue);
    expect(signal.reasonCode, 'unusually_low_odometer_delta');
    expect(signal.reviewThresholdMiles, 40);
    expect(signal.canAutoCorrectOdometer, isFalse);
    expect(summary['reasonCode'], 'unusually_low_odometer_delta');
    expect(summary['manualReviewRequiredBeforeChange'], isTrue);
    expect(summary['canAutoCorrectOdometer'], isFalse);
    expect(summary['odometerRemainsCanonical'], isTrue);
    expect(summary['remoteTotalsCanReplaceOdometer'], isFalse);
  });

  test('usage anomaly respects user opt-in before prompting', () {
    final signal = TripOdometerUsageAnomalySignal.evaluate(
      currentOdometerMiles: 180,
      history: _history(dailyMiles: 40),
      vehicleId: 'vehicle_1',
      anomalyAlertsEnabled: false,
    );
    final summary = signal.toSafeDashboardMap();

    expect(signal.status, TripOdometerUsageAnomalyStatus.normal);
    expect(signal.shouldPromptUser, isFalse);
    expect(signal.reasonCode, 'odometer_anomaly_alerts_disabled');
    expect(summary['anomalyAlertsEnabled'], isFalse);
    expect(summary['manualReviewRequiredBeforeChange'], isFalse);
  });

  test('usage anomaly waits for enough confirmed reviewed days', () {
    final signal = TripOdometerUsageAnomalySignal.evaluate(
      currentOdometerMiles: 200,
      history: _history(dailyMiles: 40, days: 6),
      vehicleId: 'vehicle_1',
    );

    expect(signal.status, TripOdometerUsageAnomalyStatus.insufficientHistory);
    expect(signal.reviewedDayCount, 6);
    expect(signal.shouldPromptUser, isFalse);
  });

  test('usage anomaly ignores other vehicles and future confirmations', () {
    final now = DateTime.utc(2026, 7, 17, 12);
    final reviews = [
      ..._history(dailyMiles: 40, days: 7),
      _review(
        day: 8,
        vehicleId: 'vehicle_2',
        startingOdometer: 5000,
        confirmedEndingOdometer: 6000,
      ),
      _review(
        day: 9,
        vehicleId: 'vehicle_1',
        startingOdometer: 6000,
        confirmedEndingOdometer: 7000,
        confirmedAt: now.add(const Duration(days: 1)),
      ),
    ];

    final signal = TripOdometerUsageAnomalySignal.evaluate(
      currentOdometerMiles: 101,
      history: reviews,
      vehicleId: ' vehicle_1 ',
      nowUtc: now,
    );

    expect(signal.reviewedDayCount, 7);
    expect(signal.ignoredHistoryRecordCount, 2);
    expect(signal.averageDailyMiles, 40);
    expect(signal.status, TripOdometerUsageAnomalyStatus.reviewRecommended);
  });

  test('usage anomaly rejects malformed thresholds instead of guessing', () {
    final signal = TripOdometerUsageAnomalySignal.evaluate(
      currentOdometerMiles: double.nan,
      history: _history(dailyMiles: 40),
      reviewMultiplier: .5,
    );

    expect(signal.status, TripOdometerUsageAnomalyStatus.invalid);
    expect(signal.reasonCode, 'invalid_usage_anomaly_input');
    expect(signal.canAutoCorrectOdometer, isFalse);
    expect(signal.toSafeDashboardMap()['currentOdometerMiles'], 0);
    expect(signal.toSafeDashboardMap()['rawHistoryIncluded'], isFalse);
  });

  test('usage anomaly ignores impossible historical mileage outliers', () {
    final signal = TripOdometerUsageAnomalySignal.evaluate(
      currentOdometerMiles: 101,
      history: [
        ..._history(dailyMiles: 40),
        _review(day: 9, startingOdometer: 2000, confirmedEndingOdometer: 6000),
      ],
      vehicleId: 'vehicle_1',
    );

    expect(signal.reviewedDayCount, 7);
    expect(signal.ignoredHistoryRecordCount, 1);
    expect(signal.averageDailyMiles, 40);
    expect(signal.status, TripOdometerUsageAnomalyStatus.reviewRecommended);
  });

  test('usage anomaly rejects malformed maximum trusted day threshold', () {
    final signal = TripOdometerUsageAnomalySignal.evaluate(
      currentOdometerMiles: 90,
      history: _history(dailyMiles: 40),
      maximumTrustedReviewedDayMiles: double.infinity,
    );

    expect(signal.status, TripOdometerUsageAnomalyStatus.invalid);
    expect(signal.reasonCode, 'invalid_usage_anomaly_input');
  });

  test('usage anomaly combines multiple confirmed trips on the same day', () {
    final signal = TripOdometerUsageAnomalySignal.evaluate(
      currentOdometerMiles: 120,
      history: [
        ..._history(dailyMiles: 40, days: 6),
        _review(day: 7, startingOdometer: 2000, confirmedEndingOdometer: 2020),
        _review(day: 7, startingOdometer: 2020, confirmedEndingOdometer: 2040),
      ],
      vehicleId: 'vehicle_1',
    );

    expect(signal.reviewedDayCount, 7);
    expect(signal.averageDailyMiles, 40);
    expect(signal.status, TripOdometerUsageAnomalyStatus.reviewRecommended);
  });

  test('usage anomaly bounds oversized imported history', () {
    final signal = TripOdometerUsageAnomalySignal.evaluate(
      currentOdometerMiles: 400,
      history: _history(dailyMiles: 40, days: 14),
      vehicleId: 'vehicle_1',
      maximumHistoryRecords: 7,
    );

    expect(signal.reviewedDayCount, 7);
    expect(signal.ignoredHistoryRecordCount, 7);
    expect(signal.status, TripOdometerUsageAnomalyStatus.reviewRecommended);
  });

  test('safe anomaly maps expose calibration as review-only guidance', () {
    final signal = TripOdometerUsageAnomalySignal.evaluate(
      currentOdometerMiles: 120,
      history: _history(dailyMiles: 40),
      vehicleId: 'vehicle_1',
    );
    final summary = signal.toSafeDashboardMap();

    expect(summary['anomalyAlertsRequireUserOptIn'], isTrue);
    expect(summary['calibrationAssistRequiresUserOptIn'], isTrue);
    expect(summary['calibrationRequiresMultipleReviewedTrips'], isTrue);
    expect(summary['calibrationCanAutoRewriteConfirmedOdometer'], isFalse);
    expect(summary['calibrationCanBypassVehicleProfile'], isFalse);
    expect(summary['usageAnomalyCanApplyCalibration'], isFalse);
    expect(summary['usageAnomalyCanPurgeLocalDataAfterBackup'], isFalse);
    expect(summary['confirmedHistoryOnly'], isTrue);
    expect(summary['futureConfirmationsIgnored'], isTrue);
    expect(summary['remoteTotalsCanReplaceOdometer'], isFalse);
  });

  test('safe usage anomaly summary validates as renderable', () {
    final validation = TripOdometerUsageAnomalySummaryValidation.fromSummary(
      TripOdometerUsageAnomalySignal.evaluate(
        currentOdometerMiles: 120,
        history: _history(dailyMiles: 40),
        vehicleId: 'vehicle_1',
      ).toSafeDashboardMap(),
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.status, TripOdometerUsageAnomalyStatus.reviewRecommended);
    expect(validation.reasons, isEmpty);
  });

  test(
    'usage anomaly summary rejects odometer, remote, and sensitive claims',
    () {
      final validation = TripOdometerUsageAnomalySummaryValidation.fromSummary(
        TripOdometerUsageAnomalySignal.evaluate(
          currentOdometerMiles: 120,
          history: _history(dailyMiles: 40),
          vehicleId: 'vehicle_1',
        ).toSafeDashboardMap()..addAll({
          'canAutoCorrectOdometer': true,
          'manualReviewRequiredBeforeChange': false,
          'odometerRemainsCanonical': false,
          'odometerIsGlobalTruth': false,
          'gpsCanReplaceOdometer': true,
          'gpsCanSetGlobalTruth': true,
          'gpsCanChangeOfficialMileage': true,
          'mapboxCanReplaceOdometer': true,
          'mapboxCanSetGlobalTruth': true,
          'mapboxCanChangeOfficialMileage': true,
          'remoteTotalsCanReplaceOdometer': true,
          'remoteTotalsCanSetGlobalTruth': true,
          'remoteTotalsCanChangeOfficialMileage': true,
          'usageAnomalyCanBlockWithoutUserReview': true,
          'firestoreCanCreateUsageAnomaly': true,
          'mapboxCanCreateUsageAnomaly': true,
          'anomalyAlertsRequireUserOptIn': false,
          'calibrationAssistRequiresUserOptIn': false,
          'calibrationRequiresMultipleReviewedTrips': false,
          'calibrationCanAutoRewriteConfirmedOdometer': true,
          'calibrationCanBypassVehicleProfile': true,
          'usageAnomalyCanApplyCalibration': true,
          'usageAnomalyCanPurgeLocalDataAfterBackup': true,
          'confirmedHistoryOnly': false,
          'futureConfirmationsIgnored': false,
          'rawHistoryIncluded': true,
          'rawTripRecordsIncluded': true,
          'rawLocationIncluded': true,
          'tokensIncluded': true,
          'debug': 'pk.public 35.123456,-80.123456',
        }),
      );

      expect(validation.isRenderable, isFalse);
      expect(
        validation.reasons,
        contains('usage_anomaly_can_mutate_odometer_truth'),
      );
      expect(validation.reasons, contains('remote_or_map_can_create_anomaly'));
      expect(
        validation.reasons,
        contains('calibration_anomaly_boundary_missing'),
      );
      expect(
        validation.reasons,
        contains('history_validation_boundary_missing'),
      );
      expect(
        validation.reasons,
        contains('summary_contains_sensitive_anomaly_material'),
      );
      expect(validation.reasons, contains('summary_contains_sensitive_text'));
    },
  );
}

List<TripTrackingReviewRecord> _history({
  required int dailyMiles,
  int days = 7,
}) {
  return [
    for (var day = 0; day < days; day++)
      _review(
        day: day,
        startingOdometer: 1000 + (day * dailyMiles),
        confirmedEndingOdometer: 1000 + ((day + 1) * dailyMiles),
      ),
  ];
}

TripTrackingReviewRecord _review({
  required int day,
  int startingOdometer = 1000,
  int confirmedEndingOdometer = 1040,
  String vehicleId = 'vehicle_1',
  DateTime? confirmedAt,
}) {
  final startedAt = DateTime.utc(2026, 7, 1 + day, 8);
  final finishedAt = DateTime.utc(2026, 7, 1 + day, 10);
  return TripTrackingReviewRecord(
    id: 'trip_usage_$day',
    vehicleId: vehicleId,
    startingOdometer: startingOdometer,
    estimatedEndingOdometer: confirmedEndingOdometer,
    confirmedEndingOdometer: confirmedEndingOdometer,
    odometerConfirmedAt:
        confirmedAt ?? finishedAt.add(const Duration(minutes: 5)),
    profile: TripTrackingProfile.roadVehicle,
    startedAt: startedAt,
    finishedAt: finishedAt,
    engineSnapshot: TripTrackingEngineSnapshot(
      totalAcceptedMeters:
          (confirmedEndingOdometer - startingOdometer) * 1609.344,
      walkingReviewSuggested: false,
    ),
  );
}
