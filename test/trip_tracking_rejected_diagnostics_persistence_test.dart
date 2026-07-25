import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_signal_quality_action_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_signal_quality.dart';

void main() {
  test(
    'unsafe rejected-sample diagnostics survive controller recovery',
    () async {
      final at = DateTime.utc(2026, 7, 24, 12);
      final store = TripTrackingSessionStore.memory();
      final firstOdometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final first = TripTrackingController(
        sessionStore: store,
        odometer: firstOdometer,
        clockNow: () => at.add(const Duration(minutes: 1)),
      );
      addTearDown(firstOdometer.dispose);
      await first.start(
        tripId: 'rejected_diagnostics_recovery',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: at,
      );
      final initialRevision = first.activeSession!.revision;

      for (var index = 0; index < 2; index += 1) {
        final decision = await first.ingest(
          TripLocationSample(
            latitude: 95,
            longitude: -80,
            recordedAt: at.add(Duration(seconds: index + 1)),
            horizontalAccuracyMeters: 5,
          ),
        );
        expect(decision?.disposition, TripSampleDisposition.rejectedInvalid);
      }

      expect(first.activeSession!.revision, initialRevision + 2);
      expect(
        first.signalQualitySummary.quality,
        TripTrackingSignalQuality.unsafe,
      );
      expect(
        first.signalQualityAction().action,
        TripSignalQualityAction.pauseGpsUntilReview,
      );
      expect(first.signalQualityAction().shouldShowBanner, isTrue);
      expect(first.acceptedMeters, 0);
      expect(
        store
            .activeSession!
            .engineSnapshot
            .diagnostics
            .dispositionCounts[TripSampleDisposition.rejectedInvalid],
        2,
      );

      first.dispose();
      final restoredOdometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final restored = TripTrackingController(
        sessionStore: store,
        odometer: restoredOdometer,
        clockNow: () => at.add(const Duration(minutes: 2)),
      );
      addTearDown(restored.dispose);
      addTearDown(restoredOdometer.dispose);
      expect(await restored.restore(), isTrue);
      expect(
        restored.signalQualitySummary.quality,
        TripTrackingSignalQuality.unsafe,
      );
      expect(restored.acceptedMeters, 0);
    },
  );

  test(
    'unsafe provider evidence pauses only GPS and preserves the trip',
    () async {
      final at = DateTime.utc(2026, 7, 24, 13);
      final gateway = _SignalSafetyGateway();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 2000,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        platform: gateway,
        clockNow: () => at.add(const Duration(minutes: 1)),
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      addTearDown(gateway.close);
      await controller.start(
        tripId: 'unsafe_signal_pause',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: at,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      for (var index = 0; index < 2; index += 1) {
        await controller.ingest(
          TripLocationSample(
            latitude: 95,
            longitude: -80,
            recordedAt: at.add(Duration(seconds: index + 1)),
            horizontalAccuracyMeters: 5,
          ),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(gateway.stopCalls, 1);
      expect(controller.nativeTracking, isFalse);
      expect(controller.isTracking, isTrue);
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.paused,
      );
      expect(controller.activeSession?.pauseKind, TripTrackingPauseKind.system);
      expect(controller.platformStatus, 'gps_signal_review_required');
      expect(controller.acceptedMeters, 0);
      expect(odometer.confirmedReading, 2000);

      expect(
        controller.cumulativeSignalQualitySummary.quality,
        TripTrackingSignalQuality.unsafe,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );
      expect(
        controller.signalQualitySummary.quality,
        TripTrackingSignalQuality.noSamples,
      );

      await controller.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          recordedAt: at.add(const Duration(seconds: 3)),
          horizontalAccuracyMeters: 5,
        ),
      );
      await controller.ingest(
        TripLocationSample(
          latitude: 95,
          longitude: -80,
          recordedAt: at.add(const Duration(seconds: 4)),
          horizontalAccuracyMeters: 5,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(controller.nativeTracking, isTrue);
      expect(
        controller.signalQualitySummary.quality,
        TripTrackingSignalQuality.reduced,
      );

      await controller.ingest(
        TripLocationSample(
          latitude: 95,
          longitude: -80,
          recordedAt: at.add(const Duration(seconds: 5)),
          horizontalAccuracyMeters: 5,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(gateway.stopCalls, 2);
      expect(controller.nativeTracking, isFalse);
      expect(controller.cumulativeSignalQualitySummary.receivedSamples, 5);
      expect(
        controller.diagnostics.dispositionCounts[TripSampleDisposition
            .rejectedInvalid],
        4,
      );
    },
  );

  test(
    'a later durable sample clears rejected-diagnostic storage failure',
    () async {
      final at = DateTime.utc(2026, 7, 24, 14);
      final store = _FailNextSaveStore();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 3000,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        clockNow: () => at.add(const Duration(minutes: 1)),
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      await controller.start(
        tripId: 'rejected_diagnostic_write_retry',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: at,
      );

      store.failNextSave = true;
      expect(
        await controller.ingest(
          TripLocationSample(
            latitude: 95,
            longitude: -80,
            recordedAt: at.add(const Duration(seconds: 1)),
            horizontalAccuracyMeters: 5,
          ),
        ),
        isNull,
      );
      expect(controller.platformStatus, 'storage_failed');
      expect(controller.diagnostics.receivedSamples, 0);

      final accepted = await controller.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          recordedAt: at.add(const Duration(seconds: 2)),
          horizontalAccuracyMeters: 5,
        ),
      );
      expect(accepted?.disposition, TripSampleDisposition.acceptedAnchor);
      expect(controller.platformStatus, isNull);
      expect(controller.platformError, isNull);
    },
  );
}

class _FailNextSaveStore extends TripTrackingSessionStore {
  _FailNextSaveStore() : super.memory();

  var failNextSave = false;

  @override
  Future<void> save(TripTrackingSessionRecord session) {
    if (failNextSave) {
      failNextSave = false;
      throw StateError('simulated diagnostic write failure');
    }
    return super.save(session);
  }
}

class _SignalSafetyGateway implements TripTrackingNativeGateway {
  final _events = StreamController<TripTrackingPlatformEvent>.broadcast();
  var running = false;
  var stopCalls = 0;

  @override
  Stream<TripTrackingPlatformEvent> get events => _events.stream;

  @override
  Future<bool> get isTracking async => running;

  @override
  Future<TripTrackingPlatformCapabilities> readCapabilities() async =>
      const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: true,
        batteryStateAvailable: true,
      );

  @override
  Future<TripTrackingBatterySnapshot> readBatterySnapshot() async =>
      const TripTrackingBatterySnapshot(
        batteryPercent: 80,
        isCharging: false,
        lowPowerModeEnabled: false,
      );

  @override
  Future<TripTrackingAuthorization> requestAuthorization({
    required bool allowBackground,
    required bool activityRecognitionEnabled,
  }) async => const TripTrackingAuthorization(
    state: TripTrackingAuthorizationState.whileInUse,
    preciseLocation: true,
  );

  @override
  Future<bool> start(TripTrackingNativeRequest request) async {
    running = true;
    return true;
  }

  @override
  Future<bool> update(TripTrackingNativeRequest request) async => running;

  @override
  Future<void> stop() async {
    stopCalls += 1;
    running = false;
  }

  Future<void> close() => _events.close();
}
