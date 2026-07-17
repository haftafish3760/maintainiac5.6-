import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/dashboard/data/dashboard_firestore_mirror.dart';
import 'package:maintaniac/shared/firebase/hosted_usage_limits.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'dashboard_firestore_mirror_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test(
    'queues a reference-only dashboard summary for guarded upload',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final sink = _RecordingSink();
      final mirror = DashboardFirestoreMirror(
        queueStore: queue,
        uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
          queue: queue,
          sink: sink,
          uploadEnabled: true,
        ),
      );

      await mirror.queueSummary(
        uid: 'firebaseUid-1',
        dashboardId: 'today',
        updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
        activeVehicleId: 'truck 1',
        activeWorkdayId: 'workday 1',
        activeWorkProfileId: 'gig profile',
        dashboardMode: 'gig_driver',
        mileageMode: 'gps_assisted',
        syncMode: 'wifi_only',
        gpsAssistState: 'battery_limited',
        storageState: 'text_record_safe',
        freeSyncsRemaining: HostedUsageLimits.freeUserSyncsPer24HourWindow,
        syncsUsedInWindow: 0,
        batteryGpsLimited: true,
      );

      expect(queue.pendingRecords, hasLength(1));
      expect(
        queue.pendingRecords.single.path,
        contains('/dashboardSummaries/'),
      );
      expect(queue.pendingRecords.single.data['locationDataIncluded'], isFalse);
      expect(
        queue.pendingRecords.single.data['rawModuleDataIncluded'],
        isFalse,
      );
      expect(
        queue.pendingRecords.single.data.keys,
        isNot(contains('latitude')),
      );
      expect(queue.pendingRecords.single.data.keys, isNot(contains('route')));

      final result = await mirror.flushSummary(
        uid: 'firebaseUid-1',
        dashboardId: 'today',
        nowUtc: DateTime.utc(2026, 7, 16, 12, 1),
      );

      expect(result.status, MaintainiacFirestoreUploadStatus.uploaded);
      expect(sink.writes, hasLength(1));
      expect(sink.writes.single['rawModuleDataIncluded'], isFalse);
    },
  );

  test('replaces one pending dashboard summary for the same path', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final mirror = DashboardFirestoreMirror(
      queueStore: queue,
      uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: _RecordingSink(),
        uploadEnabled: true,
      ),
    );

    await mirror.queueSummary(
      uid: 'firebaseUid-1',
      dashboardId: 'today',
      updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
      gpsAssistState: 'off',
    );
    await mirror.queueSummary(
      uid: 'firebaseUid-1',
      dashboardId: 'today',
      updatedAtUtc: DateTime.utc(2026, 7, 16, 12, 5),
      gpsAssistState: 'on',
    );

    expect(queue.pendingRecords, hasLength(1));
    expect(queue.pendingRecords.single.data['gpsAssistState'], 'on');
  });

  test(
    'rejects unsafe dashboard summaries before they reach the queue',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final mirror = DashboardFirestoreMirror(
        queueStore: queue,
        uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
          queue: queue,
          sink: _RecordingSink(),
          uploadEnabled: true,
        ),
      );

      await expectLater(
        mirror.queueSummary(
          uid: 'firebaseUid-1',
          dashboardId: 'today',
          updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
          dashboardMode: 'god_mode',
        ),
        throwsArgumentError,
      );
      await expectLater(
        mirror.queueSummary(
          uid: 'firebaseUid-1',
          dashboardId: ' /// ',
          updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
        ),
        throwsArgumentError,
      );

      expect(queue.pendingRecords, isEmpty);
    },
  );

  test('rejects unsafe dashboard flush paths before upload', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingSink();
    final mirror = DashboardFirestoreMirror(
      queueStore: queue,
      uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: sink,
        uploadEnabled: true,
      ),
    );

    expect(
      () => mirror.flushSummary(uid: 'firebaseUid-1', dashboardId: ' /// '),
      throwsArgumentError,
    );
    expect(
      () => mirror.flushSummary(
        uid: 'firebaseUid-1',
        orgId: ' /// ',
        dashboardId: 'today',
      ),
      throwsArgumentError,
    );

    expect(sink.writes, isEmpty);
  });
}

class _RecordingSink implements MaintainiacFirestoreDocumentSink {
  final writes = <Map<String, Object?>>[];

  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) async {
    writes.add(data);
  }
}
