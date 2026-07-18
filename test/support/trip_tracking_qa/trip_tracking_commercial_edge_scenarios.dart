import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

import 'trip_tracking_simulator.dart';

class TripTrackingCommercialEdgeScenarios {
  TripTrackingCommercialEdgeScenarios({DateTime? start})
    : start = start ?? DateTime.utc(2026, 7, 18, 8);

  final DateTime start;

  TripLocationSample roadPoint(
    double longitude,
    int seconds, {
    double latitude = 35,
    double accuracy = 5,
    double? speed,
  }) => TripLocationSample(
    latitude: latitude,
    longitude: longitude,
    recordedAt: start.add(Duration(seconds: seconds)),
    horizontalAccuracyMeters: accuracy,
    speedMetersPerSecond: speed,
  );

  TripActivityObservation activity(
    TripActivity activity,
    int seconds, {
    int confidence = 95,
  }) => TripActivityObservation(
    activity: activity,
    confidence: confidence,
    recordedAt: start.add(Duration(seconds: seconds)),
  );

  List<SimulatedTripPoint> rideshareAirportQueueLongWait() {
    final points = <SimulatedTripPoint>[
      SimulatedTripPoint(roadPoint(-80, 0, speed: 11)),
      SimulatedTripPoint(roadPoint(-79.9991, 20, speed: 10)),
      SimulatedTripPoint(roadPoint(-79.9984, 42, speed: 6)),
    ];
    for (var index = 0; index < 22; index += 1) {
      points.add(
        SimulatedTripPoint(
          roadPoint(
            -79.9984 + ((index.isEven ? 1 : -1) * .000006),
            60 + (index * 14),
            speed: index % 4 == 0 ? .7 : 0,
          ),
          activity: activity(TripActivity.automotive, 60 + (index * 14)),
        ),
      );
    }
    points.addAll([
      SimulatedTripPoint(roadPoint(-79.9978, 390, speed: 6)),
      SimulatedTripPoint(roadPoint(-79.9970, 420, speed: 9)),
    ]);
    return points;
  }

  List<SimulatedTripPoint> deliveryApartmentComplexMultiDoorWalks() => [
    SimulatedTripPoint(roadPoint(-80, 0, speed: 9)),
    SimulatedTripPoint(roadPoint(-79.9992, 22, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.9987, 44, speed: 4)),
    SimulatedTripPoint(
      roadPoint(-79.99866, 62, speed: 0),
      activity: activity(TripActivity.walking, 62),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99860, 78, speed: 0),
      activity: activity(TripActivity.walking, 78),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99854, 96, speed: 0),
      activity: activity(TripActivity.walking, 96),
    ),
    SimulatedTripPoint(roadPoint(-79.9980, 135, speed: 5)),
    SimulatedTripPoint(roadPoint(-79.9975, 160, speed: 5)),
    SimulatedTripPoint(
      roadPoint(-79.99745, 182, speed: 0),
      activity: activity(TripActivity.walking, 182),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99739, 198, speed: 0),
      activity: activity(TripActivity.walking, 198),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99732, 216, speed: 0),
      activity: activity(TripActivity.walking, 216),
    ),
    SimulatedTripPoint(roadPoint(-79.9967, 255, speed: 8)),
  ];

  List<SimulatedTripPoint> contractorSupplyCounterThenJobsiteWalk() => [
    SimulatedTripPoint(roadPoint(-80, 0, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.999, 20, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.998, 42, speed: 8)),
    SimulatedTripPoint(
      roadPoint(-79.99794, 63, speed: 0),
      activity: activity(TripActivity.walking, 63),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99786, 82, speed: 0),
      activity: activity(TripActivity.walking, 82),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99778, 101, speed: 0),
      activity: activity(TripActivity.walking, 101),
    ),
    SimulatedTripPoint(roadPoint(-79.9969, 150, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.9960, 174, speed: 8)),
    SimulatedTripPoint(
      roadPoint(-79.99594, 198, speed: 0),
      activity: activity(TripActivity.walking, 198),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99582, 220, speed: 0),
      activity: activity(TripActivity.walking, 220),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99570, 242, speed: 0),
      activity: activity(TripActivity.walking, 242),
    ),
  ];

  List<SimulatedTripPoint> deliveryStoplightThenConfirmedDoorWalk() {
    final points = <SimulatedTripPoint>[
      SimulatedTripPoint(roadPoint(-80, 0, speed: 9)),
      SimulatedTripPoint(roadPoint(-79.9992, 22, speed: 9)),
      SimulatedTripPoint(roadPoint(-79.9986, 44, speed: 4)),
    ];
    for (var index = 0; index < 12; index += 1) {
      points.add(
        SimulatedTripPoint(
          roadPoint(
            -79.9986 + ((index.isEven ? 1 : -1) * .000006),
            60 + (index * 10),
            speed: index.isEven ? .2 : 0,
          ),
          activity: activity(TripActivity.automotive, 60 + (index * 10)),
        ),
      );
    }
    points.addAll([
      SimulatedTripPoint(roadPoint(-79.9978, 205, speed: 8)),
      SimulatedTripPoint(roadPoint(-79.9971, 228, speed: 7)),
      SimulatedTripPoint(
        roadPoint(-79.99704, 248, speed: 0),
        activity: activity(TripActivity.walking, 248),
      ),
      SimulatedTripPoint(
        roadPoint(-79.99698, 266, speed: 0),
        activity: activity(TripActivity.walking, 266),
      ),
      SimulatedTripPoint(
        roadPoint(-79.99691, 286, speed: 0),
        activity: activity(TripActivity.walking, 286),
      ),
    ]);
    return points;
  }

  List<SimulatedTripPoint> rideshareBriefWalkAtPickupDoor() => [
    SimulatedTripPoint(roadPoint(-80, 0, speed: 10)),
    SimulatedTripPoint(roadPoint(-79.9992, 20, speed: 9)),
    SimulatedTripPoint(roadPoint(-79.9986, 40, speed: 5)),
    SimulatedTripPoint(
      roadPoint(-79.99855, 58, speed: 0),
      activity: activity(TripActivity.walking, 58),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99850, 68, speed: 0),
      activity: activity(TripActivity.walking, 68),
    ),
    SimulatedTripPoint(roadPoint(-79.9978, 98, speed: 8)),
  ];

  List<SimulatedTripPoint> deliveryProviderBurstThenRecoveryDrive() => [
    SimulatedTripPoint(roadPoint(-80, 0, speed: 9)),
    SimulatedTripPoint(roadPoint(-79.9992, 20, speed: 9)),
    SimulatedTripPoint(roadPoint(-79.9700, 21, speed: 0)),
    SimulatedTripPoint(roadPoint(-79.9990, 40, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.9982, 62, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.9974, 84, speed: 8)),
  ];

  List<SimulatedTripPoint> deliveryDriveThruQueueThenDoorWalk() {
    final points = <SimulatedTripPoint>[
      SimulatedTripPoint(roadPoint(-80, 0, speed: 8)),
      SimulatedTripPoint(roadPoint(-79.9993, 22, speed: 7)),
    ];
    for (var index = 0; index < 14; index += 1) {
      points.add(
        SimulatedTripPoint(
          roadPoint(
            -79.9993 + (.000018 * index),
            45 + (index * 18),
            speed: index.isEven ? .9 : .2,
          ),
          activity: activity(TripActivity.automotive, 45 + (index * 18)),
        ),
      );
    }
    points.addAll([
      SimulatedTripPoint(roadPoint(-79.9984, 320, speed: 8)),
      SimulatedTripPoint(roadPoint(-79.9978, 345, speed: 7)),
      SimulatedTripPoint(
        roadPoint(-79.99774, 368, speed: 0),
        activity: activity(TripActivity.walking, 368),
      ),
      SimulatedTripPoint(
        roadPoint(-79.99768, 386, speed: 0),
        activity: activity(TripActivity.walking, 386),
      ),
      SimulatedTripPoint(
        roadPoint(-79.99762, 405, speed: 0),
        activity: activity(TripActivity.walking, 405),
      ),
    ]);
    return points;
  }

  List<SimulatedTripPoint> ridesharePassengerSwapNoDriverWalk() {
    final points = <SimulatedTripPoint>[
      SimulatedTripPoint(roadPoint(-80, 0, speed: 10)),
      SimulatedTripPoint(roadPoint(-79.9990, 22, speed: 9)),
      SimulatedTripPoint(roadPoint(-79.9983, 45, speed: 5)),
    ];
    for (var index = 0; index < 12; index += 1) {
      points.add(
        SimulatedTripPoint(
          roadPoint(
            -79.9983 + ((index.isEven ? 1 : -1) * .000004),
            70 + (index * 16),
            speed: index % 3 == 0 ? .4 : 0,
          ),
          activity: activity(TripActivity.automotive, 70 + (index * 16)),
        ),
      );
    }
    points.addAll([
      SimulatedTripPoint(roadPoint(-79.9976, 290, speed: 8)),
      SimulatedTripPoint(roadPoint(-79.9969, 315, speed: 8)),
    ]);
    return points;
  }

  List<SimulatedTripPoint> contractorBackToBackShortJobs() => [
    SimulatedTripPoint(roadPoint(-80, 0, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.9991, 22, speed: 8)),
    SimulatedTripPoint(
      roadPoint(-79.99904, 45, speed: 0),
      activity: activity(TripActivity.walking, 45),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99898, 64, speed: 0),
      activity: activity(TripActivity.walking, 64),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99892, 84, speed: 0),
      activity: activity(TripActivity.walking, 84),
    ),
    SimulatedTripPoint(roadPoint(-79.9980, 135, speed: 8)),
    SimulatedTripPoint(roadPoint(-79.9971, 160, speed: 8)),
    SimulatedTripPoint(
      roadPoint(-79.99704, 184, speed: 0),
      activity: activity(TripActivity.walking, 184),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99696, 205, speed: 0),
      activity: activity(TripActivity.walking, 205),
    ),
    SimulatedTripPoint(
      roadPoint(-79.99688, 226, speed: 0),
      activity: activity(TripActivity.walking, 226),
    ),
  ];
}
