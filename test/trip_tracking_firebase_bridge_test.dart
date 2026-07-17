import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/firebase/hosted_usage_limits.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_firebase_bridge.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_firestore_contract.dart';
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

  TripTrackingReviewRecord review({bool confirmed = true}) =>
      TripTrackingReviewRecord(
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
        confirmedEndingOdometer: confirmed ? 1013 : null,
        odometerConfirmedAt: confirmed
            ? DateTime.utc(2026, 7, 14, 13, 1)
            : null,
      );

  test(
    'an unconfirmed review cannot enter the Firebase backup queue',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final mirror = TripTrackingFirebaseMirror(
        queueStore: queue,
        uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
          queue: queue,
          sink: _RecordingSink(),
          uploadEnabled: true,
        ),
        personal: true,
        createdByUid: 'firebaseUid-1',
      );

      await expectLater(
        mirror.queueReview(review(confirmed: false)),
        throwsStateError,
      );
      expect(queue.pendingRecords, isEmpty);
    },
  );

  test('a malformed review cannot enter the Firebase backup queue', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final mirror = TripTrackingFirebaseMirror(
      queueStore: queue,
      uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: _RecordingSink(),
        uploadEnabled: true,
      ),
      personal: true,
      createdByUid: 'firebaseUid-1',
    );
    final malformed = TripTrackingReviewRecord.fromMap({
      'id': 'malformed-trip',
      'vehicleId': 'truck-1',
      'startingOdometer': 1000,
      'estimatedEndingOdometer': 1012,
      'profile': 'roadVehicle',
      'engineSnapshot': {
        'totalAcceptedMeters': 100,
        'walkingReviewSuggested': false,
      },
      'confirmedEndingOdometer': 1013,
      'odometerConfirmedAt': DateTime.utc(2026, 7, 14, 13, 1).toIso8601String(),
    });

    await expectLater(mirror.queueReview(malformed), throwsStateError);
    expect(queue.pendingRecords, isEmpty);
  });

  test('flush removes a legacy unconfirmed mileage queue entry', () async {
    final localStore = TripTrackingSessionStore.memory();
    final unconfirmed = review(
      confirmed: false,
    ).copyWith(cloudSyncState: TripTrackingCloudSyncState.queued);
    await localStore.saveReview(unconfirmed);
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    await queue.enqueue(
      MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
        uid: 'firebaseUid-1',
        // The legacy document does not carry local confirmation state, so a
        // formerly queued summary has the same document shape as a confirmed
        // one. Local state is what must block this retry.
        review: review(),
      ),
    );
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

    await mirror.flushPending();

    expect(sink.writes, isEmpty);
    expect(queue.pendingRecords, isEmpty);
    expect(
      localStore.reviewForTrip('trip 1')?.cloudSyncState,
      TripTrackingCloudSyncState.localOnly,
    );
  });

  test('builds a mileage-only document without location evidence', () {
    final doc = MaintainiacFirestoreDocumentBuilder.tripTrackingReviewDocument(
      orgId: 'orgA',
      createdByUid: 'firebaseUid-1',
      review: review(),
    );

    expect(doc.path, 'orgs/orgA/mileageRecords/trip_1');
    expect(doc.data['schema'], 'trip_tracking_review_v1');
    expect(doc.data['createdByUid'], 'firebaseUid-1');
    expect(doc.data['confirmedEndingOdometer'], 1013);
    expect(
      doc.data['odometerConfirmedAt'],
      DateTime.utc(2026, 7, 14, 13, 1).toIso8601String(),
    );
    expect(doc.data['acceptedMeters'], 19312.128);
    expect(doc.data['locationDataIncluded'], isFalse);
    expect(doc.data['visibilityScope'], 'mileage_only');
    expect(
      doc.data.keys.toSet(),
      TripTrackingFirestoreContract.reviewedSummaryFields,
    );
    expect(doc.data.keys, isNot(contains('lastAccepted')));
    expect(doc.data.keys, isNot(contains('walkingEvidence')));
    expect(doc.data.toString(), isNot(contains('latitude')));
    MaintainiacFirestoreUploadPolicy.validateDraft(doc);
  });

  test('document builders reject an unconfirmed mileage review', () {
    expect(
      () =>
          MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
            uid: 'firebaseUid-1',
            review: review(confirmed: false),
          ),
      throwsStateError,
    );
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

  test('local upload policy rejects unknown trip profile and motion states', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
          uid: 'firebaseUid-1',
          review: review(),
        );

    for (final entry in const <String, String>{
      'profile': 'silentTracker',
      'motionState': 'rawLocationStreaming',
    }.entries) {
      expect(
        () => MaintainiacFirestoreUploadPolicy.validateDraft(
          MaintainiacFirestoreDocumentDraft(
            path: doc.path,
            data: {...doc.data, entry.key: entry.value},
          ),
        ),
        throwsArgumentError,
        reason: '${entry.key} must be an allowed trip summary value',
      );
    }
  });

  test(
    'Firestore rules allowlist stays aligned with the trip summary contract',
    () {
      final rules = File('firestore.rules').readAsStringSync();
      final allowlistStart = rules.indexOf(
        'function hasOnlyMileageSummaryFields',
      );
      final allowlistEnd = rules.indexOf(']);', allowlistStart);
      expect(allowlistStart, greaterThanOrEqualTo(0));
      expect(allowlistEnd, greaterThan(allowlistStart));
      final allowlist = rules.substring(allowlistStart, allowlistEnd);

      for (final field in TripTrackingFirestoreContract.reviewedSummaryFields) {
        expect(allowlist, contains("'$field'"));
      }

      final requiredStart = rules.indexOf(
        'function hasRequiredMileageSummaryFields',
      );
      final requiredEnd = rules.indexOf(']);', requiredStart);
      expect(requiredStart, greaterThanOrEqualTo(0));
      expect(requiredEnd, greaterThan(requiredStart));
      final requiredFields = rules.substring(requiredStart, requiredEnd);

      for (final field
          in TripTrackingFirestoreContract.requiredReviewedSummaryFields) {
        expect(requiredFields, contains("'$field'"));
      }

      final valueCheckStart = rules.indexOf(
        'function hasValidMileageSummaryValues',
      );
      final valueCheckEnd = rules.indexOf(
        'function noServerManagedFieldsOnCreate',
        valueCheckStart,
      );
      expect(valueCheckStart, greaterThanOrEqualTo(0));
      expect(valueCheckEnd, greaterThan(valueCheckStart));
      final valueCheck = rules.substring(valueCheckStart, valueCheckEnd);
      expect(rules, contains('function isAllowedTripProfile'));
      expect(rules, contains('function isAllowedTripMotionState'));
      expect(valueCheck, contains('isAllowedTripProfile'));
      expect(valueCheck, contains('isAllowedTripMotionState'));
      expect(valueCheck, contains('startingOdometer >= 0'));
      expect(valueCheck, contains('estimatedEndingOdometer >='));
      expect(
        valueCheck,
        contains('finishedAt >= request.resource.data.startedAt'),
      );
      expect(valueCheck, contains('odometerConfirmedAt >='));
      expect(valueCheck, contains('acceptedMeters >= 0'));
      expect(valueCheck, contains('acceptedSampleCount <='));
      expect(rules, contains('function hasCoherentMileageSummaryDistance'));
      expect(rules, contains('acceptedMeters >= (acceptedMiles - 0.01)'));
      expect(rules, contains('acceptedMiles < odometerDelta + 0.5'));
      expect(rules, contains('request.resource.data.tripId == recordId'));
    },
  );

  test('Firestore mileage reads require consent for fleet visibility', () {
    final rules = File('firestore.rules').readAsStringSync();
    final orgStart = rules.indexOf('match /orgs/{orgId}');
    expect(orgStart, greaterThanOrEqualTo(0));
    final mileageStart = rules.indexOf(
      'match /mileageRecords/{recordId}',
      orgStart,
    );
    final mileageEnd = rules.indexOf('match /dashboardSummaries', mileageStart);
    expect(mileageStart, greaterThanOrEqualTo(0));
    expect(mileageEnd, greaterThan(mileageStart));
    final mileageRules = rules.substring(mileageStart, mileageEnd);

    expect(
      mileageRules,
      contains('resource.data.organizationSharingConsent == true'),
    );
    expect(mileageRules, contains('viewFleetMileageReports'));
    expect(
      mileageRules,
      contains('resource.data.createdByUid == request.auth.uid'),
    );
    expect(mileageRules, contains('allow delete: if false'));
  });

  test(
    'local upload policy rejects location data before it reaches the queue',
    () {
      final doc =
          MaintainiacFirestoreDocumentBuilder.tripTrackingReviewDocument(
            orgId: 'orgA',
            createdByUid: 'firebaseUid-1',
            review: review(),
          );

      for (final entry in <String, Object?>{
        'latitude': 35.0,
        'longitude': -80.0,
        'coordinates': [35.0, -80.0],
        'route': 'raw-route-json',
        'routePoints': const [
          {'latitude': 35.0, 'longitude': -80.0},
        ],
        'polyline': 'encoded_polyline',
        'stopAddress': '123 Private Stop',
        'rawSamples': const [],
        'walkingEvidence': const [],
      }.entries) {
        expect(
          () => MaintainiacFirestoreUploadPolicy.validateDraft(
            MaintainiacFirestoreDocumentDraft(
              path: doc.path,
              data: {...doc.data, entry.key: entry.value},
            ),
          ),
          throwsArgumentError,
          reason: 'raw trip field ${entry.key} must not upload',
        );
      }
    },
  );

  test('local upload policy rejects partial mileage summaries', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
          uid: 'firebaseUid-1',
          review: review(),
        );
    final partial = Map<String, Object?>.from(doc.data)
      ..remove('startingOdometer');

    expect(
      () => MaintainiacFirestoreUploadPolicy.validateDraft(
        MaintainiacFirestoreDocumentDraft(path: doc.path, data: partial),
      ),
      throwsArgumentError,
    );
  });

  test('local upload policy rejects impossible mileage summary values', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
          uid: 'firebaseUid-1',
          review: review(),
        );

    for (final badData in [
      {...doc.data, 'acceptedMeters': -1},
      {...doc.data, 'estimatedEndingOdometer': 999},
      {...doc.data, 'confirmedEndingOdometer': 999},
      {...doc.data}..remove('odometerConfirmedAt'),
      {
        ...doc.data,
        'odometerConfirmedAt': DateTime.utc(
          2026,
          7,
          14,
          12,
          59,
        ).toIso8601String(),
      },
      {...doc.data, 'finishedAt': 'not-a-date'},
      {...doc.data, 'acceptedSampleCount': 999},
      {...doc.data, 'vehicleId': ''},
    ]) {
      expect(
        () => MaintainiacFirestoreUploadPolicy.validateDraft(
          MaintainiacFirestoreDocumentDraft(path: doc.path, data: badData),
        ),
        throwsArgumentError,
      );
    }
  });

  test('local upload policy rejects inconsistent mileage summary math', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
          uid: 'firebaseUid-1',
          review: review(),
        );

    for (final badData in [
      {...doc.data, 'acceptedMiles': 999.0},
      {...doc.data, 'estimatedEndingOdometer': 1011},
    ]) {
      expect(
        () => MaintainiacFirestoreUploadPolicy.validateDraft(
          MaintainiacFirestoreDocumentDraft(path: doc.path, data: badData),
        ),
        throwsArgumentError,
      );
    }
  });

  test('local upload policy rejects organization fields on private mileage', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
          uid: 'firebaseUid-1',
          review: review(),
        );

    expect(
      () => MaintainiacFirestoreUploadPolicy.validateDraft(
        MaintainiacFirestoreDocumentDraft(
          path: doc.path,
          data: {...doc.data, 'organizationSharingConsent': true},
        ),
      ),
      throwsArgumentError,
    );
  });

  test('local upload policy rejects personal mileage UID mismatch', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
          uid: 'firebaseUid-1',
          review: review(),
        );

    expect(
      () => MaintainiacFirestoreUploadPolicy.validateDraft(
        MaintainiacFirestoreDocumentDraft(
          path: 'users/otherUid/mileageRecords/trip_1',
          data: doc.data,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('local upload policy rejects mileage path trip id mismatch', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
          uid: 'firebaseUid-1',
          review: review(),
        );

    expect(
      () => MaintainiacFirestoreUploadPolicy.validateDraft(
        MaintainiacFirestoreDocumentDraft(
          path: 'users/firebaseUid-1/mileageRecords/other_trip',
          data: doc.data,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('local upload policy rejects divergent mileage owner UIDs', () {
    final doc = MaintainiacFirestoreDocumentBuilder.tripTrackingReviewDocument(
      orgId: 'orgA',
      createdByUid: 'firebaseUid-1',
      review: review(),
    );

    expect(
      () => MaintainiacFirestoreUploadPolicy.validateDraft(
        MaintainiacFirestoreDocumentDraft(
          path: doc.path,
          data: {...doc.data, 'updatedByUid': 'otherUid'},
        ),
      ),
      throwsArgumentError,
    );
  });

  test(
    'queues and uploads a reviewed trip while preserving local retry state',
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
      final mirror = TripTrackingFirebaseMirror(
        queueStore: queue,
        uploadCoordinator: coordinator,
        localStore: localStore,
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
    'organization sharing withdrawal preserves an unsent private backup',
    () async {
      final localStore = TripTrackingSessionStore.memory();
      final privateReview = review().copyWith(
        cloudAccountUid: 'firebaseUid-1',
        cloudBackupScope: TripTrackingCloudBackupScope.personal,
        cloudSyncState: TripTrackingCloudSyncState.queued,
      );
      await localStore.saveReview(privateReview);
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      await queue.enqueue(
        MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
          uid: 'firebaseUid-1',
          review: privateReview,
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

      expect(queue.pendingRecords, hasLength(1));
      expect(
        queue.pendingRecords.single.path,
        'users/firebaseUid-1/mileageRecords/trip_1',
      );
      expect(
        localStore.reviewForTrip('trip 1')?.cloudSyncState,
        TripTrackingCloudSyncState.queued,
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

  test('an unsafe authenticated UID cannot queue mileage backup', () async {
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
      createdByUid: 'unsafe/uid',
    );

    await expectLater(mirror.queueReview(review()), throwsStateError);

    expect(queue.pendingRecords, isEmpty);
    expect(sink.writes, isEmpty);
    final stored = localStore.reviewForTrip('trip 1');
    expect(stored?.cloudSyncState, TripTrackingCloudSyncState.pending);
    expect(stored?.cloudSyncError, contains('valid authenticated account'));
  });

  test(
    'an unsafe authenticated UID cannot flush pending mileage backup',
    () async {
      final localStore = TripTrackingSessionStore.memory();
      await localStore.saveReview(
        review().copyWith(cloudSyncState: TripTrackingCloudSyncState.pending),
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
        createdByUid: 'unsafe uid with spaces',
      );

      await mirror.flushPending();

      expect(queue.pendingRecords, isEmpty);
      expect(sink.writes, isEmpty);
      final stored = localStore.reviewForTrip('trip 1');
      expect(stored?.cloudSyncState, TripTrackingCloudSyncState.pending);
      expect(stored?.cloudSyncError, contains('valid authenticated account'));
    },
  );

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

  test(
    'broken backup consent read keeps reviewed mileage local only',
    () async {
      final localStore = TripTrackingSessionStore.memory();
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
        backupEnabled: () => throw StateError('settings unavailable'),
      );

      await mirror.queueReview(review());
      await mirror.flushPending();

      expect(sink.writes, isEmpty);
      expect(queue.pendingRecords, isEmpty);
      expect(
        localStore.reviewForTrip('trip 1')?.cloudSyncState,
        TripTrackingCloudSyncState.localOnly,
      );
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
    'a later flush fails closed when backup consent is now disabled',
    () async {
      final localStore = TripTrackingSessionStore.memory();
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final sink = _RecordingSink();
      var backupEnabled = true;
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
        backupEnabled: () => backupEnabled,
      );

      await mirror.queueReview(review());
      expect(queue.pendingRecords, hasLength(1));

      backupEnabled = false;
      await mirror.flushPending();

      expect(sink.writes, isEmpty);
      expect(queue.pendingRecords, isEmpty);
      expect(
        localStore.reviewForTrip('trip 1')?.cloudSyncState,
        TripTrackingCloudSyncState.localOnly,
      );
    },
  );

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

  test('automatic trip backup retry preserves queue backoff', () async {
    final localStore = TripTrackingSessionStore.memory();
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final failingMirror = TripTrackingFirebaseMirror(
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

    await failingMirror.queueReview(review());
    await failingMirror.flushPending();
    expect(queue.pendingRecords.single.attemptCount, 1);
    expect(
      localStore.reviewForTrip('trip 1')?.cloudSyncState,
      TripTrackingCloudSyncState.failed,
    );

    final sink = _RecordingSink();
    final retryMirror = TripTrackingFirebaseMirror(
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

    await retryMirror.flushPending();

    expect(sink.writes, isEmpty);
    expect(queue.pendingRecords.single.attemptCount, 1);
    expect(queue.pendingRecords.single.nextAttemptAtUtc, isNotNull);
  });

  test('network-blocked trip backup remains pending for retry', () async {
    final localStore = TripTrackingSessionStore.memory();
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingSink();
    final mirror = TripTrackingFirebaseMirror(
      queueStore: queue,
      uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: sink,
        uploadEnabled: true,
        uploadNetworkAllowed: () => false,
      ),
      localStore: localStore,
      personal: true,
      createdByUid: 'firebaseUid-1',
    );

    await mirror.queueReview(review());
    await mirror.flushPending();

    expect(sink.writes, isEmpty);
    expect(queue.pendingRecords, hasLength(1));
    expect(
      localStore.reviewForTrip('trip 1')?.cloudSyncState,
      TripTrackingCloudSyncState.pending,
    );
    expect(
      localStore.reviewForTrip('trip 1')?.cloudSyncError,
      contains('selected network'),
    );
  });

  test('quota-blocked trip backup remains pending for retry', () async {
    final localStore = TripTrackingSessionStore.memory();
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingSink();
    final mirror = TripTrackingFirebaseMirror(
      queueStore: queue,
      uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: sink,
        uploadEnabled: true,
        freeSyncsUsedInWindow: HostedUsageLimits.freeUserSyncsPer24HourWindow,
      ),
      localStore: localStore,
      personal: true,
      createdByUid: 'firebaseUid-1',
    );

    await mirror.queueReview(review());
    await mirror.flushPending();

    expect(sink.writes, isEmpty);
    expect(queue.pendingRecords, hasLength(1));
    expect(
      localStore.reviewForTrip('trip 1')?.cloudSyncState,
      TripTrackingCloudSyncState.pending,
    );
    expect(
      localStore.reviewForTrip('trip 1')?.cloudSyncError,
      contains('Free backup sync limit reached'),
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
