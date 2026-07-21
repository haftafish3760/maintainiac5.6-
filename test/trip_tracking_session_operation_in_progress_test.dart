import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart'
    as global_odometer;
import 'package:maintaniac/shared/storage/app_storage_guard.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

class TestGlobalOdometerController
    extends global_odometer.GlobalOdometerController {
  TestGlobalOdometerController()
    : super(vehicleId: 'vehicle_1', initialReading: 1000);
}

class _BlockingPendingSampleStore extends TripTrackingSessionStore {
  _BlockingPendingSampleStore() : super.memory();

  final pendingSaveStarted = Completer<void>();
  final allowPendingSave = Completer<void>();

  @override
  Future<void> savePending(TripTrackingPendingSample pending) async {
    if (!pendingSaveStarted.isCompleted) pendingSaveStarted.complete();
    await allowPendingSave.future;
    await super.savePending(pending);
  }
}

class _DelayedReviewMutationStore extends TripTrackingSessionStore {
  _DelayedReviewMutationStore() : super.memory();

  final saveStarted = Completer<void>();
  final allowSave = Completer<void>();
  var delayNextSave = false;

  @override
  Future<void> saveReview(TripTrackingReviewRecord review) async {
    if (delayNextSave) {
      delayNextSave = false;
      saveStarted.complete();
      await allowSave.future;
    }
    await super.saveReview(review);
  }
}

class _BlockingRestorePlatform implements TripTrackingNativeGateway {
  _BlockingRestorePlatform(this._isTrackingGate);

  final Completer<bool> _isTrackingGate;

  @override
  Stream<TripTrackingPlatformEvent> get events =>
      const Stream<TripTrackingPlatformEvent>.empty();

  @override
  Future<TripTrackingPlatformCapabilities> readCapabilities() => Future.value(
    const TripTrackingPlatformCapabilities(
      locationAvailable: true,
      backgroundTrackingAvailable: true,
      activityRecognitionAvailable: true,
    ),
  );

  @override
  Future<TripTrackingBatterySnapshot> readBatterySnapshot() => Future.value(
    const TripTrackingBatterySnapshot(
      batteryPercent: 100,
      isCharging: false,
      lowPowerModeEnabled: false,
    ),
  );

  @override
  Future<TripTrackingAuthorization> requestAuthorization({
    required bool allowBackground,
    required bool activityRecognitionEnabled,
  }) => Future.value(
    TripTrackingAuthorization(
      state: allowBackground
          ? TripTrackingAuthorizationState.always
          : TripTrackingAuthorizationState.whileInUse,
      preciseLocation: true,
    ),
  );

  @override
  Future<bool> start(TripTrackingNativeRequest request) async => true;

  @override
  Future<bool> update(TripTrackingNativeRequest request) async => true;

  @override
  Future<void> stop() async {}

  @override
  Future<bool> get isTracking => _isTrackingGate.future;
}

void main() {
  test(
    'duplicate start commands during in-flight start return explicit in-progress status',
    () async {
      final storageGate = Completer<void>();
      final blockedStore = TripTrackingSessionStore.memory(
        storageCheck: () async {
          await storageGate.future;
          return const AppStorageCheck(
            availableBytes: 1024 * 1024,
            operationBytes: 1024,
            requiredBytes: 1024,
            purpose: AppStoragePurpose.mileageTracking,
          );
        },
      );
      final controller = TripTrackingController(
        sessionStore: blockedStore,
        odometer: TestGlobalOdometerController(),
      );

      final first = controller.start(
        tripId: 'trip_overlap_start_gate',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 12, 12),
      );

      await Future<void>.delayed(Duration.zero);
      final secondResult = await controller.start(
        tripId: 'trip_overlap_start_gate_second',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 12, 12),
      );

      expect(secondResult, isFalse);
      expect(controller.platformStatus, 'session_operation_in_progress');
      expect(
        controller.platformError,
        'A trip is already starting or ending. Please wait for it to finish.',
      );

      storageGate.complete();
      expect(await first, isTrue);
      expect(
        controller.platformStatus,
        anyOf(isNull, isNot('session_operation_in_progress')),
      );
    },
  );

  test(
    'duplicate restore commands during in-flight start return explicit in-progress status',
    () async {
      final storageGate = Completer<void>();
      final blockedStore = TripTrackingSessionStore.memory(
        storageCheck: () async {
          await storageGate.future;
          return const AppStorageCheck(
            availableBytes: 1024 * 1024,
            operationBytes: 1024,
            requiredBytes: 1024,
            purpose: AppStoragePurpose.mileageTracking,
          );
        },
      );
      final controller = TripTrackingController(
        sessionStore: blockedStore,
        odometer: TestGlobalOdometerController(),
      );

      final first = controller.start(
        tripId: 'trip_overlap_restore_gate',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 12, 12),
      );

      await Future<void>.delayed(Duration.zero);
      final restoreResult = await controller.restore();

      expect(restoreResult, isFalse);
      expect(controller.platformStatus, 'session_operation_in_progress');
      expect(
        controller.platformError,
        'A trip is already starting or ending. Please wait for it to finish.',
      );

      storageGate.complete();
      expect(await first, isTrue);
    },
  );

  test(
    'duplicate restore commands during in-flight restore return explicit in-progress status',
    () async {
      final blockedRestore = Completer<bool>();
      final restoreGate = Completer<void>();
      var storageChecks = 0;
      final blockedStore = TripTrackingSessionStore.memory(
        storageCheck: () async {
          storageChecks += 1;
          if (storageChecks > 1) await restoreGate.future;
          return const AppStorageCheck(
            availableBytes: 1024 * 1024,
            operationBytes: 1024,
            requiredBytes: 1024,
            purpose: AppStoragePurpose.mileageTracking,
          );
        },
      );

      await blockedStore.save(
        TripTrackingSessionRecord(
          id: 'trip_inflight_restore',
          vehicleId: 'vehicle_1',
          startingOdometer: 1000,
          profile: TripTrackingProfile.roadVehicle,
          startedAt: DateTime.utc(2026, 7, 12, 12),
          updatedAt: DateTime.utc(2026, 7, 12, 12),
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 0,
            walkingReviewSuggested: false,
          ),
          lifecycleState: TripTrackingSessionLifecycleState.ready,
          transitionAudits: const [],
        ),
      );

      final controller = TripTrackingController(
        sessionStore: blockedStore,
        odometer: TestGlobalOdometerController(),
        platform: _BlockingRestorePlatform(blockedRestore),
      );

      final firstRestore = controller.restore();

      await Future<void>.delayed(Duration.zero);
      final secondRestore = await controller.restore();

      expect(secondRestore, isFalse);
      expect(controller.platformStatus, 'session_operation_in_progress');
      expect(
        controller.platformError,
        'A trip is already starting or ending. Please wait for it to finish.',
      );

      blockedRestore.complete(true);
      restoreGate.complete();
      expect(await firstRestore, isTrue);
    },
  );

  test(
    'duplicate discard commands during in-flight start return explicit in-progress status',
    () async {
      final storageGate = Completer<void>();
      final blockedStore = TripTrackingSessionStore.memory(
        storageCheck: () async {
          await storageGate.future;
          return const AppStorageCheck(
            availableBytes: 1024 * 1024,
            operationBytes: 1024,
            requiredBytes: 1024,
            purpose: AppStoragePurpose.mileageTracking,
          );
        },
      );
      final controller = TripTrackingController(
        sessionStore: blockedStore,
        odometer: TestGlobalOdometerController(),
      );

      final first = controller.start(
        tripId: 'trip_overlap_discard_gate',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 12, 12),
      );

      await Future<void>.delayed(Duration.zero);
      final discardResult = await controller.discardEmptyTrip();

      expect(discardResult, isFalse);
      expect(controller.platformStatus, 'session_operation_in_progress');
      expect(
        controller.platformError,
        'A trip is already starting or ending. Please wait for it to finish.',
      );

      storageGate.complete();
      expect(await first, isTrue);
    },
  );

  test(
    'duplicate finish-for-review commands during in-flight start return explicit in-progress status',
    () async {
      final storageGate = Completer<void>();
      final blockedStore = TripTrackingSessionStore.memory(
        storageCheck: () async {
          await storageGate.future;
          return const AppStorageCheck(
            availableBytes: 1024 * 1024,
            operationBytes: 1024,
            requiredBytes: 1024,
            purpose: AppStoragePurpose.mileageTracking,
          );
        },
      );
      final controller = TripTrackingController(
        sessionStore: blockedStore,
        odometer: TestGlobalOdometerController(),
      );

      final first = controller.start(
        tripId: 'trip_overlap_review_gate',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 12, 12),
      );

      await Future<void>.delayed(Duration.zero);
      final reviewResult = await controller.finishForReview();

      expect(reviewResult, isNull);
      expect(controller.platformStatus, 'session_operation_in_progress');
      expect(
        controller.platformError,
        'A trip is already starting or ending. Please wait for it to finish.',
      );

      storageGate.complete();
      expect(await first, isTrue);
    },
  );

  test(
    'duplicate cancellation commands during in-flight start return explicit in-progress status',
    () async {
      final storageGate = Completer<void>();
      final blockedStore = TripTrackingSessionStore.memory(
        storageCheck: () async {
          await storageGate.future;
          return const AppStorageCheck(
            availableBytes: 1024 * 1024,
            operationBytes: 1024,
            requiredBytes: 1024,
            purpose: AppStoragePurpose.mileageTracking,
          );
        },
      );
      final controller = TripTrackingController(
        sessionStore: blockedStore,
        odometer: TestGlobalOdometerController(),
      );

      final first = controller.start(
        tripId: 'trip_overlap_cancel_gate',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 12, 12),
      );

      await Future<void>.delayed(Duration.zero);
      final cancelResult = await controller.cancelActiveTrip();

      expect(cancelResult, isNull);
      expect(controller.platformStatus, 'session_operation_in_progress');
      expect(
        controller.platformError,
        'A trip is already starting or ending. Please wait for it to finish.',
      );

      storageGate.complete();
      expect(await first, isTrue);
    },
  );

  test(
    'duplicate odometer confirmation commands during in-flight start return explicit in-progress status',
    () async {
      final storageGate = Completer<void>();
      final blockedStore = TripTrackingSessionStore.memory(
        storageCheck: () async {
          await storageGate.future;
          return const AppStorageCheck(
            availableBytes: 1024 * 1024,
            operationBytes: 1024,
            requiredBytes: 1024,
            purpose: AppStoragePurpose.mileageTracking,
          );
        },
      );
      final controller = TripTrackingController(
        sessionStore: blockedStore,
        odometer: TestGlobalOdometerController(),
      );

      final first = controller.start(
        tripId: 'trip_overlap_confirm_gate',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 12, 12),
      );

      await Future<void>.delayed(Duration.zero);
      final confirmResult = await controller.confirmOdometerReview(
        reviewId: 'review_missing',
        confirmedEndingOdometer: 1200,
      );

      expect(confirmResult, isFalse);
      expect(controller.platformStatus, 'session_operation_in_progress');
      expect(
        controller.platformError,
        'A trip is already starting or ending. Please wait for it to finish.',
      );

      storageGate.complete();
      expect(await first, isTrue);
    },
  );

  test(
    'session boundary drains queued GPS evidence and blocks later ingestion',
    () async {
      final startedAt = DateTime.utc(2026, 7, 12, 12);
      final store = _BlockingPendingSampleStore();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: TestGlobalOdometerController(),
      );
      addTearDown(controller.dispose);
      expect(
        await controller.start(
          tripId: 'trip_ingestion_boundary',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: startedAt,
        ),
        isTrue,
      );

      final firstSampleAt = startedAt.add(const Duration(seconds: 10));
      final firstIngestion = controller.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          recordedAt: firstSampleAt,
          horizontalAccuracyMeters: 5,
        ),
        referenceTime: firstSampleAt,
      );
      await store.pendingSaveStarted.future;

      var cancellationCompleted = false;
      final cancellation = controller
          .cancelActiveTrip(canceledAt: firstSampleAt)
          .whenComplete(() => cancellationCompleted = true);
      await Future<void>.delayed(Duration.zero);
      expect(cancellationCompleted, isFalse);

      final lateSample = await controller.ingest(
        TripLocationSample(
          latitude: 35.0001,
          longitude: -80,
          recordedAt: firstSampleAt.add(const Duration(seconds: 1)),
          horizontalAccuracyMeters: 5,
        ),
        referenceTime: firstSampleAt.add(const Duration(seconds: 1)),
      );
      expect(lateSample, isNull);

      store.allowPendingSave.complete();
      expect((await firstIngestion)?.accepted, isTrue);
      expect(await cancellation, isNull);
      expect(controller.platformStatus, 'trip_cancel_confirmation_required');
      expect(controller.activeSession, isNotNull);
      expect(controller.activeSession?.updatedAt, firstSampleAt);
    },
  );

  test('completion draft cannot race odometer confirmation', () async {
    final startedAt = DateTime.utc(2026, 7, 12, 12);
    final finishedAt = startedAt.add(const Duration(minutes: 1));
    final store = _DelayedReviewMutationStore();
    final odometer = TestGlobalOdometerController();
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
    );
    addTearDown(controller.dispose);
    await controller.start(
      tripId: 'trip_draft_confirmation_race',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: startedAt,
    );
    expect(await controller.finishForReview(finishedAt: finishedAt), isNotNull);

    store.delayNextSave = true;
    final draftSave = controller.saveCompletionDraft(
      tripId: 'trip_draft_confirmation_race',
      endingOdometerDraft: 1010,
    );
    await store.saveStarted.future;

    expect(
      await controller.confirmOdometerReview(
        reviewId: 'trip_draft_confirmation_race',
        confirmedEndingOdometer: 1010,
        confirmedAt: finishedAt.add(const Duration(minutes: 1)),
        userAcknowledgedReviewPrompt: true,
      ),
      isFalse,
    );
    expect(controller.platformStatus, 'session_operation_in_progress');
    expect(odometer.confirmedReading, 1000);

    store.allowSave.complete();
    expect(await draftSave, isTrue);
    expect(
      await controller.confirmOdometerReview(
        reviewId: 'trip_draft_confirmation_race',
        confirmedEndingOdometer: 1010,
        confirmedAt: finishedAt.add(const Duration(minutes: 1)),
        userAcknowledgedReviewPrompt: true,
      ),
      isTrue,
    );
    expect(
      store.reviewForTrip('trip_draft_confirmation_race')?.endingOdometerDraft,
      1010,
    );
    expect(odometer.confirmedReading, 1010);
  });
}
