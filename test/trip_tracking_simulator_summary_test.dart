import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

import 'support/trip_tracking_qa/trip_tracking_scenarios.dart';
import 'support/trip_tracking_qa/trip_tracking_simulator.dart';

void main() {
  test('simulation harness exposes compact privacy-safe replay summaries', () {
    final scenarios = TripTrackingScenarioLibrary();
    final result = replayTrip(
      scenarios.deliveryDriverLeavesVehicle(),
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final summary = result.toSafeSummary();

    expect(summary['needsWalkingReview'], isTrue);
    expect(summary['motionState'], 'moving');
    expect(summary['acceptedDistanceCount'], greaterThanOrEqualTo(3));
    expect(summary['rejectedCount'], greaterThanOrEqualTo(4));
    expect(summary['acceptedMiles'], isA<double>());
    expect(summary['rawSamplesIncluded'], isFalse);
    expect(summary['coordinatesIncluded'], isFalse);
    expect(summary['routeGeometryIncluded'], isFalse);
    expect(summary.keys, isNot(contains('samples')));
    expect(summary.keys, isNot(contains('latitude')));
    expect(summary.keys, isNot(contains('longitude')));
  });

  test(
    'hostile provider replay summary stays bounded and non-authoritative',
    () {
      final scenarios = TripTrackingScenarioLibrary();
      final result = replayTrip(scenarios.hostileProviderReplay());
      final summary = result.toSafeSummary();

      expect(summary['acceptedMiles'], lessThan(.1));
      expect(summary['rejectedCount'], greaterThanOrEqualTo(6));
      expect(summary.toString(), isNot(contains('-79.')));
      expect(summary.toString(), isNot(contains('35.')));
    },
  );
}
