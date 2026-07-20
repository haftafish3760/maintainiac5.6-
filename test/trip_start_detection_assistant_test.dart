import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_start_detection_assistant.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  final started = DateTime.utc(2026, 7, 20, 12);
  List<TripStartEvidenceObservation> evidence({bool independentHint = false}) =>
      [
        TripStartEvidenceObservation(
          observedAtUtc: started,
          credibleLocation: true,
          displacementMeters: 0,
          speedMetersPerSecond: 4,
        ),
        TripStartEvidenceObservation(
          observedAtUtc: started.add(const Duration(seconds: 10)),
          credibleLocation: true,
          displacementMeters: 45,
          speedMetersPerSecond: 6,
        ),
        TripStartEvidenceObservation(
          observedAtUtc: started.add(const Duration(seconds: 20)),
          credibleLocation: true,
          displacementMeters: 50,
          speedMetersPerSecond: 7,
          motionHint: independentHint
              ? TripStartMotionHint.inVehicle
              : TripStartMotionHint.unknown,
        ),
      ];

  test('automatic assistance remains off by default', () {
    final decision = TripStartDetectionAssistant.evaluate(
      settings: const TripTrackingSettings(),
      observations: evidence(independentHint: true),
      hasActiveOrRecoverableSession: false,
    );
    expect(decision.disposition, TripStartDetectionDisposition.disabled);
  });

  test('one speed point cannot suggest or start a trip', () {
    final settings = const TripTrackingSettings().copyWith(
      gpsAssistedTrackingEnabled: true,
      assistedStartSuggestionsEnabled: true,
      automaticAssistedStartEnabled: true,
    );
    final decision = TripStartDetectionAssistant.evaluate(
      settings: settings,
      observations: [evidence(independentHint: true).first],
      hasActiveOrRecoverableSession: false,
    );
    expect(
      decision.disposition,
      TripStartDetectionDisposition.insufficientEvidence,
    );
  });

  test('strong GPS movement suggests without automatic-start consent', () {
    final settings = const TripTrackingSettings().copyWith(
      gpsAssistedTrackingEnabled: true,
      assistedStartSuggestionsEnabled: true,
    );
    final decision = TripStartDetectionAssistant.evaluate(
      settings: settings,
      observations: evidence(),
      hasActiveOrRecoverableSession: false,
    );
    expect(decision.disposition, TripStartDetectionDisposition.suggestStart);
    expect(decision.toSafeSummary()['canInventOdometer'], isFalse);
  });

  test(
    'explicit auto consent plus independent motion creates candidate',
    () async {
      final store = TripTrackingSessionStore.memory();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        activeProfileId: () => 'profile_1',
      );
      final settings = const TripTrackingSettings().copyWith(
        gpsAssistedTrackingEnabled: true,
        assistedStartSuggestionsEnabled: true,
        automaticAssistedStartEnabled: true,
      );

      expect(
        await controller.beginAssistedSessionIfEligible(
          tripId: 'trip_assisted_candidate',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          settings: settings,
          observations: evidence(independentHint: true),
          startedAt: started,
        ),
        isTrue,
      );
      expect(
        store.activeSession?.lifecycleState,
        TripTrackingSessionLifecycleState.candidateMovement,
      );
      expect(odometer.confirmedReading, 1000);
      expect(
        store.transitionEventsFor('trip_assisted_candidate'),
        hasLength(1),
      );
      expect(
        store
            .transitionEventsFor('trip_assisted_candidate')
            .single
            .initiatingSource,
        'assisted_start_detector',
      );
    },
  );
}
