import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_firebase_bridge.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'trip_tracking_firebase_bridge_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  TripTrackingReviewRecord review() => TripTrackingReviewRecord(
    id: 'trip 1',
    vehicleId: 'truck-1',
    startingOdometer: 1000,
    estimatedEndingOdometer: 1012,
    profile: TripTrackingProfile.roadVehicle,
    startedAt: DateTime.utc(2026, 7, 14, 12),
    finishedAt: DateTime.utc(2026, 7, 14, 13),
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 19312.128,
      walkingReviewSuggested: true,
      motionState: TripMotionState.stopped,
    ),
  );

  test('builds a mileage-only document without location evidence', () {
    final doc = MaintainiacFirestoreDocumentBuilder.tripTrackingReviewDocument(
      orgId: 'orgA',
      createdByUid: 'firebaseUid-1',
      review: review(),
    );

    expect(doc.path, 'orgs/orgA/mileageRecords/trip_1');
    expect(doc.data['schema'], 'trip_tracking_review_v1');
    expect(doc.data['createdByUid'], 'firebaseUid-1');
    expect(doc.data['acceptedMeters'], 19312.128);
    expect(doc.data['locationDataIncluded'], isFalse);
    expect(doc.data['visibilityScope'], 'mileage_only');
    expect(doc.data.keys.toSet(), {
      'schema',
      'tripId',
      'orgId',
      'createdByUid',
      'updatedByUid',
      'vehicleId',
      'profile',
      'startedAt',
      'finishedAt',
      'createdAt',
      'updatedAt',
      'startingOdometer',
      'estimatedEndingOdometer',
      'acceptedMeters',
      'acceptedMiles',
      'walkingReviewSuggested',
      'motionState',
      'receivedSampleCount',
      'acceptedSampleCount',
      'locationDataIncluded',
      'visibilityScope',
    });
    expect(doc.data.keys, isNot(contains('lastAccepted')));
    expect(doc.data.keys, isNot(contains('walkingEvidence')));
    expect(doc.data.toString(), isNot(contains('latitude')));
    MaintainiacFirestoreUploadPolicy.validateDraft(doc);
  });

  test('builds solo-user mileage backup under the authenticated user', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
          uid: 'firebaseUid-1',
          review: review(),
        );

    expect(doc.path, 'users/firebaseUid-1/mileageRecords/trip_1');
    expect(doc.data['orgId'], isNull);
    expect(doc.data['createdByUid'], 'firebaseUid-1');
    MaintainiacFirestoreUploadPolicy.validateDraft(doc);
  });

  test(
    'queues and uploads a reviewed trip while preserving local retry state',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final sink = _RecordingSink();
      final coordinator = MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: sink,
        uploadEnabled: true,
      );
      final mirror = TripTrackingFirebaseMirror(
        queueStore: queue,
        uploadCoordinator: coordinator,
        orgId: 'orgA',
        createdByUid: 'firebaseUid-1',
      );

      await mirror.queueReview(review());
      expect(queue.pendingRecords, hasLength(1));
      await mirror.flushPending();

      expect(sink.writes, hasLength(1));
      expect(queue.pendingRecords, isEmpty);
      expect(sink.writes.single['locationDataIncluded'], isFalse);
    },
  );

  test('organization backup requires separate sharing consent', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final mirror = TripTrackingFirebaseMirror(
      queueStore: queue,
      uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: _RecordingSink(),
        uploadEnabled: true,
      ),
      orgId: 'orgA',
      createdByUid: 'firebaseUid-1',
      organizationSharingEnabled: () => false,
    );

    await mirror.queueReview(review());

    expect(queue.pendingRecords, hasLength(1));
    expect(
      queue.pendingRecords.single.path,
      'users/firebaseUid-1/mileageRecords/trip_1',
    );
  });

  test(
    'revoking organization sharing removes an unsent company record',
    () async {
      final localStore = TripTrackingSessionStore.memory();
      final organizationReview = review().copyWith(
        cloudAccountUid: 'firebaseUid-1',
        cloudBackupScope: TripTrackingCloudBackupScope.organization,
        cloudOrganizationId: 'orgA',
        cloudSyncState: TripTrackingCloudSyncState.queued,
      );
      await localStore.saveReview(organizationReview);
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      await queue.enqueue(
        MaintainiacFirestoreDocumentBuilder.tripTrackingReviewDocument(
          orgId: 'orgA',
          createdByUid: 'firebaseUid-1',
          review: organizationReview,
        ),
      );
      final mirror = TripTrackingFirebaseMirror(
        queueStore: queue,
        uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
          queue: queue,
          sink: _RecordingSink(),
          uploadEnabled: true,
        ),
        localStore: localStore,
        orgId: 'orgA',
        createdByUid: 'firebaseUid-1',
        organizationSharingEnabled: () => false,
      );

      await mirror.withdrawOrganizationSharingConsent();

      expect(queue.pendingRecords, isEmpty);
      expect(
        localStore.reviewForTrip('trip 1')?.cloudSyncState,
        TripTrackingCloudSyncState.localOnly,
      );
    },
  );

  test(
    'organization sharing withdrawal clears a legacy unscoped queue record',
    () async {
      final localStore = TripTrackingSessionStore.memory();
      await localStore.saveReview(
        review().copyWith(cloudSyncState: TripTrackingCloudSyncState.queued),
      );
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      await queue.enqueue(
        MaintainiacFirestoreDocumentBuilder.tripTrackingReviewDocument(
          orgId: 'orgA',
          createdByUid: 'firebaseUid-1',
          review: review(),
        ),
      );
      final mirror = TripTrackingFirebaseMirror(
        queueStore: queue,
        uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
          queue: queue,
          sink: _RecordingSink(),
          uploadEnabled: true,
        ),
        localStore: localStore,
        orgId: 'orgA',
        createdByUid: 'firebaseUid-1',
        organizationSharingEnabled: () => false,
      );

      await mirror.withdrawOrganizationSharingConsent();

      expect(queue.pendingRecords, isEmpty);
      expect(
        localStore.reviewForTrip('trip 1')?.cloudSyncState,
        TripTrackingCloudSyncState.localOnly,
      );
    },
  );

  test(
    'a review finished before sign-in retries after authentication becomes available',
    () async {
      final localStore = TripTrackingSessionStore.memory();
      await localStore.saveReview(review());
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final sink = _RecordingSink();
      final coordinator = MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: sink,
        uploadEnabled: true,
      );
      final signedOut = TripTrackingFirebaseMirror(
        queueStore: queue,
        uploadCoordinator: coordinator,
        localStore: localStore,
        personal: true,
      );

      await expectLater(signedOut.queueReview(review()), throwsStateError);
      expect(
        localStore.reviewForTrip('trip 1')?.cloudSyncState,
        TripTrackingCloudSyncState.pending,
      );

      final signedIn = TripTrackingFirebaseMirror(
        queueStore: queue,
        uploadCoordinator: coordinator,
        localStore: localStore,
        personal: true,
        createdByUid: 'firebaseUid-1',
      );
      await signedIn.flushPending();

      expect(sink.writes, hasLength(1));
      expect(
        localStore.reviewForTrip('trip 1')?.cloudSyncState,
        TripTrackingCloudSyncState.synced,
      );
    },
  );

  test('a signed-out auth state never falls back to the startup UID', () async {
    final localStore = TripTrackingSessionStore.memory();
    await localStore.saveReview(review());
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingSink();
    final coordinator = MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink,
      uploadEnabled: true,
    );
    String? currentUid;
    final mirror = TripTrackingFirebaseMirror(
      queueStore: queue,
      uploadCoordinator: coordinator,
      localStore: localStore,
      personal: true,
      createdByUid: 'stale-startup-uid',
      authenticatedUid: () => currentUid,
    );

    await expectLater(mirror.queueReview(review()), throwsStateError);
    expect(sink.writes, isEmpty);
    expect(
      localStore.reviewForTrip('trip 1')?.cloudSyncState,
      TripTrackingCloudSyncState.pending,
    );

    currentUid = 'fresh-authenticated-uid';
    await mirror.flushPending();

    expect(sink.writes, hasLength(1));
    expect(
      sink.paths.single,
      'users/fresh-authenticated-uid/mileageRecords/trip_1',
    );
  });

  test(
    'an account switch cannot adopt an already-bound mileage review',
    () async {
      final localStore = TripTrackingSessionStore.memory();
      await localStore.saveReview(
        review().copyWith(
          cloudAccountUid: 'original-account-uid',
          cloudSyncState: TripTrackingCloudSyncState.pending,
        ),
      );
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final sink = _RecordingSink();
      final mirror = TripTrackingFirebaseMirror(
        queueStore: queue,
        uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
          queue: queue,
          sink: sink,
          uploadEnabled: true,
        ),
        localStore: localStore,
        personal: true,
        createdByUid: 'different-account-uid',
      );

      await mirror.flushPending();

      expect(sink.writes, isEmpty);
      expect(queue.pendingRecords, isEmpty);
      final stored = localStore.reviewForTrip('trip 1');
      expect(stored?.cloudSyncState, TripTrackingCloudSyncState.pending);
      expect(
        stored?.cloudSyncError,
        contains('original account and organization'),
      );
    },
  );

  test(
    'an organization switch cannot redirect a queued mileage review',
    () async {
      final localStore = TripTrackingSessionStore.memory();
      await localStore.saveReview(
        review().copyWith(
          cloudAccountUid: 'firebaseUid-1',
          cloudBackupScope: TripTrackingCloudBackupScope.organization,
          cloudOrganizationId: 'original-org',
          cloudSyncState: TripTrackingCloudSyncState.pending,
        ),
      );
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final sink = _RecordingSink();
      final mirror = TripTrackingFirebaseMirror(
        queueStore: queue,
        uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
          queue: queue,
          sink: sink,
          uploadEnabled: true,
        ),
        localStore: localStore,
        orgId: 'different-org',
        createdByUid: 'firebaseUid-1',
      );

      await mirror.flushPending();

      expect(sink.writes, isEmpty);
      expect(queue.pendingRecords, isEmpty);
      final stored = localStore.reviewForTrip('trip 1');
      expect(stored?.cloudSyncState, TripTrackingCloudSyncState.pending);
      expect(
        stored?.cloudSyncError,
        contains('original account and organization'),
      );
    },
  );

  test(
    'backup-off consent keeps reviewed mileage local until explicitly enabled',
    () async {
      final localStore = TripTrackingSessionStore.memory();
      await localStore.saveReview(review());
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final sink = _RecordingSink();
      final coordinator = MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: sink,
        uploadEnabled: true,
      );
      var backupEnabled = false;
      final mirror = TripTrackingFirebaseMirror(
        queueStore: queue,
        uploadCoordinator: coordinator,
        localStore: localStore,
        personal: true,
        createdByUid: 'firebaseUid-1',
        backupEnabled: () => backupEnabled,
      );

      await mirror.queueReview(review());
      expect(sink.writes, isEmpty);
      expect(
        localStore.reviewForTrip('trip 1')?.cloudSyncState,
        TripTrackingCloudSyncState.localOnly,
      );

      backupEnabled = true;
      await mirror.flushPending();
      expect(sink.writes, isEmpty);

      await mirror.queueReview(review());
      await mirror.flushPending();
      expect(sink.writes, hasLength(1));
    },
  );

  test('revoking backup consent removes an unsent mileage summary', () async {
    final localStore = TripTrackingSessionStore.memory();
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    var backupEnabled = true;
    final mirror = TripTrackingFirebaseMirror(
      queueStore: queue,
      uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: _RecordingSink(),
        uploadEnabled: true,
      ),
      localStore: localStore,
      personal: true,
      createdByUid: 'firebaseUid-1',
      backupEnabled: () => backupEnabled,
    );

    await mirror.queueReview(review());
    expect(queue.pendingRecords, hasLength(1));

    backupEnabled = false;
    await mirror.queueReview(localStore.reviewForTrip('trip 1')!);

    expect(queue.pendingRecords, isEmpty);
    expect(
      localStore.reviewForTrip('trip 1')?.cloudSyncState,
      TripTrackingCloudSyncState.localOnly,
    );
  });

  test(
    'withdrawal clears every unsent backup while retaining local reviews',
    () async {
      final localStore = TripTrackingSessionStore.memory();
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final mirror = TripTrackingFirebaseMirror(
        queueStore: queue,
        uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
          queue: queue,
          sink: _RecordingSink(),
          uploadEnabled: true,
        ),
        localStore: localStore,
        personal: true,
        createdByUid: 'firebaseUid-1',
      );
      await mirror.queueReview(review());

      await mirror.withdrawBackupConsent();

      expect(queue.pendingRecords, isEmpty);
      expect(localStore.reviewForTrip('trip 1'), isNotNull);
      expect(
        localStore.reviewForTrip('trip 1')?.cloudSyncState,
        TripTrackingCloudSyncState.localOnly,
      );
    },
  );

  test('withdrawal clears a legacy unsent company backup record', () async {
    final localStore = TripTrackingSessionStore.memory();
    final legacyReview = review().copyWith(
      cloudAccountUid: 'firebaseUid-1',
      cloudSyncState: TripTrackingCloudSyncState.queued,
    );
    await localStore.saveReview(legacyReview);
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    await queue.enqueue(
      MaintainiacFirestoreDocumentBuilder.tripTrackingReviewDocument(
        orgId: 'org-1',
        createdByUid: 'firebaseUid-1',
        review: legacyReview,
      ),
    );
    final mirror = TripTrackingFirebaseMirror(
      queueStore: queue,
      uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: _RecordingSink(),
        uploadEnabled: true,
      ),
      localStore: localStore,
      orgId: 'org-1',
      createdByUid: 'firebaseUid-1',
    );

    await mirror.withdrawBackupConsent();

    expect(queue.pendingRecords, isEmpty);
    expect(
      localStore.reviewForTrip('trip 1')?.cloudSyncState,
      TripTrackingCloudSyncState.localOnly,
    );
  });

  test('missing organization keeps company backup durably retryable', () async {
    final localStore = TripTrackingSessionStore.memory();
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final mirror = TripTrackingFirebaseMirror(
      queueStore: queue,
      uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: _RecordingSink(),
        uploadEnabled: true,
      ),
      localStore: localStore,
      createdByUid: 'firebaseUid-1',
    );

    await expectLater(mirror.queueReview(review()), throwsStateError);
    final stored = localStore.reviewForTrip('trip 1');
    expect(stored?.cloudSyncState, TripTrackingCloudSyncState.pending);
    expect(stored?.cloudSyncError, contains('organization'));
    expect(queue.pendingRecords, isEmpty);

    final sink = _RecordingSink();
    final retryMirror = TripTrackingFirebaseMirror(
      queueStore: queue,
      uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: sink,
        uploadEnabled: true,
      ),
      localStore: localStore,
      createdByUid: 'firebaseUid-1',
    );
    await retryMirror.flushPending();
    expect(sink.writes, isEmpty);
    expect(
      localStore.reviewForTrip('trip 1')?.cloudSyncState,
      TripTrackingCloudSyncState.pending,
    );
  });

  test('overlapping flush requests share one upload attempt', () async {
    final localStore = TripTrackingSessionStore.memory();
    await localStore.saveReview(review());
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingSink();
    final mirror = TripTrackingFirebaseMirror(
      queueStore: queue,
      uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: sink,
        uploadEnabled: true,
      ),
      localStore: localStore,
      personal: true,
      createdByUid: 'firebaseUid-1',
    );

    await mirror.queueReview(review());
    await Future.wait([mirror.flushPending(), mirror.flushPending()]);

    expect(sink.writes, hasLength(1));
    expect(
      localStore.reviewForTrip('trip 1')?.cloudSyncState,
      TripTrackingCloudSyncState.synced,
    );
  });

  test(
    'consent withdrawal clears a Firebase write that previously failed',
    () async {
      final localStore = TripTrackingSessionStore.memory();
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final mirror = TripTrackingFirebaseMirror(
        queueStore: queue,
        uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
          queue: queue,
          sink: _RecordingSink(throwOnWrite: true),
          uploadEnabled: true,
        ),
        localStore: localStore,
        personal: true,
        createdByUid: 'firebaseUid-1',
      );

      await mirror.queueReview(review());
      await mirror.flushPending();
      expect(
        localStore.reviewForTrip('trip 1')?.cloudSyncState,
        TripTrackingCloudSyncState.failed,
      );
      expect(queue.pendingRecords, hasLength(1));

      await mirror.withdrawBackupConsent();

      expect(queue.pendingRecords, isEmpty);
      expect(
        localStore.reviewForTrip('trip 1')?.cloudSyncState,
        TripTrackingCloudSyncState.localOnly,
      );
    },
  );
}

class _RecordingSink implements MaintainiacFirestoreDocumentSink {
  _RecordingSink({this.throwOnWrite = false});

  final bool throwOnWrite;
  final writes = <Map<String, Object?>>[];
  final paths = <String>[];

  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) async {
    if (throwOnWrite) throw StateError('simulated Firestore outage');
    paths.add(path);
    writes.add(Map<String, Object?>.from(data));
  }
}
