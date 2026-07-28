import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

import 'support/trip_tracking_qa/trip_tracking_scenarios.dart';
import 'support/trip_tracking_qa/trip_tracking_simulator.dart';

void main() {
  test(
    'commercial workday excludes walking and recovers after urban signal loss',
    () {
      final scenarios = TripTrackingScenarioLibrary(
        start: DateTime.utc(2026, 7, 26, 8),
      );
      final points = <SimulatedTripPoint>[
        SimulatedTripPoint(scenarios.roadPoint(-80, 0, speed: 10)),
        SimulatedTripPoint(scenarios.roadPoint(-79.999, 20, speed: 10)),
        SimulatedTripPoint(scenarios.roadPoint(-79.998, 40, speed: 9)),
        SimulatedTripPoint(scenarios.roadPoint(-79.998006, 55, speed: 0)),
        SimulatedTripPoint(
          scenarios.roadPoint(-79.99795, 70, speed: 0),
          activity: scenarios.activity(TripActivity.walking, 70),
        ),
        SimulatedTripPoint(
          scenarios.roadPoint(-79.99788, 90, speed: 0),
          activity: scenarios.activity(TripActivity.walking, 90),
        ),
        SimulatedTripPoint(
          scenarios.roadPoint(-79.99782, 110, speed: 0),
          activity: scenarios.activity(TripActivity.walking, 110),
        ),
        SimulatedTripPoint(
          scenarios.roadPoint(-79.99780, 135, speed: 0),
          activity: scenarios.activity(TripActivity.still, 135),
        ),
        SimulatedTripPoint(scenarios.roadPoint(-79.997, 175, speed: 9)),
        SimulatedTripPoint(scenarios.roadPoint(-79.996, 195, speed: 9)),
        SimulatedTripPoint(
          scenarios.roadPoint(-79.9957, 210, accuracy: 115, speed: 8),
        ),
        SimulatedTripPoint(
          scenarios.roadPoint(-79.9952, 225, accuracy: 140, speed: 8),
        ),
        SimulatedTripPoint(scenarios.roadPoint(-79.995, 250, speed: 8)),
        SimulatedTripPoint(scenarios.roadPoint(-79.990, 610, speed: 10)),
        SimulatedTripPoint(scenarios.roadPoint(-79.989, 630, speed: 10)),
        SimulatedTripPoint(scenarios.roadPoint(-79.988, 650, speed: 10)),
      ];

      final result = replayTrip(
        points,
        profile: TripTrackingProfile.deliveryVehicle,
      );
      final summary = result.toSafeDashboardSummary(
        profile: TripTrackingProfile.deliveryVehicle,
      );

      expect(result.excludedWalkingCount, greaterThanOrEqualTo(3));
      expect(
        result.count(TripSampleDisposition.rejectedAccuracy),
        greaterThanOrEqualTo(2),
      );
      expect(result.count(TripSampleDisposition.rejectedGap), 1);
      expect(result.acceptedDistanceCount, greaterThanOrEqualTo(6));
      expect(result.motionState, TripMotionState.moving);
      expect(result.acceptedMeters, greaterThan(400));
      expect(result.acceptedMeters, lessThan(1000));
      expect(summary['officialMileageSource'], 'odometer');
      expect(summary['simulationCanReplaceOdometer'], isFalse);
      expect(summary['stopCanCreateOfficialStop'], isFalse);
      expect(summary['coordinatesIncluded'], isFalse);
      expect(summary['routeGeometryIncluded'], isFalse);
    },
  );
}
