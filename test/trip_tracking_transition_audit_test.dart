import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'controller transition hook rejects illegal lifecycle transitions',
    () async {
      final start = DateTime.utc(2026, 7, 12, 12);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: _AuditClockPlatformFake(),
      );
      addTearDown(controller.dispose);

      expect(
        await controller.start(
          tripId: 'trip_transition_reject_test',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: start,
        ),
        isTrue,
      );
      expect(
        controller.lifecycleState?.name,
        TripTrackingSessionLifecycleState.ready.name,
      );

      final rejected = await controller.tryTransitionForTest(
        TripTrackingSessionLifecycleState.completed,
        reasonCode: 'illegal_test_transition',
        source: 'transition_test',
      );

      expect(rejected, isFalse);
      expect(controller.platformStatus, 'transition_rejected');
      expect(
        controller.platformError,
        contains('Illegal GPS session transition: ready -> completed'),
      );
      expect(controller.transitionAudits, hasLength(1));
      expect(controller.transitionAudits.single.accepted, isFalse);
      expect(
        controller.transitionAudits.single.fromState,
        TripTrackingSessionLifecycleState.ready,
      );
      expect(
        controller.transitionAudits.single.toState,
        TripTrackingSessionLifecycleState.completed,
      );
      expect(
        controller.transitionAudits.single.effectiveFromContractState,
        TripTrackingSessionLifecycleContractState.PREPARING,
      );
      expect(
        controller.transitionAudits.single.effectiveToContractState,
        TripTrackingSessionLifecycleContractState.COMPLETED,
      );
      expect(controller.activeSession?.revision, 2);
      final restored = TripTrackingSessionRecord.fromMap(
        controller.activeSession!.toMap(),
      );
      expect(restored.transitionAudits.single.accepted, isFalse);
      expect(
        restored.transitionAudits.single.effectiveToContractState,
        TripTrackingSessionLifecycleContractState.COMPLETED,
      );

      final legacyMap = Map<String, Object?>.from(
        controller.activeSession!.toMap(),
      );
      final legacyAudit = Map<String, Object?>.from(
        (legacyMap['transitionAudits'] as List).single as Map,
      )..remove('schemaVersion');
      legacyMap['transitionAudits'] = [legacyAudit];
      expect(
        TripTrackingSessionRecord.fromMap(legacyMap).transitionAudits,
        hasLength(1),
      );

      final futureMap = Map<String, Object?>.from(
        controller.activeSession!.toMap(),
      );
      final futureAudit = Map<String, Object?>.from(
        (futureMap['transitionAudits'] as List).single as Map,
      )..['schemaVersion'] = 2;
      futureMap['transitionAudits'] = [futureAudit];
      expect(
        TripTrackingSessionRecord.fromMap(futureMap).transitionAudits,
        isEmpty,
      );

      final afterCheckpointMap = Map<String, Object?>.from(
        controller.activeSession!.toMap(),
      );
      final afterCheckpointAudit =
          Map<String, Object?>.from(
              (afterCheckpointMap['transitionAudits'] as List).single as Map,
            )
            ..['eventTimestamp'] = controller.activeSession!.updatedAt
                .add(const Duration(seconds: 1))
                .toIso8601String();
      afterCheckpointMap['transitionAudits'] = [afterCheckpointAudit];
      expect(
        TripTrackingSessionRecord.fromMap(afterCheckpointMap).transitionAudits,
        isEmpty,
      );

      final review = TripTrackingReviewRecord(
        id: controller.activeSession!.id,
        vehicleId: controller.activeSession!.vehicleId,
        startingOdometer: controller.activeSession!.startingOdometer,
        estimatedEndingOdometer: controller.activeSession!.startingOdometer,
        profile: controller.activeSession!.profile,
        profileId: controller.activeSession!.effectiveProfileId,
        startedAt: controller.activeSession!.startedAt,
        finishedAt: controller.activeSession!.updatedAt,
        engineSnapshot: controller.activeSession!.engineSnapshot,
        transitionAudits: controller.activeSession!.transitionAudits,
      );
      final reviewMap = Map<String, Object?>.from(review.toMap());
      final reviewAfterFinishAudit =
          Map<String, Object?>.from(
              (reviewMap['transitionAudits'] as List).single as Map,
            )
            ..['eventTimestamp'] = review.finishedAt
                .add(const Duration(seconds: 1))
                .toIso8601String();
      reviewMap['transitionAudits'] = [reviewAfterFinishAudit];
      expect(
        TripTrackingReviewRecord.fromMap(reviewMap).transitionAudits,
        isEmpty,
      );
    },
  );

  test(
    'controller transition hook accepts legal lifecycle transitions',
    () async {
      final start = DateTime.utc(2026, 7, 12, 12);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: _AuditClockPlatformFake(),
      );
      addTearDown(controller.dispose);

      expect(
        await controller.start(
          tripId: 'trip_transition_allow_test',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: start,
        ),
        isTrue,
      );

      final accepted = await controller.tryTransitionForTest(
        TripTrackingSessionLifecycleState.starting,
        reasonCode: 'legal_test_transition',
        source: 'transition_test',
      );
      expect(accepted, isTrue);
      expect(controller.platformStatus, isNull);
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.starting,
      );
      expect(controller.transitionAudits, hasLength(1));
      expect(
        controller.transitionAudits.last.toState,
        TripTrackingSessionLifecycleState.starting,
      );
      expect(
        controller.transitionAudits.last.effectiveToContractState,
        TripTrackingSessionLifecycleContractState.AWAITING_INITIAL_FIX,
      );
      expect(
        controller.transitionAudits.last.reasonCode,
        'legal_test_transition',
      );
      expect(
        controller.transitionAudits.last.initiatingSource,
        'transition_test',
      );
    },
  );

  test(
    'transition audits use deterministic sequencing and event ordering with one source clock',
    () async {
      var now = DateTime.utc(2026, 7, 12, 12);
      final platform = _AuditClockPlatformFake();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: platform,
        clockNow: () => now,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_transition_audit_test',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: now,
      );

      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );
      expect(controller.transitionAudits, hasLength(2));
      expect(
        controller.transitionAudits.first.toState,
        TripTrackingSessionLifecycleState.starting,
      );
      expect(
        controller.transitionAudits.last.toState,
        TripTrackingSessionLifecycleState.active,
      );
      expect(
        controller.transitionAudits.map((entry) => entry.sequenceNumber),
        equals([2, 3]),
      );

      now = now.subtract(const Duration(hours: 1));
      await controller.stopNativeTracking();

      final audits = controller.transitionAudits;
      expect(audits, hasLength(3));
      expect(audits.map((entry) => entry.sequenceNumber), equals([2, 3, 4]));
      expect(audits.last.toState, TripTrackingSessionLifecycleState.paused);
      expect(audits[2].reasonCode, 'native_tracking_stopped');
      expect(audits[2].eventTimestamp, audits[1].eventTimestamp);
      expect(
        audits.map((entry) => entry.initiatingSource),
        equals(['native_start', 'native_start', 'native_stop_tracking']),
      );
      expect(
        audits.map((entry) => entry.profileId),
        everyElement(TripTrackingProfile.roadVehicle.name),
      );
      expect(audits[0].initiatingSource, 'native_start');
      expect(audits[1].initiatingSource, 'native_start');
      expect(audits[2].initiatingSource, 'native_stop_tracking');
      for (var index = 0; index < audits.length - 1; index += 1) {
        expect(
          audits[index + 1].eventTimestamp.isAfter(
                audits[index].eventTimestamp,
              ) ||
              audits[index + 1].eventTimestamp.isAtSameMomentAs(
                audits[index].eventTimestamp,
              ),
          isTrue,
          reason: 'audit #$index is not time-ordered',
        );
      }

      expect(
        controller.activeSession?.updatedAt.toUtc(),
        audits.last.eventTimestamp,
      );
    },
  );

  test('clock rollback cannot regress native startup checkpoints', () async {
    final startedAt = DateTime.utc(2026, 7, 12, 12);
    var now = startedAt;
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
      platform: _AuditClockPlatformFake(),
      clockNow: () => now,
    );
    addTearDown(controller.dispose);

    expect(
      await controller.start(
        tripId: 'trip_native_clock_rollback',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
      ),
      isTrue,
    );
    now = startedAt.subtract(const Duration(hours: 2));
    expect(
      await controller.startNativeTracking(allowBackground: false),
      isTrue,
    );

    expect(controller.activeSession?.updatedAt, startedAt);
    expect(
      controller.transitionAudits.map((audit) => audit.eventTimestamp),
      everyElement(startedAt),
    );
    expect(controller.activeSession?.permissionHistory.single.observedAt, now);
  });

  test('clock rollback cannot regress default finish or cancel time', () async {
    final startedAt = DateTime.utc(2026, 7, 12, 12);
    var now = startedAt;
    final finishController = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
      clockNow: () => now,
    );
    addTearDown(finishController.dispose);
    await finishController.start(
      tripId: 'trip_finish_clock_rollback',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: startedAt,
    );
    final latestEvidenceAt = startedAt.add(const Duration(seconds: 30));
    await finishController.ingest(
      TripLocationSample(
        latitude: 35,
        longitude: -80,
        recordedAt: latestEvidenceAt,
        horizontalAccuracyMeters: 5,
      ),
      referenceTime: latestEvidenceAt,
    );
    now = startedAt.subtract(const Duration(hours: 1));
    final finished = await finishController.finishForReview();
    expect(finished?.finishedAt, latestEvidenceAt);

    now = startedAt;
    final cancelController = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
      clockNow: () => now,
    );
    addTearDown(cancelController.dispose);
    await cancelController.start(
      tripId: 'trip_cancel_clock_rollback',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: startedAt,
    );
    now = startedAt.subtract(const Duration(hours: 1));
    final cancelled = await cancelController.cancelActiveTrip();
    expect(cancelled?.finishedAt, startedAt);
  });

  test('explicit end times cannot predate persisted trip evidence', () async {
    final startedAt = DateTime.utc(2026, 7, 12, 12);
    final evidenceAt = startedAt.add(const Duration(seconds: 30));
    final invalidEndAt = startedAt.add(const Duration(seconds: 10));

    Future<TripTrackingController> controllerFor(String tripId) async {
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
      );
      addTearDown(controller.dispose);
      expect(
        await controller.start(
          tripId: tripId,
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: startedAt,
        ),
        isTrue,
      );
      await controller.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          recordedAt: evidenceAt,
          horizontalAccuracyMeters: 5,
        ),
        referenceTime: evidenceAt,
      );
      expect(controller.activeSession?.updatedAt, evidenceAt);
      return controller;
    }

    final finishController = await controllerFor('trip_explicit_finish');
    expect(
      await finishController.finishForReview(finishedAt: invalidEndAt),
      isNull,
    );
    expect(
      finishController.platformStatus,
      'review_finish_before_latest_evidence',
    );
    expect(finishController.activeSession, isNotNull);
    expect(finishController.activeSession?.updatedAt, evidenceAt);

    final cancelController = await controllerFor('trip_explicit_cancel');
    expect(
      await cancelController.cancelActiveTrip(
        canceledAt: invalidEndAt,
        userConfirmed: true,
      ),
      isNull,
    );
    expect(
      cancelController.platformStatus,
      'trip_cancel_before_latest_evidence',
    );
    expect(cancelController.activeSession, isNotNull);
    expect(cancelController.activeSession?.updatedAt, evidenceAt);
  });

  test(
    'legacy transition map without profileId falls back to profile name',
    () {
      final audit = TripTrackingSessionTransitionAudit.fromMap({
        'id': 'legacy-audit-id',
        'sessionId': 'trip_legacy',
        'vehicleId': 'vehicle_legacy',
        'profile': TripTrackingProfile.roadVehicle.name,
        'fromState': TripTrackingSessionLifecycleState.ready.name,
        'toState': TripTrackingSessionLifecycleState.active.name,
        'eventTimestamp': DateTime.utc(2026, 7, 21, 12).toIso8601String(),
        'sequenceNumber': 7,
        'reasonCode': 'legacy_restart',
        'initiatingSource': 'recovery',
        'revision': 2,
        'permissionState': 'authorized_always',
        'confidenceState': 'low',
        'trackingQualityMode': 'assisted',
      });

      expect(audit.profile, TripTrackingProfile.roadVehicle);
      expect(audit.profileId, TripTrackingProfile.roadVehicle.name);
    },
  );

  test(
    'legacy transition map with bad profile but valid profileId resolves profile from profileId',
    () {
      final audit = TripTrackingSessionTransitionAudit.fromMap({
        'id': 'legacy-audit-id',
        'sessionId': 'trip_legacy',
        'vehicleId': 'vehicle_legacy',
        'profile': 'definitely-not-real',
        'profileId': TripTrackingProfile.deliveryVehicle.name,
        'fromState': TripTrackingSessionLifecycleState.ready.name,
        'toState': TripTrackingSessionLifecycleState.active.name,
        'eventTimestamp': DateTime.utc(2026, 7, 21, 12).toIso8601String(),
        'sequenceNumber': 7,
        'reasonCode': 'legacy_restart',
        'initiatingSource': 'recovery',
        'revision': 2,
        'permissionState': 'authorized_always',
        'confidenceState': 'low',
        'trackingQualityMode': 'assisted',
      });

      expect(audit.profile, TripTrackingProfile.deliveryVehicle);
      expect(audit.profileId, TripTrackingProfile.deliveryVehicle.name);
    },
  );

  test('malformed transition map hardens to safe defaults', () {
    final audit = TripTrackingSessionTransitionAudit.fromMap({
      'id': null,
      'sessionId': null,
      'vehicleId': null,
      'profile': null,
      'profileId': null,
      'fromState': 'bad_state',
      'toState': 99,
      'eventTimestamp': 'not-a-timestamp',
      'sequenceNumber': -9,
      'reasonCode': null,
      'initiatingSource': null,
      'revision': 'NaN',
      'permissionState': 1234,
      'confidenceState': null,
      'trackingQualityMode': null,
    });

    expect(audit.id, isEmpty);
    expect(audit.sessionId, isEmpty);
    expect(audit.vehicleId, isEmpty);
    expect(audit.profile, TripTrackingProfile.roadVehicle);
    expect(audit.profileId, TripTrackingProfile.roadVehicle.name);
    expect(audit.fromState, TripTrackingSessionLifecycleState.ready);
    expect(audit.toState, TripTrackingSessionLifecycleState.ready);
    expect(
      audit.eventTimestamp,
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
    expect(audit.sequenceNumber, 1);
    expect(audit.reasonCode, 'gps_session_transition_allowed');
    expect(audit.initiatingSource, 'controller');
    expect(audit.revision, 1);
    expect(audit.permissionState, '');
    expect(audit.confidenceState, '');
    expect(audit.trackingQualityMode, '');
  });

  test(
    'malformed transition fields are sanitized and unsafe values drop to safe defaults',
    () {
      final audit = TripTrackingSessionTransitionAudit.fromMap({
        'id': 'audit-id',
        'sessionId': 'session-id',
        'vehicleId': 'vehicle-id',
        'profile': TripTrackingProfile.deliveryVehicle.name,
        'profileId': TripTrackingProfile.deliveryVehicle.name,
        'fromState': TripTrackingSessionLifecycleState.active.name,
        'toState': TripTrackingSessionLifecycleState.awaitingReview.name,
        'eventTimestamp': DateTime.now().toIso8601String(),
        'sequenceNumber': 42,
        'reasonCode': 'INVALID REASON CODE with spaces',
        'initiatingSource': 'UI-Button',
        'revision': 99,
        'permissionState': 'AUTH_GRANTED',
        'confidenceState': 'LOW QUALITY',
        'trackingQualityMode': 'fast-mode',
      });

      expect(audit.id, 'audit-id');
      expect(audit.sessionId, 'session-id');
      expect(audit.vehicleId, 'vehicle-id');
      expect(audit.profile, TripTrackingProfile.deliveryVehicle);
      expect(audit.reasonCode, 'gps_session_transition_allowed');
      expect(audit.initiatingSource, 'controller');
      expect(audit.permissionState, '');
      expect(audit.confidenceState, '');
      expect(audit.trackingQualityMode, '');
    },
  );
}

class _AuditClockPlatformFake implements TripTrackingNativeGateway {
  _AuditClockPlatformFake()
    : _events = StreamController<TripTrackingPlatformEvent>.broadcast();

  final StreamController<TripTrackingPlatformEvent> _events;
  bool _running = false;

  @override
  Stream<TripTrackingPlatformEvent> get events => _events.stream;

  @override
  Future<TripTrackingPlatformCapabilities> readCapabilities() async {
    return const TripTrackingPlatformCapabilities(
      locationAvailable: true,
      backgroundTrackingAvailable: true,
      activityRecognitionAvailable: false,
      batteryStateAvailable: true,
      lowPowerModeAvailable: true,
    );
  }

  @override
  Future<TripTrackingBatterySnapshot> readBatterySnapshot() async {
    return const TripTrackingBatterySnapshot(
      batteryPercent: 98,
      isCharging: false,
      lowPowerModeEnabled: false,
    );
  }

  @override
  Future<TripTrackingAuthorization> requestAuthorization({
    required bool allowBackground,
    required bool activityRecognitionEnabled,
  }) async {
    return const TripTrackingAuthorization(
      state: TripTrackingAuthorizationState.always,
      preciseLocation: true,
    );
  }

  @override
  Future<bool> start(TripTrackingNativeRequest request) async {
    _running = true;
    return true;
  }

  @override
  Future<bool> update(TripTrackingNativeRequest request) async => true;

  @override
  Future<void> stop() async {
    _running = false;
  }

  @override
  Future<bool> get isTracking async => _running;

  void closeEvents() => _events.close();
}
