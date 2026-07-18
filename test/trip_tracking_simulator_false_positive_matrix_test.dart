import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_false_positive_guard.dart';
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

  test('simulator false-positive matrix stays profile bounded', () {
    final cases = <_SimulationCase>[
      _SimulationCase(
        name: 'delivery leaves vehicle',
        profile: TripTrackingProfile.deliveryVehicle,
        points: scenarios.deliveryDriverLeavesVehicle(),
        expectsReview: true,
        expectedSignal: 'review_only_stop',
      ),
      _SimulationCase(
        name: 'contractor walks jobsite',
        profile: TripTrackingProfile.contractorVehicle,
        points: scenarios.contractorJobsiteWalkAround(),
        expectsReview: true,
        expectedSignal: 'review_only_stop',
      ),
      _SimulationCase(
        name: 'rideshare phone stays in vehicle',
        profile: TripTrackingProfile.rideshareVehicle,
        points: scenarios.rideshareDriverStaysInVehicle(),
        expectsReview: false,
        expectedSignal: 'likely_traffic_control',
      ),
      _SimulationCase(
        name: 'delivery long traffic light',
        profile: TripTrackingProfile.deliveryVehicle,
        points: scenarios.longTrafficLightWithUrbanJitter(),
        expectsReview: false,
        expectedSignal: 'likely_traffic_control',
      ),
      _SimulationCase(
        name: 'two-person delivery phone parked',
        profile: TripTrackingProfile.deliveryVehicle,
        points: scenarios.deliveryPhoneStaysInVehicleAtCustomerStop(),
        expectsReview: false,
        expectedSignal: 'likely_traffic_control',
      ),
      _SimulationCase(
        name: 'rideshare airport queue',
        profile: TripTrackingProfile.rideshareVehicle,
        points: commercial.rideshareAirportQueueLongWait(),
        expectsReview: false,
        expectedSignal: 'likely_traffic_control',
      ),
      _SimulationCase(
        name: 'provider burst then recovery',
        profile: TripTrackingProfile.deliveryVehicle,
        points: commercial.deliveryProviderBurstThenRecoveryDrive(),
        expectsReview: false,
        expectedSignal: 'no_stop',
      ),
      _SimulationCase(
        name: 'stoplight then confirmed door walk',
        profile: TripTrackingProfile.deliveryVehicle,
        points: commercial.deliveryStoplightThenConfirmedDoorWalk(),
        expectsReview: true,
        expectedSignal: 'review_only_stop',
      ),
    ];

    for (final entry in cases) {
      final result = replayTrip(entry.points, profile: entry.profile);
      final summary = result.toSafeDashboardSummary(profile: entry.profile);
      final guard = summary['falsePositiveGuard'] as Map<String, Object?>;

      expect(
        result.needsWalkingReview,
        entry.expectsReview,
        reason: entry.name,
      );
      expect(summary['stopSignal'], entry.expectedSignal, reason: entry.name);
      expect(
        summary['stopCanSuggestReview'],
        entry.expectsReview,
        reason: entry.name,
      );
      expect(
        guard['status'],
        TripStopFalsePositiveGuardStatus.passed.name,
        reason: entry.name,
      );
      expect(guard['officialStopRequiresUserAction'], isTrue);
      expect(guard['mapboxCanOverrideFalsePositiveGuard'], isFalse);
      expect(guard['firestoreCanOverrideFalsePositiveGuard'], isFalse);
      expect(summary['stopCanCreateOfficialStop'], isFalse);
      expect(summary['stopCanReplaceOdometer'], isFalse);
      expect(summary['mapsRequiredForStopReview'], isFalse);
      expect(summary.toString(), isNot(contains('pk.')));
      expect(summary.toString(), isNot(contains('sk.')));
      expect(summary.toString(), isNot(contains('35.')));
      expect(summary.toString(), isNot(contains('-79.')));
    }
  });

  test('forged simulator summaries cannot bypass false-positive guard', () {
    final result = replayTrip(
      scenarios.deliveryDriverLeavesVehicle(),
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final classification = {
      'schemaVersion': 1,
      'canCreateOfficialStop': false,
      'canEndTripAutomatically': false,
      'officialStopSource': 'user_review',
      'officialMileageSource': 'odometer',
      'mapboxCanCreateStop': true,
    };

    final remote = TripStopFalsePositiveGuard.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      status: 'readyForReview',
      classification: classification,
      vehicleOnlyDwell: null,
      needsWalkingReview: true,
      protectedTrafficControl: false,
      canOpenReview: true,
    );
    final noWalking = TripStopFalsePositiveGuard.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      status: 'readyForReview',
      classification: {...classification, 'mapboxCanCreateStop': false},
      vehicleOnlyDwell: null,
      needsWalkingReview: false,
      protectedTrafficControl: false,
      canOpenReview: true,
    );
    final traffic = TripStopFalsePositiveGuard.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      status: 'trafficControlProtected',
      classification: {...classification, 'mapboxCanCreateStop': false},
      vehicleOnlyDwell: null,
      needsWalkingReview: false,
      protectedTrafficControl: true,
      canOpenReview: true,
    );

    expect(summary['stopCanSuggestReview'], isTrue);
    expect(
      remote.status,
      TripStopFalsePositiveGuardStatus.blockedRemoteAuthority,
    );
    expect(
      noWalking.status,
      TripStopFalsePositiveGuardStatus.blockedReviewWithoutWalkingEvidence,
    );
    expect(
      traffic.status,
      TripStopFalsePositiveGuardStatus.blockedTrafficControlReview,
    );
    expect(remote.canAllowReviewOpen, isFalse);
    expect(noWalking.canAllowReviewOpen, isFalse);
    expect(traffic.canAllowReviewOpen, isFalse);
  });
}

class _SimulationCase {
  const _SimulationCase({
    required this.name,
    required this.profile,
    required this.points,
    required this.expectsReview,
    required this.expectedSignal,
  });

  final String name;
  final TripTrackingProfile profile;
  final List<SimulatedTripPoint> points;
  final bool expectsReview;
  final String expectedSignal;
}
