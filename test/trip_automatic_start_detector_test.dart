import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_start_detector.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  const detector = TripAutomaticStartDetector();
  final start = DateTime.utc(2026, 7, 21, 12);

  TripAutomaticStartObservation observation(
    int seconds, {
    TripActivity activity = TripActivity.unknown,
    int confidence = 0,
    String? vehicleId,
  }) => TripAutomaticStartObservation(
    recordedAt: start.add(Duration(seconds: seconds)),
    speedMetersPerSecond: 8,
    displacementMeters: 30,
    horizontalAccuracyMeters: 8,
    activity: activity,
    activityConfidence: confidence,
    bluetoothVehicleId: vehicleId,
  );

  test('one point and GPS-only thresholds cannot create a candidate', () {
    final onePoint = detector.evaluate(
      enabled: true,
      hasActiveOrRecoverableSession: false,
      observations: [
        observation(0, activity: TripActivity.automotive, confidence: 90),
      ],
    );
    final gpsOnly = detector.evaluate(
      enabled: true,
      hasActiveOrRecoverableSession: false,
      observations: [observation(0), observation(15), observation(30)],
    );

    expect(onePoint.shouldSuggestStart, isFalse);
    expect(gpsOnly.shouldSuggestStart, isFalse);
  });

  test(
    'time-spaced movement plus independent signal creates suggestion only',
    () {
      final decision = detector.evaluate(
        enabled: true,
        hasActiveOrRecoverableSession: false,
        observations: [
          observation(0, vehicleId: 'vehicle_1'),
          observation(
            15,
            activity: TripActivity.automotive,
            confidence: 90,
            vehicleId: 'vehicle_1',
          ),
          observation(30, vehicleId: 'vehicle_1'),
        ],
      );

      expect(decision.disposition, TripAutomaticStartDisposition.candidate);
      expect(decision.confidence, TripTrackingConfidence.high);
      expect(decision.suggestedVehicleId, 'vehicle_1');
      expect(decision.canInventStartingOdometer, isFalse);
      expect(decision.canAssignBusinessPurpose, isFalse);
      expect(decision.canAssignJob, isFalse);
      expect(decision.canFinalizeTripLog, isFalse);
      expect(decision.canClassifyMileage, isFalse);
      expect(decision.toMap()['coordinatesIncluded'], isFalse);
    },
  );
}
