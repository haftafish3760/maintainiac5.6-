import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_simulation_readiness_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

import 'support/trip_tracking_qa/trip_tracking_commercial_edge_scenarios.dart';
import 'support/trip_tracking_qa/trip_tracking_scenarios.dart';
import 'support/trip_tracking_qa/trip_tracking_simulator.dart';

void main() {
  final scenarios = TripTrackingScenarioLibrary(
    start: DateTime.utc(2026, 7, 18, 8),
  );
  final commercial = TripTrackingCommercialEdgeScenarios(
    start: DateTime.utc(2026, 7, 18, 8),
  );

  TripSimulationReadinessDecision evaluate(
    List<SimulatedTripPoint> points, {
    required TripTrackingProfile profile,
    required bool expectedStopReview,
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
      expectedVehicleMovement: true,
    );
  }

  test(
    'profile-specific commercial simulations validate for field trial prep',
    () {
      final delivery = evaluate(
        commercial.deliveryApartmentComplexMultiDoorWalks(),
        profile: TripTrackingProfile.deliveryVehicle,
        expectedStopReview: true,
      );
      final contractor = evaluate(
        commercial.contractorSupplyCounterThenJobsiteWalk(),
        profile: TripTrackingProfile.contractorVehicle,
        expectedStopReview: true,
      );
      final rideshare = evaluate(
        commercial.ridesharePassengerSwapNoDriverWalk(),
        profile: TripTrackingProfile.rideshareVehicle,
        expectedStopReview: false,
      );

      expect(delivery.status, TripSimulationReadinessStatus.readyForFieldTrial);
      expect(
        contractor.status,
        TripSimulationReadinessStatus.readyForFieldTrial,
      );
      expect(
        rideshare.status,
        TripSimulationReadinessStatus.readyForFieldTrial,
      );
      expect(delivery.stopReviewSuggested, isTrue);
      expect(contractor.stopReviewSuggested, isTrue);
      expect(rideshare.stopReviewSuggested, isFalse);
    },
  );

  test(
    'traffic and fast-door-drop simulations stay out of automatic stops',
    () {
      final traffic = evaluate(
        scenarios.longTrafficLightWithUrbanJitter(),
        profile: TripTrackingProfile.deliveryVehicle,
        expectedStopReview: false,
      );
      final fastDoorDrop = evaluate(
        scenarios.fastDoorDropWithTooLittleWalkingEvidence(),
        profile: TripTrackingProfile.deliveryVehicle,
        expectedStopReview: false,
      );

      expect(traffic.status, TripSimulationReadinessStatus.readyForFieldTrial);
      expect(
        fastDoorDrop.status,
        TripSimulationReadinessStatus.readyForFieldTrial,
      );
      expect(traffic.stopReviewSuggested, isFalse);
      expect(fastDoorDrop.stopReviewSuggested, isFalse);
    },
  );

  test('safe simulation summary validates as advisory and profile bounded', () {
    final validation = TripSimulationReadinessSummaryValidation.fromSummary(
      evaluate(
        scenarios.contractorLongJobsiteWalkThenDriveAway(),
        profile: TripTrackingProfile.contractorVehicle,
        expectedStopReview: true,
      ).toSafeDashboardMap(),
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.status, TripSimulationReadinessStatus.readyForFieldTrial);
    expect(validation.reasons, isEmpty);
  });

  test(
    'simulation summary rejects official-truth, Mapbox, and privacy claims',
    () {
      final validation = TripSimulationReadinessSummaryValidation.fromSummary(
        evaluate(
          scenarios.deliveryDriverLeavesVehicle(),
          profile: TripTrackingProfile.deliveryVehicle,
          expectedStopReview: true,
        ).toSafeDashboardMap()..addAll({
          'simulationCanCreateOfficialStop': true,
          'simulationCanConfirmOdometer': true,
          'simulationCanDeleteLocalData': true,
          'odometerRemainsOfficialMileageTruth': false,
          'deviceTestingStillRequiredBeforeCommercialClaim': false,
          'mapsRequiredForSimulation': true,
          'mapboxCanMakeSimulationPass': true,
          'simulationRequiresProfileSpecificExpectations': false,
          'deliveryStopRequiresWalkingOrManualReviewEvidence': false,
          'contractorStopRequiresWalkingOrManualReviewEvidence': false,
          'rideshareVehicleOnlyStopsStayManualFallback': false,
          'trafficControlMustStayOutOfStopReview': false,
          'rawSamplesIncluded': true,
          'preciseLocationIncluded': true,
          'routeGeometryIncluded': true,
          'tokensIncluded': true,
          'debug': 'pk.public 35.123456,-80.123456',
        }),
      );

      expect(validation.isRenderable, isFalse);
      expect(
        validation.reasons,
        contains('simulation_can_create_official_truth'),
      );
      expect(
        validation.reasons,
        contains('device_testing_requirement_missing'),
      );
      expect(validation.reasons, contains('maps_can_control_simulation'));
      expect(
        validation.reasons,
        contains('profile_expectation_boundary_missing'),
      );
      expect(
        validation.reasons,
        contains('summary_contains_sensitive_trip_material'),
      );
      expect(validation.reasons, contains('summary_contains_sensitive_text'));
    },
  );
}
