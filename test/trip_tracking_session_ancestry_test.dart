import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test('split ancestry requires a distinct safe parent', () {
    const ancestry = TripTrackingSessionAncestry.splitChild(
      parentSessionId: 'parent-trip',
    );
    expect(ancestry.isValidFor('child-trip'), isTrue);
    expect(ancestry.isValidFor('parent-trip'), isFalse);
    expect(
      TripTrackingSessionAncestry.tryFromMap(
        ancestry.toMap(),
        sessionId: 'child-trip',
      )?.parentSessionId,
      'parent-trip',
    );
    expect(
      TripTrackingSessionAncestry.tryFromMap({
        ...ancestry.toMap(),
        'parentSessionId': 12,
      }, sessionId: 'child-trip'),
      isNull,
    );
  });

  test('merge ancestry rejects duplicates, self-reference, and one source', () {
    final valid = TripTrackingSessionAncestry.mergeResult(
      sourceSessionIds: ['trip-a', 'trip-b'],
    );
    expect(valid.isValidFor('merged-trip'), isTrue);
    expect(
      TripTrackingSessionAncestry.mergeResult(
        sourceSessionIds: ['trip-a'],
      ).isValidFor('merged-trip'),
      isFalse,
    );
    expect(
      TripTrackingSessionAncestry.tryFromMap({
        ...valid.toMap(),
        'sourceSessionIds': ['trip-a', 2],
      }, sessionId: 'merged-trip'),
      isNull,
    );
    expect(
      TripTrackingSessionAncestry.mergeResult(
        sourceSessionIds: ['trip-a', 'trip-a'],
      ).isValidFor('merged-trip'),
      isFalse,
    );
    expect(
      TripTrackingSessionAncestry.mergeResult(
        sourceSessionIds: ['trip-a', 'merged-trip'],
      ).isValidFor('merged-trip'),
      isFalse,
    );
    final mutableSources = ['trip-a', 'trip-b'];
    final immutable = TripTrackingSessionAncestry.mergeResult(
      sourceSessionIds: mutableSources,
    );
    mutableSources.add('trip-c');
    expect(immutable.sourceSessionIds, ['trip-a', 'trip-b']);
    expect(
      () => immutable.sourceSessionIds.add('trip-c'),
      throwsUnsupportedError,
    );
  });

  test(
    'session persistence preserves valid ancestry and distrusts malformed ancestry',
    () {
      final at = DateTime.utc(2026, 7, 22, 22);
      final session = TripTrackingSessionRecord(
        id: 'child-trip',
        vehicleId: 'vehicle-1',
        startingOdometer: 12000,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: at,
        updatedAt: at,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: false,
        ),
        ancestry: const TripTrackingSessionAncestry.splitChild(
          parentSessionId: 'parent-trip',
        ),
      );
      final restored = TripTrackingSessionRecord.fromMap(session.toMap());
      expect(restored.hasValidTimeline, isTrue);
      expect(restored.ancestry?.parentSessionId, 'parent-trip');
      expect(restored.copyWith().ancestry?.parentSessionId, 'parent-trip');

      final malformed = TripTrackingSessionRecord.fromMap({
        ...session.toMap(),
        'ancestry': {
          'schemaVersion': 1,
          'kind': 'splitChild',
          'parentSessionId': 'child-trip',
        },
      });
      expect(malformed.hasValidTimeline, isFalse);
      expect(malformed.ancestry, isNull);
    },
  );

  test(
    'controller accepts only valid explicit lineage at session creation',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle-1',
          initialReading: 12000,
        ),
      );
      addTearDown(controller.dispose);
      final at = DateTime.utc(2026, 7, 22, 20);
      expect(
        await controller.start(
          tripId: 'parent-trip',
          vehicleId: 'vehicle-1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: at,
        ),
        isTrue,
      );
      expect(
        await controller.finishForReview(
          finishedAt: at.add(const Duration(minutes: 1)),
        ),
        isNotNull,
      );
      expect(
        await controller.start(
          tripId: 'unconfirmed-child',
          vehicleId: 'vehicle-1',
          profile: TripTrackingProfile.roadVehicle,
          ancestry: const TripTrackingSessionAncestry.splitChild(
            parentSessionId: 'parent-trip',
          ),
          startedAt: at.add(const Duration(minutes: 2)),
        ),
        isFalse,
      );
      expect(controller.platformStatus, 'split_parent_unavailable');
      expect(
        await controller.confirmOdometerReview(
          reviewId: 'parent-trip',
          confirmedEndingOdometer: 12000,
          confirmedAt: at.add(const Duration(minutes: 1)),
          userAcknowledgedReviewPrompt: true,
        ),
        isTrue,
      );
      expect(
        await controller.start(
          tripId: 'child-trip',
          vehicleId: 'vehicle-1',
          profile: TripTrackingProfile.roadVehicle,
          ancestry: const TripTrackingSessionAncestry.splitChild(
            parentSessionId: 'parent-trip',
          ),
          startedAt: at.add(const Duration(minutes: 2)),
        ),
        isTrue,
      );
      expect(
        controller.activeSession?.ancestry?.parentSessionId,
        'parent-trip',
      );
      final childReview = await controller.finishForReview(
        finishedAt: at.add(const Duration(minutes: 3)),
      );
      expect(childReview?.ancestry?.parentSessionId, 'parent-trip');
      expect(
        childReview?.toMap()['ancestry'],
        containsPair('kind', 'splitChild'),
      );
      expect(
        await controller.confirmOdometerReview(
          reviewId: 'child-trip',
          confirmedEndingOdometer: 12000,
          confirmedAt: at.add(const Duration(minutes: 3)),
          userAcknowledgedReviewPrompt: true,
        ),
        isTrue,
      );
      expect(
        await controller.start(
          tripId: 'profile-switched-child',
          vehicleId: 'vehicle-1',
          profile: TripTrackingProfile.roadVehicle,
          profileId: 'different-profile',
          ancestry: const TripTrackingSessionAncestry.splitChild(
            parentSessionId: 'child-trip',
          ),
          startedAt: at.add(const Duration(minutes: 4)),
        ),
        isTrue,
      );
      expect(controller.activeSession?.effectiveProfileId, 'different-profile');
      await controller.cancelActiveTrip(userConfirmed: true);

      expect(
        await controller.start(
          tripId: 'self-trip',
          vehicleId: 'vehicle-1',
          profile: TripTrackingProfile.roadVehicle,
          ancestry: const TripTrackingSessionAncestry.splitChild(
            parentSessionId: 'self-trip',
          ),
        ),
        isFalse,
      );
      expect(controller.activeSession, isNull);
      expect(controller.platformStatus, 'session_ancestry_invalid');

      expect(
        await controller.start(
          tripId: 'orphan-child',
          vehicleId: 'vehicle-1',
          profile: TripTrackingProfile.roadVehicle,
          ancestry: const TripTrackingSessionAncestry.splitChild(
            parentSessionId: 'missing-parent',
          ),
        ),
        isFalse,
      );
      expect(controller.platformStatus, 'split_parent_unavailable');

      expect(
        await controller.start(
          tripId: 'reused-parent-child',
          vehicleId: 'vehicle-1',
          profile: TripTrackingProfile.roadVehicle,
          ancestry: const TripTrackingSessionAncestry.splitChild(
            parentSessionId: 'parent-trip',
          ),
        ),
        isFalse,
      );
      expect(controller.platformStatus, 'split_parent_unavailable');

      expect(
        await controller.start(
          tripId: 'merged-trip',
          vehicleId: 'vehicle-1',
          profile: TripTrackingProfile.roadVehicle,
          ancestry: TripTrackingSessionAncestry.mergeResult(
            sourceSessionIds: ['trip-a', 'trip-b'],
          ),
        ),
        isFalse,
      );
      expect(controller.activeSession, isNull);
    },
  );

  test(
    'confirmed lineage can cross to a separately scoped vehicle odometer',
    () async {
      final store = TripTrackingSessionStore.memory();
      final at = DateTime.utc(2026, 7, 22, 18);
      final firstVehicle = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle-1',
          initialReading: 12000,
        ),
      );
      addTearDown(firstVehicle.dispose);
      await firstVehicle.start(
        tripId: 'vehicle-1-parent',
        vehicleId: 'vehicle-1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: at,
      );
      await firstVehicle.finishForReview(
        finishedAt: at.add(const Duration(minutes: 1)),
      );
      expect(
        await firstVehicle.confirmOdometerReview(
          reviewId: 'vehicle-1-parent',
          confirmedEndingOdometer: 12000,
          confirmedAt: at.add(const Duration(minutes: 1)),
          userAcknowledgedReviewPrompt: true,
        ),
        isTrue,
      );

      final secondVehicle = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle-2',
          initialReading: 5000,
        ),
      );
      expect(
        await secondVehicle.start(
          tripId: 'vehicle-2-child',
          vehicleId: 'vehicle-2',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: at.add(const Duration(minutes: 2)),
          ancestry: const TripTrackingSessionAncestry.splitChild(
            parentSessionId: 'vehicle-1-parent',
          ),
        ),
        isTrue,
      );
      expect(secondVehicle.activeSession?.startingOdometer, 5000);
      expect(secondVehicle.activeSession?.vehicleId, 'vehicle-2');
      secondVehicle.dispose();

      final recoveredVehicle = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle-2',
          initialReading: 5000,
        ),
      );
      addTearDown(recoveredVehicle.dispose);
      expect(await recoveredVehicle.restore(), isTrue);
      expect(
        recoveredVehicle.activeSession?.ancestry?.parentSessionId,
        'vehicle-1-parent',
      );
      expect(recoveredVehicle.activeSession?.startingOdometer, 5000);
    },
  );

  for (final failurePoint in _SplitAncestryFailurePoint.values) {
    test(
      'split ancestry ${failurePoint.name} storage failure is controlled',
      () async {
        final odometer = GlobalOdometerController(
          vehicleId: 'vehicle-1',
          initialReading: 12000,
        );
        final controller = TripTrackingController(
          sessionStore: _FailingSplitAncestryStore(failurePoint),
          odometer: odometer,
        );
        addTearDown(controller.dispose);

        expect(
          await controller.start(
            tripId: 'child-trip',
            vehicleId: 'vehicle-1',
            profile: TripTrackingProfile.roadVehicle,
            ancestry: const TripTrackingSessionAncestry.splitChild(
              parentSessionId: 'parent-trip',
            ),
          ),
          isFalse,
        );
        expect(controller.platformStatus, 'storage_failed');
        expect(
          controller.platformError,
          'Could not read local split-trip ancestry evidence.',
        );
        expect(controller.activeSession, isNull);
        expect(odometer.hasLiveTripProjection, isFalse);
      },
    );
  }

  test('user pause exact contract state survives process recovery', () async {
    final store = TripTrackingSessionStore.memory();
    final at = DateTime.utc(2026, 7, 22, 22);
    await store.save(
      TripTrackingSessionRecord(
        id: 'paused-contract-trip',
        vehicleId: 'vehicle-1',
        startingOdometer: 1000,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: at,
        updatedAt: at,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: false,
        ),
        lifecycleState: TripTrackingSessionLifecycleState.paused,
        pauseKind: TripTrackingPauseKind.user,
        persistedContractState:
            TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
      ),
    );

    final recovered = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle-1',
        initialReading: 1000,
      ),
    );
    addTearDown(recovered.dispose);
    expect(await recovered.restore(), isTrue);
    expect(
      recovered.activeSession?.effectiveContractState,
      TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
    );
  });
}

enum _SplitAncestryFailurePoint { parentReview, pendingReviews }

class _FailingSplitAncestryStore extends TripTrackingSessionStore {
  _FailingSplitAncestryStore(this.failurePoint) : super.memory();

  final _SplitAncestryFailurePoint failurePoint;

  @override
  TripTrackingReviewRecord? reviewForTrip(String tripId) {
    if (failurePoint == _SplitAncestryFailurePoint.parentReview) {
      throw StateError('parent review unavailable');
    }
    return null;
  }

  @override
  List<TripTrackingReviewRecord> get pendingReviews {
    if (failurePoint == _SplitAncestryFailurePoint.pendingReviews) {
      throw StateError('pending reviews unavailable');
    }
    return const <TripTrackingReviewRecord>[];
  }
}
