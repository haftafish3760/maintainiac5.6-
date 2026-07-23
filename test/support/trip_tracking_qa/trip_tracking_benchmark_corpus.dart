import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

import 'trip_tracking_benchmark_reporter.dart';
import 'trip_tracking_scenarios.dart';
import 'trip_tracking_simulator.dart';

/// Representative deterministic event corpus. The fixtures are deliberately
/// non-geographic: each contributes only replay outcomes and known advisory
/// expectations. Field routes are required before any real-device metric is
/// claimed.
class TripTrackingBenchmarkCorpus {
  TripTrackingBenchmarkCorpus({DateTime? start})
    : _scenarios = TripTrackingScenarioLibrary(start: start);

  final TripTrackingScenarioLibrary _scenarios;

  List<TripTrackingBenchmarkCase> build() => [
    _case(
      id: 'normal_known_distance',
      category: TripTrackingBenchmarkCategory.normalOpenSky,
      profile: TripTrackingProfile.roadVehicle,
      expectedDistanceMeters: 910.86,
      expectedStopReview: false,
      points: _knownDistanceRoute(
        latitude: 35,
        longitudeStep: .001,
        secondsPerSample: 10,
        speedMetersPerSecond: 9.1,
      ),
    ),
    _case(
      id: 'rural_known_distance',
      category: TripTrackingBenchmarkCategory.rural,
      profile: TripTrackingProfile.roadVehicle,
      expectedDistanceMeters: 1703.61,
      expectedStopReview: false,
      points: _knownDistanceRoute(
        latitude: 40,
        longitudeStep: .002,
        secondsPerSample: 20,
        speedMetersPerSecond: 8.52,
      ),
    ),
    _case(
      id: 'normal_delivery_walk',
      category: TripTrackingBenchmarkCategory.normalOpenSky,
      profile: TripTrackingProfile.deliveryVehicle,
      expectedStopReview: true,
      points: _scenarios.deliveryDriverLeavesVehicle(),
    ),
    _case(
      id: 'normal_contractor_walk',
      category: TripTrackingBenchmarkCategory.normalOpenSky,
      profile: TripTrackingProfile.contractorVehicle,
      expectedStopReview: true,
      points: _scenarios.contractorJobsiteWalkAround(),
    ),
    _case(
      id: 'urban_stationary_drift',
      category: TripTrackingBenchmarkCategory.urban,
      profile: TripTrackingProfile.roadVehicle,
      expectedDistanceMeters: 0,
      expectedStopReview: false,
      points: _stationaryUrbanDrift(),
    ),
    _case(
      id: 'urban_traffic_light',
      category: TripTrackingBenchmarkCategory.urban,
      profile: TripTrackingProfile.deliveryVehicle,
      expectedStopReview: false,
      points: _scenarios.longTrafficLightWithUrbanJitter(),
    ),
    _case(
      id: 'urban_pickup_queue',
      category: TripTrackingBenchmarkCategory.urban,
      profile: TripTrackingProfile.rideshareVehicle,
      expectedStopReview: false,
      points: _scenarios.ridesharePickupQueueCreepingTraffic(),
    ),
    _case(
      id: 'rural_multi_stop_delivery',
      category: TripTrackingBenchmarkCategory.rural,
      profile: TripTrackingProfile.deliveryVehicle,
      expectedStopReview: true,
      points: _scenarios.deliveryMultiStopRouteWithWalkingProof(),
    ),
    _case(
      id: 'degraded_gps_jump_gap',
      category: TripTrackingBenchmarkCategory.degraded,
      profile: TripTrackingProfile.deliveryVehicle,
      expectedStopReview: false,
      points: _scenarios.gpsJumpAndGapMasqueradingAsStop(),
    ),
    _case(
      id: 'severe_hostile_provider',
      category: TripTrackingBenchmarkCategory.severeInterruption,
      profile: TripTrackingProfile.deliveryVehicle,
      expectedStopReview: false,
      points: _scenarios.hostileProviderReplay(),
    ),
  ];

  TripTrackingBenchmarkCase _case({
    required String id,
    required TripTrackingBenchmarkCategory category,
    required TripTrackingProfile profile,
    required bool expectedStopReview,
    required List<SimulatedTripPoint> points,
    double? expectedDistanceMeters,
  }) => TripTrackingBenchmarkCase(
    id: id,
    category: category,
    expectedDistanceMeters: expectedDistanceMeters,
    expectedStopReview: expectedStopReview,
    run: () => replayTrip(points, profile: profile),
    stopReviewDetector: (result) =>
        result.toSafeDashboardSummary(
          profile: profile,
        )['stopCanSuggestReview'] ==
        true,
  );

  List<SimulatedTripPoint> _stationaryUrbanDrift() =>
      List.generate(120, (index) {
        final jitter = index.isEven ? .000012 : -.000012;
        return SimulatedTripPoint(
          _scenarios.roadPoint(-80 + jitter, index * 5, speed: 0),
        );
      });

  List<SimulatedTripPoint> _knownDistanceRoute({
    required double latitude,
    required double longitudeStep,
    required int secondsPerSample,
    required double speedMetersPerSecond,
  }) => List.generate(
    11,
    (index) => SimulatedTripPoint(
      _scenarios.roadPoint(
        -80 + (longitudeStep * index),
        secondsPerSample * index,
        latitude: latitude,
        speed: speedMetersPerSecond,
      ),
    ),
  );
}
