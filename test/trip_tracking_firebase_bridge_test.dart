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

  TripTrackingReviewRecord review({bool confirmed = true, String? id}) =>
      TripTrackingReviewRecord(
        id: id ?? 'trip 1',
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

  test('mileage backup clamps impossible diagnostic counters', () {
    final source = review();
    final doc =
        MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
          uid: 'firebaseUid-1',
          review: TripTrackingReviewRecord(
            id: source.id,
            vehicleId: source.vehicleId,
            startingOdometer: source.startingOdometer,
            estimatedEndingOdometer: source.estimatedEndingOdometer,
            profile: source.profile,
            startedAt: source.startedAt,
            finishedAt: source.finishedAt,
            engineSnapshot: const TripTrackingEngineSnapshot(
              totalAcceptedMeters: 19312.128,
              walkingReviewSuggested: false,
              diagnostics: TripTrackingDiagnostics(
                receivedSamples: 2,
                acceptedSamples: 5,
              ),
            ),
            confirmedEndingOdometer: source.confirmedEndingOdometer,
            odometerConfirmedAt: source.odometerConfirmedAt,
          ),
        );

    expect(doc.data['receivedSampleCount'], 2);
    expect(doc.data['acceptedSampleCount'], 0);
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

  test('document builders reject confirmed reviews with invalid timelines', () {
    final invalidTimeline = TripTrackingReviewRecord.fromMap({
      ...review().toMap(),
      'finishedAt': DateTime.utc(2026, 7, 14, 11).toIso8601String(),
    });

    expect(
      () =>
          MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
            uid: 'firebaseUid-1',
            review: invalidTimeline,
          ),
      throwsStateError,
    );
  });

  test('document builders reject impossible mileage odometer math', () {
    TripTrackingReviewRecord impossibleReview({
      required int estimatedEndingOdometer,
      required int confirmedEndingOdometer,
    }) => TripTrackingReviewRecord(
      id: 'trip_bad_math',
      vehicleId: 'truck-1',
      startingOdometer: 1000,
      estimatedEndingOdometer: estimatedEndingOdometer,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 14, 12),
      finishedAt: DateTime.utc(2026, 7, 14, 13),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 19312.128,
        walkingReviewSuggested: false,
      ),
      confirmedEndingOdometer: confirmedEndingOdometer,
      odometerConfirmedAt: DateTime.utc(2026, 7, 14, 13, 1),
    );

    expect(
      () =>
          MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
            uid: 'firebaseUid-1',
            review: impossibleReview(
              estimatedEndingOdometer: 999,
              confirmedEndingOdometer: 1013,
            ),
          ),
      throwsArgumentError,
    );
    expect(
      () =>
          MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
            uid: 'firebaseUid-1',
            review: impossibleReview(
              estimatedEndingOdometer: 1012,
              confirmedEndingOdometer: 999,
            ),
          ),
      throwsStateError,
    );
  });

  test('document builders allow odometer truth below GPS estimate', () {
    final odometerReview = TripTrackingReviewRecord(
      id: 'trip_odometer_lower_than_gps',
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
      confirmedEndingOdometer: 1011,
      odometerConfirmedAt: DateTime.utc(2026, 7, 14, 13, 1),
    );

    final doc =
        MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
          uid: 'firebaseUid-1',
          review: odometerReview,
        );

    expect(doc.data['estimatedEndingOdometer'], 1012);
    expect(doc.data['confirmedEndingOdometer'], 1011);
  });

  test('local upload policy allows odometer truth below GPS estimate', () {
    final odometerReview = TripTrackingReviewRecord(
      id: 'trip_upload_odometer_lower_than_gps',
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
      confirmedEndingOdometer: 1011,
      odometerConfirmedAt: DateTime.utc(2026, 7, 14, 13, 1),
    );
    final doc =
        MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
          uid: 'firebaseUid-1',
          review: odometerReview,
        );

    expect(
      () => MaintainiacFirestoreUploadPolicy.validateDraft(doc),
      returnsNormally,
    );
  });

  test('document builders reject unsafe mileage path identifiers', () {
    expect(
      () => MaintainiacFirestoreDocumentBuilder.tripTrackingReviewDocument(
        orgId: ' /// ',
        createdByUid: 'firebaseUid-1',
        review: review(),
      ),
      throwsArgumentError,
    );
    expect(
      () =>
          MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
            uid: 'firebaseUid-1',
            review: TripTrackingReviewRecord(
              id: ' /// ',
              vehicleId: 'vehicle_1',
              startingOdometer: 1000,
              estimatedEndingOdometer: 1013,
              profile: TripTrackingProfile.roadVehicle,
              startedAt: DateTime.utc(2026, 7, 14, 12),
              finishedAt: DateTime.utc(2026, 7, 14, 13),
              engineSnapshot: const TripTrackingEngineSnapshot(
                totalAcceptedMeters: 19312.128,
                walkingReviewSuggested: false,
              ),
              confirmedEndingOdometer: 1013,
              odometerConfirmedAt: DateTime.utc(2026, 7, 14, 13, 1),
            ),
          ),
      throwsArgumentError,
    );
  });

  test(
    'unsafe mileage backup identity stays pending without raw details',
    () async {
      final localStore = TripTrackingSessionStore.memory();
      final unsafeReview = TripTrackingReviewRecord(
        id: '///',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000,
        estimatedEndingOdometer: 1013,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 14, 12),
        finishedAt: DateTime.utc(2026, 7, 14, 13),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 19312.128,
          walkingReviewSuggested: false,
        ),
        confirmedEndingOdometer: 1013,
        odometerConfirmedAt: DateTime.utc(2026, 7, 14, 13, 1),
      );
      await localStore.saveReview(unsafeReview);
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

      await expectLater(mirror.queueReview(unsafeReview), throwsStateError);

      expect(queue.pendingRecords, isEmpty);
      final stored = localStore.reviewForTrip('///');
      expect(stored?.cloudSyncState, TripTrackingCloudSyncState.pending);
      expect(
        stored?.cloudSyncError,
        contains('valid trip and vehicle identity'),
      );
      expect(stored?.cloudSyncError, isNot(contains('///')));
    },
  );

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

  test('trip summary contract validates trust-boundary value shape', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
          uid: 'firebaseUid-1',
          review: review(),
        );

    expect(
      TripTrackingFirestoreContract.isReviewedSummaryShape(doc.data),
      isTrue,
    );
    expect(
      TripTrackingFirestoreContract.reviewedSummaryFindings(doc.data),
      isEmpty,
    );

    final unsafe = <String, Object?>{
      ...doc.data,
      'tripId': 'trip/../other',
      'createdByUid': 'firebaseUid-1',
      'updatedByUid': 'firebaseUid-2',
      'profile': 'silentTracker',
      'motionState': 'rawLocationStreaming',
      'locationDataIncluded': true,
      'acceptedMeters': double.nan,
      'acceptedSampleCount': 9,
      'receivedSampleCount': 1,
      'rawRoute': '35.1,-80.1',
    };

    final findings = TripTrackingFirestoreContract.reviewedSummaryFindings(
      unsafe,
    );

    expect(findings, contains('unknown_fields'));
    expect(findings, contains('not_mileage_only'));
    expect(findings, contains('unsafe_identity'));
    expect(findings, contains('owner_mismatch'));
    expect(findings, contains('invalid_profile'));
    expect(findings, contains('invalid_motion_state'));
    expect(findings, contains('invalid_distance'));
    expect(findings, contains('invalid_sample_counts'));
    expect(
      TripTrackingFirestoreContract.isReviewedSummaryShape(unsafe),
      isFalse,
    );
    expect(findings.toString(), isNot(contains('35.1')));
    expect(findings.toString(), isNot(contains('rawRoute')));
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
      for (final field in const <String>[
        'tripId',
        'createdByUid',
        'updatedByUid',
        'vehicleId',
        'startedAt',
        'finishedAt',
        'createdAt',
        'updatedAt',
        'odometerConfirmedAt',
      ]) {
        expect(valueCheck, contains('request.resource.data.$field.size() > 0'));
      }
      expect(valueCheck, contains('startingOdometer >= 0'));
      expect(valueCheck, contains('estimatedEndingOdometer >='));
      expect(
        valueCheck,
        contains(
          'confirmedEndingOdometer >=\n          request.resource.data.startingOdometer',
        ),
      );
      expect(
        valueCheck,
        isNot(
          contains(
            'confirmedEndingOdometer >=\n          request.resource.data.estimatedEndingOdometer',
          ),
        ),
      );
      expect(
        valueCheck,
        contains('finishedAt >= request.resource.data.startedAt'),
      );
      expect(valueCheck, contains('odometerConfirmedAt >='));
      expect(valueCheck, contains('acceptedMeters >= 0'));
      expect(valueCheck, contains('acceptedSampleCount <='));
      expect(valueCheck, contains('receivedSampleCount <= 999999'));
      expect(valueCheck, contains('acceptedSampleCount <= 999999'));
      for (final forbiddenRouteField in const [
        'mapboxRoute',
        'mapboxGeometry',
        'mapboxPolyline',
        'mapMatching',
        'optimizationRoute',
        'directionsRoute',
        'geometry',
        'waypoints',
        'navigationRoute',
        'directions',
        'matrix',
        'isochrone',
        'optimization',
        'mapMatchedTrace',
        'evChargeFinder',
        'chargingStations',
      ]) {
        expect(rules, contains("'$forbiddenRouteField'"));
      }
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
        'mapboxRoute': 'raw-mapbox-route-json',
        'mapboxGeometry': 'raw-mapbox-geometry',
        'mapboxPolyline': 'encoded_mapbox_polyline',
        'mapMatching': 'raw-map-match-json',
        'optimizationRoute': 'raw-optimization-json',
        'directionsRoute': 'raw-directions-json',
        'geometry': {'encoded': 'hidden-route'},
        'waypoints': const ['private-stop'],
        'navigationRoute': 'raw-navigation-route',
        'directions': {'legs': 1},
        'matrix': {
          'durations': const [0, 120],
        },
        'isochrone': {
          'contours': const [5, 10],
        },
        'optimization': 'raw-optimization-response',
        'mapMatchedTrace': 'raw-map-matched-trace',
        'evChargeFinder': 'raw-ev-charge-finder-response',
        'chargingStations': const ['station-near-stop'],
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
      {...doc.data, 'receivedSampleCount': 1000000},
      {
        ...doc.data,
        'receivedSampleCount': 1000000,
        'acceptedSampleCount': 1000000,
      },
      {...doc.data, 'vehicleId': ''},
      {...doc.data, 'createdAt': 'not-a-date'},
      {...doc.data, 'updatedAt': 'not-a-date'},
      {
        ...doc.data,
        'createdAt': DateTime.utc(2026, 7, 14, 14).toIso8601String(),
        'updatedAt': DateTime.utc(2026, 7, 14, 13).toIso8601String(),
      },
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

  test(
    'mileage backup permits reviewed odometer and GPS estimate differences',
    () {
      final discrepancy = TripTrackingReviewRecord(
        id: 'trip_reviewed_discrepancy',
        vehicleId: 'truck-1',
        startingOdometer: 1000,
        estimatedEndingOdometer: 1012,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 14, 12),
        finishedAt: DateTime.utc(2026, 7, 14, 13),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 19312.128,
          walkingReviewSuggested: false,
        ),
        confirmedEndingOdometer: 1010,
        odometerConfirmedAt: DateTime.utc(2026, 7, 14, 13, 1),
      );
      final doc =
          MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
            uid: 'firebaseUid-1',
            review: discrepancy,
          );

      MaintainiacFirestoreUploadPolicy.validateDraft(doc);
      expect(doc.data['estimatedEndingOdometer'], 1012);
      expect(doc.data['confirmedEndingOdometer'], 1010);
      expect(doc.data['locationDataIncluded'], isFalse);
    },
  );

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

  test('mileage backup builder rejects oversized path identities', () {
    expect(
      () =>
          MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
            uid: 'firebaseUid-1',
            review: review(id: 'trip_${'x' * 160}'),
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

  test('local upload policy rejects unsafe mileage identity fields', () {
    final doc = MaintainiacFirestoreDocumentBuilder.tripTrackingReviewDocument(
      orgId: 'orgA',
      createdByUid: 'firebaseUid-1',
      review: review(),
    );

    for (final badData in [
      {...doc.data, 'tripId': 'trip/1'},
      {...doc.data, 'tripId': ' trip_1 '},
      {...doc.data, 'vehicleId': 'truck 1'},
      {...doc.data, 'vehicleId': 'truck/1'},
      {...doc.data, 'createdByUid': 'firebase uid'},
      {...doc.data, 'updatedByUid': 'firebaseUid/1'},
      {...doc.data, 'createdByUid': 'firebaseUid-1 '},
      {...doc.data, 'updatedByUid': ' firebaseUid-1'},
    ]) {
      expect(
        () => MaintainiacFirestoreUploadPolicy.validateDraft(
          MaintainiacFirestoreDocumentDraft(path: doc.path, data: badData),
        ),
        throwsArgumentError,
      );
    }
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

  test('backup normalizes padded authenticated UIDs before binding', () async {
    final localStore = TripTrackingSessionStore.memory();
    await localStore.saveReview(review());
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
      createdByUid: ' firebaseUid-1 ',
    );

    await mirror.queueReview(review());

    expect(
      queue.pendingRecords.single.path,
      'users/firebaseUid-1/mileageRecords/trip_1',
    );
    final stored = localStore.reviewForTrip('trip 1');
    expect(stored?.cloudAccountUid, 'firebaseUid-1');
    expect(stored?.cloudBackupScope, TripTrackingCloudBackupScope.personal);
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
    'flush rejects unsafe legacy mileage identity without generic failure',
    () async {
      final legacyStore = TripTrackingSessionStore.memory();
      final unsafeReview = TripTrackingReviewRecord(
        id: '///',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000,
        estimatedEndingOdometer: 1013,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 14, 12),
        finishedAt: DateTime.utc(2026, 7, 14, 13),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 19312.128,
          walkingReviewSuggested: false,
        ),
        confirmedEndingOdometer: 1013,
        odometerConfirmedAt: DateTime.utc(2026, 7, 14, 13, 1),
        cloudSyncState: TripTrackingCloudSyncState.pending,
      );
      await legacyStore.saveReview(unsafeReview);
      final legacyQueue = await MaintainiacFirestoreUploadQueueStore.create();
      final legacySink = _RecordingSink();
      final legacyMirror = TripTrackingFirebaseMirror(
        queueStore: legacyQueue,
        uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
          queue: legacyQueue,
          sink: legacySink,
          uploadEnabled: true,
        ),
        localStore: legacyStore,
        personal: true,
        createdByUid: 'firebaseUid-1',
      );

      await legacyMirror.flushPending();

      expect(legacySink.writes, isEmpty);
      expect(legacyQueue.pendingRecords, isEmpty);
      final legacyStored = legacyStore.reviewForTrip('///');
      expect(legacyStored?.cloudSyncState, TripTrackingCloudSyncState.pending);
      expect(
        legacyStored?.cloudSyncError,
        contains('valid trip and vehicle identity'),
      );
      expect(legacyStored?.cloudSyncError, isNot(contains('///')));
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
    'a pre-scoped mileage review is bound to the current account before retry',
    () async {
      final localStore = TripTrackingSessionStore.memory();
      await localStore.saveReview(
        review().copyWith(
          cloudBackupScope: TripTrackingCloudBackupScope.personal,
          cloudSyncState: TripTrackingCloudSyncState.pending,
        ),
      );
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final mirror = TripTrackingFirebaseMirror(
        queueStore: queue,
        uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
          queue: queue,
          sink: _RecordingSink(),
          uploadEnabled: false,
        ),
        localStore: localStore,
        personal: true,
        createdByUid: 'firebaseUid-1',
      );

      await mirror.flushPending();

      final stored = localStore.reviewForTrip('trip 1');
      expect(stored?.cloudAccountUid, 'firebaseUid-1');
      expect(stored?.cloudBackupScope, TripTrackingCloudBackupScope.personal);
      expect(stored?.cloudSyncState, TripTrackingCloudSyncState.pending);
      expect(
        stored?.cloudSyncError,
        contains('Firestore uploads are disabled'),
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

  test(
    'Firebase mirror safe summary exposes consent boundaries only',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final mirror = TripTrackingFirebaseMirror(
        queueStore: queue,
        uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
          queue: queue,
          sink: _RecordingSink(),
          uploadEnabled: true,
        ),
        localStore: TripTrackingSessionStore.memory(),
        personal: false,
        orgId: 'orgA',
        createdByUid: 'firebaseUid-1',
        backupEnabled: () => true,
        organizationSharingEnabled: () => true,
      );
      final summary = mirror.toSafeSummary();

      expect(summary['backupEnabled'], isTrue);
      expect(summary['personalBackup'], isFalse);
      expect(summary['organizationSharingEnabled'], isTrue);
      expect(summary['hasSafeAuthenticatedAccount'], isTrue);
      expect(summary['hasUsableOrganizationId'], isTrue);
      expect(summary['queuesReviewedMileageOnly'], isTrue);
      expect(summary['requiresConfirmedOdometer'], isTrue);
      expect(summary['odometerIsGlobalTruth'], isTrue);
      expect(summary['confirmedOdometerRemainsCanonical'], isTrue);
      expect(summary['firebaseMirrorCanCreateCalibration'], isFalse);
      expect(summary['firebaseMirrorCanApplyCalibration'], isFalse);
      expect(summary['calibrationRequiresTrustedGpsWindow'], isTrue);
      expect(summary['poorGpsDaysExcludedFromCalibration'], isTrue);
      expect(summary['requiresAuthUidToMatchCreatedByUid'], isTrue);
      expect(summary['requiresLocalReviewBeforeFlush'], isTrue);
      expect(summary['requiresOrganizationConsentForOrgMirror'], isTrue);
      expect(summary['crossUserReplayBlocked'], isTrue);
      expect(summary['authenticationDoesNotImplyAuthorization'], isTrue);
      expect(summary['hiveRemainsSourceOfTruth'], isTrue);
      expect(summary['firestoreMirrorOnly'], isTrue);
      expect(summary['remoteDataCanOverrideLocalDaytimeData'], isFalse);
      expect(summary['remoteDataCanReviveDeletedLocalTrip'], isFalse);
      expect(summary['remoteDataCanModifyConfirmedMileage'], isFalse);
      expect(summary['withdrawalKeepsLocalReviews'], isTrue);
      expect(summary['withdrawalDeletesLocalTripData'], isFalse);
      expect(summary['rawGpsIncluded'], isFalse);
      expect(summary['routeGeometryIncluded'], isFalse);
      expect(summary['mapboxDataIncluded'], isFalse);
      expect(summary['tokensIncluded'], isFalse);
      expect(summary['uidIncluded'], isFalse);
      expect(summary.toString(), isNot(contains('firebaseUid-1')));
    },
  );

  test(
    'Firestore trust boundary requires owner, consent, and no raw location',
    () {
      final personal = TripTrackingFirestoreContract.trustBoundarySummary(
        organizationScoped: false,
      );
      final organization = TripTrackingFirestoreContract.trustBoundarySummary(
        organizationScoped: true,
      );

      expect(
        TripTrackingFirestoreContract.isTrustBoundaryClosed(personal),
        isTrue,
      );
      expect(
        TripTrackingFirestoreContract.isTrustBoundaryClosed(organization),
        isTrue,
      );
      expect(personal['rulesMustValidateCreatedByMatchesAuthUid'], isTrue);
      expect(personal['rulesMustRejectOwnerUidChanges'], isTrue);
      expect(personal['rulesMustRejectClientManagedServerFields'], isTrue);
      expect(personal['rulesMustRejectLocationArrays'], isTrue);
      expect(personal['rulesMustRejectCrossUserReplay'], isTrue);
      expect(personal['rulesMustRejectLiveOdometerProjectionWrites'], isTrue);
      expect(personal['rulesMustRejectClientStopWrites'], isTrue);
      expect(personal['rulesMustRejectMapboxOptimizationWrites'], isTrue);
      expect(personal['odometerIsGlobalTruth'], isTrue);
      expect(personal['rulesMustRejectRemoteCalibrationWrites'], isTrue);
      expect(personal['calibrationRequiresTrustedGpsWindow'], isTrue);
      expect(personal['poorGpsDaysExcludedFromCalibration'], isTrue);
      expect(personal['firestoreCanCreateCalibration'], isFalse);
      expect(personal['firestoreCanApplyCalibration'], isFalse);
      expect(organization['rulesMustRejectOrgWritesWithoutConsent'], isTrue);
      expect(
        organization['organizationWriteRequiresExplicitSharingConsent'],
        isTrue,
      );
    },
  );

  test(
    'Firestore trust boundary validation rejects owner and consent shortcuts',
    () {
      final findings = TripTrackingFirestoreContract.trustBoundaryFindings({
        ...TripTrackingFirestoreContract.trustBoundarySummary(
          organizationScoped: true,
        ),
        'rulesMustValidateCreatedByMatchesAuthUid': false,
        'rulesMustRejectOwnerUidChanges': false,
        'rulesMustRejectClientManagedServerFields': false,
        'rulesMustRejectLocationArrays': false,
        'rulesMustRejectCrossUserReplay': false,
        'rulesMustRejectLiveOdometerProjectionWrites': false,
        'rulesMustRejectClientStopWrites': false,
        'rulesMustRejectMapboxOptimizationWrites': false,
        'odometerIsGlobalTruth': false,
        'rulesMustRejectRemoteCalibrationWrites': false,
        'calibrationRequiresTrustedGpsWindow': false,
        'poorGpsDaysExcludedFromCalibration': false,
        'firestoreCanCreateCalibration': true,
        'firestoreCanApplyCalibration': true,
        'rulesMustRejectOrgWritesWithoutConsent': false,
        'organizationWriteRequiresExplicitSharingConsent': false,
      });

      expect(findings, contains('authorization_boundary_not_closed'));
      expect(findings, contains('organization_consent_boundary_open'));
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

  test(
    'unsafe legacy org scope cannot be saved as cloud-eligible mileage',
    () async {
      final localStore = TripTrackingSessionStore.memory();
      final legacyReview = review().copyWith(
        cloudAccountUid: 'firebaseUid-1',
        cloudBackupScope: TripTrackingCloudBackupScope.organization,
        cloudOrganizationId: ' /// ',
        cloudSyncState: TripTrackingCloudSyncState.queued,
      );

      await expectLater(
        localStore.saveReview(legacyReview),
        throwsArgumentError,
      );
      expect(localStore.reviewForTrip('trip 1'), isNull);
    },
  );

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
        sink: _RecordingSink(
          throwOnWrite: true,
          failureMessage:
              'token=sk.secret lat=35.123 lon=-80.456 near 35.12345,-80.45678',
        ),
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
    expect(
      localStore.reviewForTrip('trip 1')?.cloudSyncError,
      contains('saved locally'),
    );
    expect(
      localStore.reviewForTrip('trip 1')?.cloudSyncError,
      contains('retry'),
    );
    expect(
      localStore.reviewForTrip('trip 1')?.cloudSyncError,
      isNot(contains('sk.secret')),
    );
    expect(
      localStore.reviewForTrip('trip 1')?.cloudSyncError,
      isNot(contains('35.123')),
    );
    expect(
      localStore.reviewForTrip('trip 1')?.cloudSyncError,
      isNot(contains('-80.45678')),
    );
    expect(queue.pendingRecords.single.lastError, isNot(contains('sk.secret')));
    expect(queue.pendingRecords.single.lastError, isNot(contains('35.123')));
    expect(queue.pendingRecords.single.lastError, isNot(contains('-80.45678')));
    expect(queue.pendingRecords.single.lastError, contains('token redacted'));
    expect(
      queue.pendingRecords.single.lastError,
      contains('coordinates redacted'),
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

  test('manual trip backup requeue preserves queue backoff', () async {
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
    await queue.markAttempted(
      queue.pendingRecords.single,
      error: 'temporary outage near 35.12345,-80.45678',
      nowUtc: DateTime.utc(2026, 7, 14, 13, 5),
    );
    final attempted = queue.pendingRecords.single;

    await mirror.queueReview(review());

    final refreshed = queue.pendingRecords.single;
    expect(refreshed.attemptCount, attempted.attemptCount);
    expect(refreshed.nextAttemptAtUtc, attempted.nextAttemptAtUtc);
    expect(refreshed.lastError, contains('coordinates redacted'));
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

  test('disabled hosted trip backup remains pending for retry', () async {
    final localStore = TripTrackingSessionStore.memory();
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingSink();
    final mirror = TripTrackingFirebaseMirror(
      queueStore: queue,
      uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: sink,
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
      contains('Firestore uploads are disabled'),
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
  _RecordingSink({
    this.throwOnWrite = false,
    this.failureMessage = 'simulated Firestore outage',
  });

  final bool throwOnWrite;
  final String failureMessage;
  final writes = <Map<String, Object?>>[];
  final paths = <String>[];

  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) async {
    if (throwOnWrite) throw StateError(failureMessage);
    paths.add(path);
    writes.add(Map<String, Object?>.from(data));
  }
}
