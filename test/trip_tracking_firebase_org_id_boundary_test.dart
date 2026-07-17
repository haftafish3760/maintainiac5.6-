import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_firebase_bridge.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'trip_tracking_firebase_org_boundary_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('unsafe organization ids cannot queue company mileage backup', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final store = TripTrackingSessionStore.memory();
    final review = _review();
    await store.saveReview(review);
    final mirror = TripTrackingFirebaseMirror(
      queueStore: queue,
      uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: _NoopSink(),
        uploadEnabled: true,
      ),
      localStore: store,
      orgId: 'org/../other',
      authenticatedUid: () => 'firebaseUid-1',
      backupEnabled: () => true,
      organizationSharingEnabled: () => true,
    );
    addTearDown(mirror.dispose);

    await expectLater(mirror.queueReview(review), throwsStateError);

    expect(queue.pendingRecords, isEmpty);
    expect(store.reviewForTrip(review.id)?.cloudSyncState, TripTrackingCloudSyncState.pending);
    expect(store.reviewForTrip(review.id)?.cloudSyncError, contains('organization'));
  });
}

TripTrackingReviewRecord _review() {
  return TripTrackingReviewRecord(
    id: 'trip_1',
    vehicleId: 'vehicle_1',
    startingOdometer: 1000,
    estimatedEndingOdometer: 1010,
    confirmedEndingOdometer: 1010,
    odometerConfirmedAt: DateTime.utc(2026, 7, 17, 9, 5),
    profile: TripTrackingProfile.roadVehicle,
    startedAt: DateTime.utc(2026, 7, 17, 8),
    finishedAt: DateTime.utc(2026, 7, 17, 9),
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 16093.44,
      walkingReviewSuggested: false,
    ),
  );
}

class _NoopSink implements MaintainiacFirestoreDocumentSink {
  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) async {}
}
