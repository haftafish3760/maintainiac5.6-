import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_start_detector.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_evidence_candidate_store.dart';
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
      clockNow: () => at.add(const Duration(seconds: 30)),
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
    );
    addTearDown(controller.dispose);

    final disabled = controller.evaluateAutomaticStartAssistance(
      settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
      accessLevel: TripAutomaticStartAccessLevel.paid,
      observations: evidence(),
    );
    final enabled = controller.evaluateAutomaticStartAssistance(
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        automaticStartAssistanceEnabled: true,
      ),
      accessLevel: TripAutomaticStartAccessLevel.paid,
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
      clockNow: () => at.add(const Duration(seconds: 30)),
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
      accessLevel: TripAutomaticStartAccessLevel.paid,
      observations: evidence(),
    );
    expect(
      decision.disposition,
      TripAutomaticStartDisposition.activeSessionExists,
    );
  });

  test('unknown local recovery state suppresses automatic start safely', () {
    final store = _RecoveringActiveSessionStore();
    final controller = TripTrackingController(
      sessionStore: store,
      clockNow: () => at.add(const Duration(seconds: 30)),
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
    );
    addTearDown(controller.dispose);
    const settings = TripTrackingSettings(
      gpsAssistedTrackingEnabled: true,
      automaticStartAssistanceEnabled: true,
    );

    final failed = controller.evaluateAutomaticStartAssistance(
      settings: settings,
      accessLevel: TripAutomaticStartAccessLevel.paid,
      observations: evidence(),
    );
    expect(
      failed.disposition,
      TripAutomaticStartDisposition.activeSessionExists,
    );
    expect(controller.platformStatus, 'automatic_start_storage_state_unknown');

    store.fail = false;
    final recovered = controller.evaluateAutomaticStartAssistance(
      settings: settings,
      accessLevel: TripAutomaticStartAccessLevel.paid,
      observations: evidence(),
    );
    expect(recovered.disposition, TripAutomaticStartDisposition.candidate);
    expect(controller.platformStatus, isNull);
    expect(controller.platformError, isNull);
  });

  test('controller offers an approval-only free recovery within allowance', () {
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      clockNow: () => at.add(const Duration(seconds: 30)),
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
      accessLevel: TripAutomaticStartAccessLevel.free,
      observations: evidence(),
    );

    expect(decision.disposition, TripAutomaticStartDisposition.candidate);
    expect(decision.shouldSuggestStart, isFalse);
    expect(decision.canStartTrackingAutomatically, isFalse);
    expect(decision.canFinalizeTripLog, isFalse);
    expect(decision.allowanceDecision?.consumesOnDetection, isFalse);
  });

  test(
    'controller persists a proposal-only candidate without starting a trip',
    () async {
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        automaticEvidenceCandidateStore:
            TripAutomaticEvidenceCandidateStore.memory(),
        clockNow: () => at.add(const Duration(seconds: 31)),
        odometer: odometer,
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);

      final decision = await controller.captureAutomaticStartAssistance(
        settings: const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          automaticStartAssistanceEnabled: true,
        ),
        accessLevel: TripAutomaticStartAccessLevel.paid,
        observations: evidence(),
      );

      expect(decision.shouldCreateReviewCandidate, isTrue);
      expect(controller.isTracking, isFalse);
      expect(controller.pendingAutomaticEvidenceCandidates, hasLength(1));
      expect(
        controller.pendingAutomaticEvidenceCandidates.single.canConfirmMileage,
        isFalse,
      );
      expect(odometer.confirmedReading, 1000);
    },
  );

  test('candidate-store failure leaves manual tracking available', () async {
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      automaticEvidenceCandidateStore:
          TripAutomaticEvidenceCandidateStore.unavailable(),
      clockNow: () => at.add(const Duration(seconds: 31)),
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
    );
    addTearDown(controller.dispose);

    final decision = await controller.captureAutomaticStartAssistance(
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        automaticStartAssistanceEnabled: true,
      ),
      accessLevel: TripAutomaticStartAccessLevel.paid,
      observations: evidence(),
    );

    expect(decision.shouldCreateReviewCandidate, isTrue);
    expect(controller.isTracking, isFalse);
    expect(controller.pendingAutomaticEvidenceCandidates, isEmpty);
    expect(
      controller.platformStatus,
      'automatic_evidence_candidate_storage_unavailable',
    );
  });

  test(
    'user decision resolves evidence without creating a trip or mileage record',
    () async {
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        automaticEvidenceCandidateStore:
            TripAutomaticEvidenceCandidateStore.memory(),
        clockNow: () => at.add(const Duration(minutes: 1)),
        odometer: odometer,
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      await controller.captureAutomaticStartAssistance(
        settings: const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          automaticStartAssistanceEnabled: true,
        ),
        accessLevel: TripAutomaticStartAccessLevel.paid,
        observations: evidence(),
      );
      final candidate = controller.pendingAutomaticEvidenceCandidates.single;

      final decided = await controller.decideAutomaticEvidenceCandidate(
        candidateId: candidate.id,
        expectedRevision: candidate.revision,
        approved: false,
      );

      expect(decided.requiresUserReview, isFalse);
      expect(controller.pendingAutomaticEvidenceCandidates, isEmpty);
      expect(controller.isTracking, isFalse);
      expect(odometer.confirmedReading, 1000);
    },
  );

  test(
    'opt-in live evidence creates one review item without starting a trip',
    () async {
      final store = TripAutomaticEvidenceCandidateStore.memory();
      final odometer = GlobalOdometerController(initialReading: 1000);
      final at = DateTime.utc(2026, 8, 4, 12);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        automaticEvidenceCandidateStore: store,
        clockNow: () => at.add(const Duration(seconds: 30)),
      );
      addTearDown(odometer.dispose);
      addTearDown(controller.dispose);
      final settings = const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        automaticStartAssistanceEnabled: true,
      );
      await controller.captureAutomaticLocationEvidence(
        settings: settings,
        accessLevel: TripAutomaticStartAccessLevel.paid,
        location: TripLocationSample(
          latitude: 35,
          longitude: -82,
          recordedAt: at,
          horizontalAccuracyMeters: 12,
          speedMetersPerSecond: 8,
        ),
      );
      final decision = await controller.captureAutomaticLocationEvidence(
        settings: settings,
        accessLevel: TripAutomaticStartAccessLevel.paid,
        bluetoothVehicleId: 'truck-1',
        location: TripLocationSample(
          latitude: 35.0004,
          longitude: -82.0004,
          recordedAt: at.add(const Duration(seconds: 15)),
          horizontalAccuracyMeters: 12,
          speedMetersPerSecond: 8,
        ),
      );

      expect(decision?.shouldCreateReviewCandidate, isTrue);
      expect(controller.pendingAutomaticEvidenceCandidates, hasLength(1));
      expect(controller.isTracking, isFalse);
      expect(odometer.confirmedReading, 1000);

      controller.captureAutomaticActivityEvidence(
        settings: settings,
        activity: TripActivityObservation(
          activity: TripActivity.walking,
          confidence: 95,
          recordedAt: at.add(const Duration(seconds: 25)),
        ),
      );
      await controller.captureAutomaticLocationEvidence(
        settings: settings,
        accessLevel: TripAutomaticStartAccessLevel.paid,
        location: TripLocationSample(
          latitude: 35.0008,
          longitude: -82.0008,
          recordedAt: at.add(const Duration(seconds: 30)),
          horizontalAccuracyMeters: 12,
          speedMetersPerSecond: 8,
        ),
      );
      expect(controller.pendingAutomaticEvidenceCandidates, hasLength(1));
      expect(controller.pendingStopReviewCount, 0);
      expect(controller.advisories, isEmpty);
      expect(controller.boundaryCandidates, isEmpty);
    },
  );

  test('disabled assistance clears live evidence without a proposal', () async {
    final store = TripAutomaticEvidenceCandidateStore.memory();
    final odometer = GlobalOdometerController();
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      automaticEvidenceCandidateStore: store,
    );
    addTearDown(odometer.dispose);
    addTearDown(controller.dispose);

    final result = await controller.captureAutomaticLocationEvidence(
      settings: const TripTrackingSettings(),
      accessLevel: TripAutomaticStartAccessLevel.paid,
      location: TripLocationSample(
        latitude: 35,
        longitude: -82,
        recordedAt: DateTime.utc(2026, 8, 4, 12),
        horizontalAccuracyMeters: 12,
        speedMetersPerSecond: 8,
      ),
    );

    expect(result, isNull);
    expect(controller.pendingAutomaticEvidenceCandidates, isEmpty);
    expect(controller.isTracking, isFalse);
  });
}

class _RecoveringActiveSessionStore extends TripTrackingSessionStore {
  _RecoveringActiveSessionStore() : super.memory();

  var fail = true;

  @override
  TripTrackingSessionRecord? get activeSession {
    if (fail) throw StateError('active session storage unavailable');
    return super.activeSession;
  }
}
