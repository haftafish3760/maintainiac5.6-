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

  test(
    'one point cannot start, while plausible GPS movement is retained for review',
    () {
      final onePoint = detector.evaluate(
        enabled: true,
        accessLevel: TripAutomaticStartAccessLevel.paid,
        hasActiveOrRecoverableSession: false,
        evaluatedAt: start.add(const Duration(seconds: 30)),
        observations: [
          observation(0, activity: TripActivity.automotive, confidence: 90),
        ],
      );
      final gpsOnly = detector.evaluate(
        enabled: true,
        accessLevel: TripAutomaticStartAccessLevel.paid,
        hasActiveOrRecoverableSession: false,
        evaluatedAt: start.add(const Duration(seconds: 30)),
        observations: [observation(0), observation(15), observation(30)],
      );

      expect(onePoint.shouldSuggestStart, isFalse);
      expect(onePoint.shouldCreateReviewCandidate, isTrue);
      expect(
        onePoint.disposition,
        TripAutomaticStartDisposition.reviewCandidate,
      );
      expect(gpsOnly.shouldSuggestStart, isFalse);
      expect(gpsOnly.shouldCreateReviewCandidate, isTrue);
      expect(gpsOnly.reasonCode, 'possible_vehicle_movement_requires_review');
    },
  );

  test(
    'Bluetooth connection without current movement cannot create a candidate',
    () {
      final decision = detector.evaluate(
        enabled: true,
        accessLevel: TripAutomaticStartAccessLevel.paid,
        hasActiveOrRecoverableSession: false,
        evaluatedAt: start.add(const Duration(seconds: 30)),
        observations: List.generate(
          3,
          (index) => TripAutomaticStartObservation(
            recordedAt: start.add(Duration(seconds: index * 15)),
            speedMetersPerSecond: 0,
            displacementMeters: 0,
            horizontalAccuracyMeters: 8,
            bluetoothVehicleId: 'vehicle_1',
          ),
        ),
      );

      expect(decision.shouldSuggestStart, isFalse);
      expect(
        decision.reasonCode,
        'insufficient_multi_signal_movement_evidence',
      );
      expect(decision.suggestedVehicleId, isNull);
    },
  );

  test(
    'time-spaced movement plus independent signal creates suggestion only',
    () {
      final decision = detector.evaluate(
        enabled: true,
        accessLevel: TripAutomaticStartAccessLevel.paid,
        hasActiveOrRecoverableSession: false,
        evaluatedAt: start.add(const Duration(seconds: 30)),
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

  test('free access can create one of four proposal-only recoveries', () {
    final decision = detector.evaluate(
      enabled: true,
      accessLevel: TripAutomaticStartAccessLevel.free,
      hasActiveOrRecoverableSession: false,
      evaluatedAt: start.add(const Duration(seconds: 30)),
      observations: [
        observation(0, vehicleId: 'vehicle_1'),
        observation(15, vehicleId: 'vehicle_1'),
        observation(30, vehicleId: 'vehicle_1'),
      ],
    );

    expect(decision.disposition, TripAutomaticStartDisposition.candidate);
    expect(decision.shouldSuggestStart, isFalse);
    expect(decision.canStartTrackingAutomatically, isFalse);
    expect(decision.shouldCreateReviewCandidate, isTrue);
    expect(decision.requiresPaidEntitlementOnAcceptance, isFalse);
    expect(decision.allowanceDecision?.freeUsesRemaining, 4);
    expect(decision.allowanceDecision?.consumesOnDetection, isFalse);
    expect(decision.allowanceDecision?.consumesFreeUseIfAccepted, isTrue);
    expect(decision.toMap()['confidenceScoreShown'], isFalse);
  });

  test(
    'fifth free recovery stays reviewable but requires paid access on acceptance',
    () {
      final decision = detector.evaluate(
        enabled: true,
        accessLevel: TripAutomaticStartAccessLevel.free,
        hasActiveOrRecoverableSession: false,
        evaluatedAt: start.add(const Duration(seconds: 30)),
        acceptedFreeUsesInPeriod: 4,
        observations: [
          observation(0, vehicleId: 'vehicle_1'),
          observation(15, vehicleId: 'vehicle_1'),
          observation(30, vehicleId: 'vehicle_1'),
        ],
      );

      expect(decision.disposition, TripAutomaticStartDisposition.candidate);
      expect(decision.shouldSuggestStart, isFalse);
      expect(decision.canStartTrackingAutomatically, isFalse);
      expect(decision.shouldCreateReviewCandidate, isTrue);
      expect(decision.requiresPaidEntitlementOnAcceptance, isTrue);
      expect(decision.allowanceDecision?.freeUsesRemaining, 0);
    },
  );

  test('strong walking evidence never becomes a vehicle review candidate', () {
    final decision = detector.evaluate(
      enabled: true,
      accessLevel: TripAutomaticStartAccessLevel.paid,
      hasActiveOrRecoverableSession: false,
      evaluatedAt: start.add(const Duration(seconds: 30)),
      observations: [
        TripAutomaticStartObservation(
          recordedAt: start,
          speedMetersPerSecond: 2.5,
          displacementMeters: 12,
          horizontalAccuracyMeters: 8,
          activity: TripActivity.walking,
          activityConfidence: 90,
        ),
      ],
    );

    expect(
      decision.disposition,
      TripAutomaticStartDisposition.insufficientEvidence,
    );
    expect(decision.shouldCreateReviewCandidate, isFalse);
  });

  test('cached or future movement evidence cannot create a proposal', () {
    final cached = detector.evaluate(
      enabled: true,
      accessLevel: TripAutomaticStartAccessLevel.paid,
      hasActiveOrRecoverableSession: false,
      evaluatedAt: start.add(const Duration(minutes: 5)),
      observations: [
        observation(0, vehicleId: 'vehicle_1'),
        observation(15, vehicleId: 'vehicle_1'),
        observation(30, vehicleId: 'vehicle_1'),
      ],
    );
    final future = detector.evaluate(
      enabled: true,
      accessLevel: TripAutomaticStartAccessLevel.paid,
      hasActiveOrRecoverableSession: false,
      evaluatedAt: start.add(const Duration(seconds: 20)),
      observations: [
        observation(0, vehicleId: 'vehicle_1'),
        observation(15, vehicleId: 'vehicle_1'),
        observation(30, vehicleId: 'vehicle_1'),
      ],
    );

    for (final decision in [cached, future]) {
      expect(decision.shouldSuggestStart, isFalse);
      expect(decision.reasonCode, 'stale_or_future_automatic_evidence');
      expect(decision.canInventStartingOdometer, isFalse);
    }
  });
}
