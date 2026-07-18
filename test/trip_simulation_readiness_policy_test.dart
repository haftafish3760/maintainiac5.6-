import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_simulation_readiness_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

import 'support/trip_tracking_qa/trip_tracking_scenarios.dart';
import 'support/trip_tracking_qa/trip_tracking_simulator.dart';

void main() {
  final scenarios = TripTrackingScenarioLibrary(
    start: DateTime.utc(2026, 7, 18, 8),
  );

  TripSimulationReadinessDecision evaluate(
    List<SimulatedTripPoint> points, {
    required TripTrackingProfile profile,
    required bool expectedStopReview,
    bool expectedVehicleMovement = true,
  }) {
    final result = replayTrip(points, profile: profile);
    return TripSimulationReadinessPolicy.evaluate(
      profile: profile,
      acceptedMiles: result.acceptedMiles,
      acceptedDistanceCount: result.acceptedDistanceCount,
      rejectedUnsafeCount: result.rejectedUnsafeCount,
      excludedWalkingCount: result.excludedWalkingCount,
      stopReviewSuggested: result.needsWalkingReview,
      expectedStopReview: expectedStopReview,
      expectedVehicleMovement: expectedVehicleMovement,
    );
  }

  test('delivery leave-vehicle replay is ready with stop review expected', () {
    final decision = evaluate(
      scenarios.deliveryDriverLeavesVehicle(),
      profile: TripTrackingProfile.deliveryVehicle,
      expectedStopReview: true,
    );

    expect(decision.status, TripSimulationReadinessStatus.readyForFieldTrial);
    expect(decision.stopReviewSuggested, isTrue);
    expect(decision.excludedWalkingCount, greaterThan(0));
  });

  test('rideshare vehicle-only stop is ready without false walking stop', () {
    final decision = evaluate(
      scenarios.rideshareDriverStaysInVehicle(),
      profile: TripTrackingProfile.rideshareVehicle,
      expectedStopReview: false,
    );

    expect(decision.status, TripSimulationReadinessStatus.readyForFieldTrial);
    expect(decision.stopReviewSuggested, isFalse);
  });

  test('contractor jobsite replay is ready with review-only stop', () {
    final decision = evaluate(
      scenarios.contractorJobsiteWalkAround(),
      profile: TripTrackingProfile.contractorVehicle,
      expectedStopReview: true,
    );

    expect(decision.status, TripSimulationReadinessStatus.readyForFieldTrial);
    expect(decision.profile, TripTrackingProfile.contractorVehicle);
  });

  test('unsafe GPS replay blocks field trial readiness', () {
    final points = [
      SimulatedTripPoint(scenarios.roadPoint(-80, 0, speed: 9)),
      SimulatedTripPoint(scenarios.roadPoint(-79.5, 1, speed: 90)),
      SimulatedTripPoint(scenarios.roadPoint(-79.0, 2, speed: 90)),
      SimulatedTripPoint(scenarios.roadPoint(-78.5, 3, speed: 90)),
    ];
    final decision = evaluate(
      points,
      profile: TripTrackingProfile.deliveryVehicle,
      expectedStopReview: false,
    );

    expect(
      decision.status,
      TripSimulationReadinessStatus.blockedByUnsafeEvidence,
    );
    expect(decision.stopReviewSuggested, isFalse);
  });

  test('mismatched expected stop review needs more synthetic coverage', () {
    final decision = evaluate(
      scenarios.deliveryPhoneStaysInVehicleAtCustomerStop(),
      profile: TripTrackingProfile.deliveryVehicle,
      expectedStopReview: true,
    );

    expect(
      decision.status,
      TripSimulationReadinessStatus.needsMoreSyntheticCoverage,
    );
    expect(decision.reasonCode, 'simulation_stop_expectation_mismatch');
  });

  test(
    'safe summary never claims official stop, odometer, map, or token proof',
    () {
      final safe = evaluate(
        scenarios.deliveryDriverLeavesVehicle(),
        profile: TripTrackingProfile.deliveryVehicle,
        expectedStopReview: true,
      ).toSafeDashboardMap();

      expect(safe['simulationCanCreateOfficialStop'], isFalse);
      expect(safe['simulationCanConfirmOdometer'], isFalse);
      expect(safe['deviceTestingStillRequiredBeforeCommercialClaim'], isTrue);
      expect(safe['mapsRequiredForSimulation'], isFalse);
      expect(safe['rawSamplesIncluded'], isFalse);
      expect(safe['preciseLocationIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
    },
  );
}
