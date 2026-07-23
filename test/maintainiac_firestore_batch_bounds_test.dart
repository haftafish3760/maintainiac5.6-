import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'firestore_batch_bounds_test_',
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
    'queued upload batch is bounded by encoded bytes and record count',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final records = MaintainiacDurableRecordStore.memory();
      const padding = 720 * 1024;
      for (var index = 0; index < 3; index += 1) {
        final record = await records.save(
          module: 'settings',
          id: 'large-$index',
          payload: {'padding': String.fromCharCodes(List.filled(padding, 97))},
          now: DateTime.utc(2026, 7, 22, 0, index),
        );
        await queue.enqueue(
          MaintainiacFirestoreDurableRecordCodec.encode(
            organizationId: 'org-a',
            uid: 'user-a',
            accountScopeId: 'org-a.user-a',
            schemaVersion: 1,
            record: record,
          ),
          queuedAtUtc: DateTime.utc(2026, 7, 22, 1, index),
        );
      }

      final batch = queue.nextBatch(
        limit: 20,
        nowUtc: DateTime.utc(2026, 7, 22, 2),
      );

      expect(batch, hasLength(2));
      expect(
        batch.fold<int>(
          0,
          (sum, record) =>
              sum +
              utf8
                  .encode(
                    jsonEncode({'path': record.path, 'data': record.data}),
                  )
                  .length,
        ),
        lessThan(MaintainiacFirestoreUploadPolicy.maxBatchBytes),
      );
      expect(queue.pendingRecords, hasLength(3));
    },
  );
}
