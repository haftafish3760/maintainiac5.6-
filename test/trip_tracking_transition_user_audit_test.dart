import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final driveStart = DateTime.utc(2026, 7, 12, 12);

  TripLocationSample sample(double longitude, int seconds) =>
      TripLocationSample(
        latitude: 35,
        longitude: longitude,
        recordedAt: driveStart.add(Duration(seconds: seconds)),
        horizontalAccuracyMeters: 5,
        speedMetersPerSecond: 10,
        speedAccuracyMetersPerSecond: 1,
      );

  test(
    'finishForReview transition records explicit user source and reason',
    () async {
      var now = driveStart;
      final platform = _AuditClockPlatformFake();
      final store = _TransitionTrackingSessionStore();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: platform,
        clockNow: () => now,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_review_user_audit',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: now,
      );

      final nativeStarted = await controller.startNativeTracking(
        allowBackground: false,
      );
      expect(
        nativeStarted,
        isTrue,
        reason:
            'startNativeTracking must successfully enter tracking to audit user actions.',
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

      now = now.add(const Duration(seconds: 1));
      final decision = await controller.ingest(sample(-79.999, 1));
      expect(decision?.disposition, isNotNull);

      now = now.add(const Duration(seconds: 1));
      final review = await controller.finishForReview(finishedAt: now);
      expect(review, isNotNull);
      expect(review!.transitionAudits, isNotEmpty);
      expect(
        review.transitionAudits.last.toState,
        TripTrackingSessionLifecycleState.stopping,
      );

      final audits = store.lastSavedSession?.transitionAudits ?? const [];
      expect(audits, isNotEmpty);
      expect(audits.length, greaterThanOrEqualTo(3));
      expect(audits.last.toState, TripTrackingSessionLifecycleState.stopping);
      expect(audits.last.reasonCode, 'trip_review_requested');
      expect(audits.last.initiatingSource, 'user_finish_for_review');
      expect(controller.activeSession, isNull);
    },
  );

  test(
    'cancelActiveTrip transition records explicit user source and reason',
    () async {
      var now = driveStart.add(const Duration(minutes: 1));
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 2000,
      );
      final store = _TransitionTrackingSessionStore();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        platform: _AuditClockPlatformFake(),
        clockNow: () => now,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_cancel_user_audit',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: now,
      );

      final nativeStarted = await controller.startNativeTracking(
        allowBackground: false,
      );
      expect(
        nativeStarted,
        isTrue,
        reason:
            'startNativeTracking must successfully enter tracking to audit cancellation evidence.',
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

      now = now.add(const Duration(seconds: 20));
      await controller.ingest(sample(-79.999, 20), referenceTime: now);
      now = now.add(const Duration(seconds: 20));
      await controller.ingest(sample(-79.998, 40), referenceTime: now);

      final review = await controller.cancelActiveTrip(
        userConfirmed: true,
        canceledAt: now,
      );
      expect(review, isNotNull);
      expect(review!.transitionAudits, isNotEmpty);
      expect(review.transitionAudits.last.reasonCode, 'trip_cancelled');

      final audits = store.lastSavedSession?.transitionAudits ?? const [];
      expect(audits, isNotEmpty);
      expect(audits.last.toState, TripTrackingSessionLifecycleState.cancelled);
      expect(audits.last.reasonCode, 'trip_cancelled');
      expect(audits.last.initiatingSource, 'user_cancel');
      expect(controller.activeSession, isNull);
      expect(odometer.confirmedReading, 2000);
    },
  );
}

class _AuditClockPlatformFake implements TripTrackingNativeGateway {
  _AuditClockPlatformFake()
    : _events = StreamController<TripTrackingPlatformEvent>.broadcast();

  final StreamController<TripTrackingPlatformEvent> _events;

  int startCalls = 0;
  int stopCalls = 0;

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
      batteryPercent: 90,
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
    startCalls += 1;
    return true;
  }

  @override
  Future<bool> update(TripTrackingNativeRequest request) async => true;

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<bool> get isTracking async => startCalls > stopCalls;
}

class _TransitionTrackingSessionStore extends TripTrackingSessionStore {
  _TransitionTrackingSessionStore() : super.memory();

  TripTrackingSessionRecord? lastSavedSession;

  @override
  Future<void> save(TripTrackingSessionRecord session) async {
    lastSavedSession = session;
    await super.save(session);
  }
}
