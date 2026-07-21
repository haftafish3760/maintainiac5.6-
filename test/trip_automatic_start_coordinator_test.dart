import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_start_detector.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  final at = DateTime.utc(2026, 7, 21, 12);
  List<TripAutomaticStartObservation> evidence() => List.generate(
    3,
    (index) => TripAutomaticStartObservation(
      recordedAt: at.add(Duration(seconds: index * 15)),
      speedMetersPerSecond: 8,
      displacementMeters: 30,
      horizontalAccuracyMeters: 8,
      activity: index == 1 ? TripActivity.automotive : TripActivity.unknown,
      activityConfidence: index == 1 ? 90 : 0,
      bluetoothVehicleId: 'vehicle_1',
    ),
  );

  test('coordinator requires explicit automatic-start opt-in', () {
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
    );
    addTearDown(controller.dispose);

    final disabled = controller.evaluateAutomaticStartAssistance(
      settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
      observations: evidence(),
    );
    final enabled = controller.evaluateAutomaticStartAssistance(
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        automaticStartAssistanceEnabled: true,
      ),
      observations: evidence(),
    );
    expect(disabled.disposition, TripAutomaticStartDisposition.disabled);
    expect(enabled.disposition, TripAutomaticStartDisposition.candidate);
    expect(enabled.canFinalizeTripLog, isFalse);
  });

  test('durable unfinished session suppresses automatic start', () async {
    final store = TripTrackingSessionStore.memory();
    await store.save(
      TripTrackingSessionRecord(
        id: 'existing_trip',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: at,
        updatedAt: at,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: false,
        ),
      ),
    );
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
    );
    addTearDown(controller.dispose);

    final decision = controller.evaluateAutomaticStartAssistance(
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        automaticStartAssistanceEnabled: true,
      ),
      observations: evidence(),
    );
    expect(
      decision.disposition,
      TripAutomaticStartDisposition.activeSessionExists,
    );
  });
}
