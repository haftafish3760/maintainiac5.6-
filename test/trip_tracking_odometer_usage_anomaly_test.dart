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
        'currentOdometerMiles': 180.0,
        'averageDailyMiles': 40.0,
        'reviewThresholdMiles': 100.0,
        'reasonCode': 'unusually_high_odometer_delta',
        'shouldPromptUser': true,
        'canAutoCorrectOdometer': false,
        'manualReviewRequiredBeforeChange': true,
        'odometerRemainsCanonical': true,
        'gpsCanReplaceOdometer': false,
        'mapboxCanReplaceOdometer': false,
        'remoteTotalsCanReplaceOdometer': false,
        'anomalyAlertsRequireUserOptIn': true,
        'calibrationAssistRequiresUserOptIn': true,
        'calibrationRequiresMultipleReviewedTrips': true,
        'calibrationCanAutoRewriteConfirmedOdometer': false,
        'confirmedHistoryOnly': true,
        'futureConfirmationsIgnored': true,
        'rawHistoryIncluded': false,
        'rawTripRecordsIncluded': false,
        'rawLocationIncluded': false,
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
    expect(summary['confirmedHistoryOnly'], isTrue);
    expect(summary['futureConfirmationsIgnored'], isTrue);
    expect(summary['remoteTotalsCanReplaceOdometer'], isFalse);
  });
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
