import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

import 'support/trip_tracking_qa/trip_tracking_scenarios.dart';
import 'support/trip_tracking_qa/trip_tracking_simulator.dart';

void main() {
  final scenarios = TripTrackingScenarioLibrary(
    start: DateTime.utc(2026, 7, 27, 8),
  );

  test('garage exit reanchors after a covered-signal gap without bridge miles', () {
    final result = replayTrip([
      SimulatedTripPoint(scenarios.roadPoint(-80, 0, speed: 8)),
      SimulatedTripPoint(scenarios.roadPoint(-79.999, 20, speed: 8)),
      SimulatedTripPoint(scenarios.roadPoint(-79.990, 190, speed: 8)),
      SimulatedTripPoint(scenarios.roadPoint(-79.989, 210, speed: 8)),
      SimulatedTripPoint(scenarios.roadPoint(-79.988, 230, speed: 8)),
    ], profile: TripTrackingProfile.deliveryVehicle);

    expect(result.count(TripSampleDisposition.rejectedGap), 1);
    expect(result.acceptedDistanceCount, greaterThanOrEqualTo(3));
    expect(result.acceptedMeters, greaterThan(150));
    expect(result.acceptedMeters, lessThan(400));
    expect(
      result.toSafeDashboardSummary(
        profile: TripTrackingProfile.deliveryVehicle,
      )['officialMileageSource'],
      'odometer',
    );
  });

  test('downtown queue and real delivery walk remain separate evidence', () {
    final points = <SimulatedTripPoint>[
      SimulatedTripPoint(scenarios.roadPoint(-80, 0, speed: 9)),
      SimulatedTripPoint(scenarios.roadPoint(-79.999, 20, speed: 9)),
      SimulatedTripPoint(scenarios.roadPoint(-79.998, 40, speed: 8)),
      for (var index = 0; index < 7; index += 1)
        SimulatedTripPoint(
          scenarios.roadPoint(
            -79.998 + (index.isEven ? .000006 : -.000006),
            55 + (index * 12),
            speed: 0,
          ),
          activity: scenarios.activity(TripActivity.automotive, 55 + (index * 12)),
        ),
      SimulatedTripPoint(
        scenarios.roadPoint(-79.99794, 155, speed: 0),
        activity: scenarios.activity(TripActivity.walking, 155),
      ),
      SimulatedTripPoint(
        scenarios.roadPoint(-79.99786, 175, speed: 0),
        activity: scenarios.activity(TripActivity.walking, 175),
      ),
      SimulatedTripPoint(
        scenarios.roadPoint(-79.99778, 195, speed: 0),
        activity: scenarios.activity(TripActivity.walking, 195),
      ),
      SimulatedTripPoint(scenarios.roadPoint(-79.997, 230, speed: 8)),
      SimulatedTripPoint(scenarios.roadPoint(-79.996, 250, speed: 8)),
    ];
    final result = replayTrip(
      points,
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.count(TripSampleDisposition.rejectedDrift), greaterThan(4));
    expect(result.excludedWalkingCount, greaterThanOrEqualTo(3));
    expect(result.needsWalkingReview, isTrue);
    expect(summary['stopCanCreateOfficialStop'], isFalse);
    expect(summary['simulationCanReplaceOdometer'], isFalse);
  });
}
