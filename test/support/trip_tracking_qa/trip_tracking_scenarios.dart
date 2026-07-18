import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

import 'trip_tracking_simulator.dart';

class TripTrackingScenarioLibrary {
  TripTrackingScenarioLibrary({DateTime? start})
    : start = start ?? DateTime.utc(2026, 7, 17, 8);

  final DateTime start;

  TripLocationSample roadPoint(
    double longitude,
    int seconds, {
    double latitude = 35,
    double accuracy = 5,
    double? speed,
    bool? mockedLocation,
  }) {
    return TripLocationSample(
      latitude: latitude,
      longitude: longitude,
      recordedAt: start.add(Duration(seconds: seconds)),
      horizontalAccuracyMeters: accuracy,
      speedMetersPerSecond: speed,
      mockedLocation: mockedLocation,
    );
  }

  TripActivityObservation activity(
    TripActivity activity,
    int seconds, {
    int confidence = 95,
  }) {
    return TripActivityObservation(
      activity: activity,
      confidence: confidence,
      recordedAt: start.add(Duration(seconds: seconds)),
    );
  }

  List<SimulatedTripPoint> deliveryDriverLeavesVehicle() => [
    SimulatedTripPoint(roadPoint(-80, 0, speed: 9)),
    SimulatedTripPoint(roadPoint(-79.999, 20, speed: 9)),
    SimulatedTripPoint(roadPoint(-79.998, 40, speed: 9)),
    SimulatedTripPoint(
      roadPoint(-79.99795, 55),
      activity: activity(TripActivity.walking, 55),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99788, 70),
      activity: activity(TripActivity.walking, 70),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99782, 85),
      activity: activity(TripActivity.walking, 85),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99775, 100),
      activity: activity(TripActivity.walking, 100),
    ),
    SimulatedTripPoint(roadPoint(-79.9968, 130, speed: 9)),
    SimulatedTripPoint(roadPoint(-79.9958, 150, speed: 9)),
  ];

  List<SimulatedTripPoint> rideshareDriverStaysInVehicle() => [
    SimulatedTripPoint(roadPoint(-80, 0, speed: 10)),
    SimulatedTripPoint(roadPoint(-79.999, 20, speed: 10)),
    SimulatedTripPoint(roadPoint(-79.998, 40, speed: 10)),
    ...List.generate(
      9,
      (index) => SimulatedTripPoint(
        roadPoint(
          -79.998 + ((index.isEven ? 1 : -1) * .000009),
          60 + (index * 12),
          speed: 0,
        ),
      ),
    ),
    SimulatedTripPoint(roadPoint(-79.997, 180, speed: 10)),
    SimulatedTripPoint(roadPoint(-79.996, 200, speed: 10)),
  ];

  List<SimulatedTripPoint> ridesharePickupQueueCreepingTraffic() {
    final points = <SimulatedTripPoint>[
      SimulatedTripPoint(roadPoint(-80, 0, speed: 9)),
      SimulatedTripPoint(roadPoint(-79.9993, 18, speed: 8)),
      SimulatedTripPoint(roadPoint(-79.9988, 36, speed: 5)),
    ];
    for (var index = 0; index < 10; index += 1) {
      points.add(
        SimulatedTripPoint(
          roadPoint(
            -79.9988 + (index * .000018),
            52 + (index * 14),
            speed: index.isEven ? .6 : 1.1,
          ),
          activity: activity(TripActivity.automotive, 52 + (index * 14)),
        ),
      );
    }
    points.addAll([
      SimulatedTripPoint(roadPoint(-79.9978, 210, speed: 8)),
      SimulatedTripPoint(roadPoint(-79.9969, 232, speed: 9)),
    ]);
    return points;
  }

  List<SimulatedTripPoint> rideshareDriverWalksAfterShiftStop() => [
    SimulatedTripPoint(roadPoint(-80, 0, speed: 10)),
    SimulatedTripPoint(roadPoint(-79.999, 20, speed: 10)),
    SimulatedTripPoint(roadPoint(-79.998, 40, speed: 10)),
    SimulatedTripPoint(
      roadPoint(-79.9979, 60),
      activity: activity(TripActivity.walking, 60),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99785, 75),
      activity: activity(TripActivity.walking, 75),
    ),
    SimulatedTripPoint(
      roadPoint(-79.9978, 90),
      activity: activity(TripActivity.walking, 90),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99775, 105),
      activity: activity(TripActivity.walking, 105),
    ),
  ];

  List<SimulatedTripPoint> contractorJobsiteWalkAround() => [
    SimulatedTripPoint(roadPoint(-80, 0, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.999, 20, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.998, 40, speed: 8)),
    SimulatedTripPoint(
      roadPoint(-79.99795, 60),
      activity: activity(TripActivity.walking, 60),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99784, 80),
      activity: activity(TripActivity.walking, 80),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99772, 100),
      activity: activity(TripActivity.walking, 100),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99755, 120),
      activity: activity(TripActivity.walking, 120),
    ),
    SimulatedTripPoint(roadPoint(-79.9968, 170, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.9958, 190, speed: 8)),
  ];

  List<SimulatedTripPoint> deliveryMultiStopRouteWithWalkingProof() => [
    SimulatedTripPoint(roadPoint(-80, 0, speed: 9)),
    SimulatedTripPoint(roadPoint(-79.9992, 22, speed: 9)),
    SimulatedTripPoint(roadPoint(-79.9985, 44, speed: 8)),
    SimulatedTripPoint(
      roadPoint(-79.99845, 62),
      activity: activity(TripActivity.walking, 62),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99838, 78),
      activity: activity(TripActivity.walking, 78),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99832, 94),
      activity: activity(TripActivity.walking, 94),
    ),
    SimulatedTripPoint(roadPoint(-79.9974, 128, speed: 9)),
    SimulatedTripPoint(roadPoint(-79.9967, 150, speed: 8)),
    SimulatedTripPoint(
      roadPoint(-79.99665, 172),
      activity: activity(TripActivity.walking, 172),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99658, 188),
      activity: activity(TripActivity.walking, 188),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99651, 204),
      activity: activity(TripActivity.walking, 204),
    ),
    SimulatedTripPoint(roadPoint(-79.9957, 240, speed: 9)),
    SimulatedTripPoint(roadPoint(-79.9948, 264, speed: 9)),
  ];

  List<SimulatedTripPoint> deliveryPhoneStaysInVehicleAtCustomerStop() {
    final points = <SimulatedTripPoint>[
      SimulatedTripPoint(roadPoint(-80, 0, speed: 9)),
      SimulatedTripPoint(roadPoint(-79.9992, 22, speed: 9)),
      SimulatedTripPoint(roadPoint(-79.9984, 44, speed: 8)),
    ];
    for (var index = 0; index < 10; index += 1) {
      points.add(
        SimulatedTripPoint(
          roadPoint(
            -79.9984 + ((index.isEven ? 1 : -1) * .000006),
            64 + (index * 12),
            speed: 0,
          ),
        ),
      );
    }
    points.addAll([
      SimulatedTripPoint(roadPoint(-79.9975, 205, speed: 9)),
      SimulatedTripPoint(roadPoint(-79.9967, 228, speed: 9)),
    ]);
    return points;
  }

  List<SimulatedTripPoint> weakWalkingFalsePositiveWhileDriving() => [
    SimulatedTripPoint(roadPoint(-80, 0, speed: 10)),
    SimulatedTripPoint(roadPoint(-79.999, 20, speed: 10)),
    SimulatedTripPoint(
      roadPoint(-79.998, 40, speed: 10),
      activity: activity(TripActivity.walking, 40, confidence: 35),
    ),
    SimulatedTripPoint(
      roadPoint(-79.997, 60, speed: 10),
      activity: activity(TripActivity.walking, 60, confidence: 45),
    ),
    SimulatedTripPoint(roadPoint(-79.996, 80, speed: 10)),
  ];

  List<SimulatedTripPoint> longTrafficLightWithUrbanJitter() {
    final points = <SimulatedTripPoint>[
      SimulatedTripPoint(roadPoint(-80, 0, speed: 9)),
      SimulatedTripPoint(roadPoint(-79.999, 20, speed: 9)),
      SimulatedTripPoint(roadPoint(-79.998, 40, speed: 9)),
    ];
    for (var index = 0; index < 14; index += 1) {
      points.add(
        SimulatedTripPoint(
          roadPoint(
            -79.998 + ((index.isEven ? 1 : -1) * .000007),
            55 + (index * 10),
            speed: 0,
          ),
        ),
      );
    }
    points.addAll([
      SimulatedTripPoint(roadPoint(-79.997, 210, speed: 9)),
      SimulatedTripPoint(roadPoint(-79.996, 230, speed: 9)),
    ]);
    return points;
  }

  List<SimulatedTripPoint> hostileProviderReplay() => [
    SimulatedTripPoint(roadPoint(-80, 0, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.999, 20, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.9989, 20, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.99, 21, accuracy: 120, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.9988, 19, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.98, 180, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.9799, 190, accuracy: 120, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.9798, 185, speed: 8)),
    SimulatedTripPoint(
      TripLocationSample(
        latitude: double.nan,
        longitude: -79.9798,
        recordedAt: start.add(const Duration(seconds: 195)),
        horizontalAccuracyMeters: 5,
      ),
    ),
    SimulatedTripPoint(
      TripLocationSample(
        latitude: 35,
        longitude: -79.85,
        recordedAt: start.add(const Duration(seconds: 200)),
        horizontalAccuracyMeters: 3,
        mockedLocation: true,
      ),
    ),
    SimulatedTripPoint(roadPoint(-79.9796, 220, speed: 8)),
  ];
}
