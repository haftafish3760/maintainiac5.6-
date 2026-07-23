import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('batch_hash_test_');
    Hive.init(directory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  test('retry keeps its batch hash while replacement changes it', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final start = DateTime.utc(2026, 7, 22, 12);
    await queue.enqueue(_draft('first'), queuedAtUtc: start);
    final hashes = <String>[];
    final coordinator = MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: _FailingSink(),
      uploadEnabled: true,
      hostedSyncReservationProvider:
          (attemptId, batchSha256, batchBytes) async {
            expect(batchBytes, greaterThan(0));
            hashes.add(batchSha256);
            return _reservation();
          },
    );

    await coordinator.uploadPending(attemptId: 'attempt-1', nowUtc: start);
    await coordinator.uploadPending(
      attemptId: 'attempt-1',
      nowUtc: start.add(const Duration(seconds: 31)),
    );
    expect(hashes, hasLength(2));
    expect(hashes[1], hashes[0]);

    await queue.enqueueReplacingPendingForPath(
      _draft('replacement'),
      queuedAtUtc: start.add(const Duration(seconds: 32)),
    );
    await coordinator.uploadPending(
      attemptId: 'attempt-2',
      nowUtc: start.add(const Duration(seconds: 33)),
    );
    expect(hashes, hasLength(3));
    expect(hashes[2], isNot(hashes[0]));
  });
}

MaintainiacFirestoreDocumentDraft _draft(String value) =>
    MaintainiacFirestoreDocumentDraft(
      path: 'parserHealth/batch-fingerprint',
      data: {'schema': 'qa_safe_document_v1', 'event': value},
    );

MaintainiacHostedSyncReservation _reservation() =>
    MaintainiacHostedSyncReservation(
      id: 'reservation-1',
      used: 1,
      remaining: 3,
      limit: 4,
      window: const Duration(hours: 24),
      reservedAtUtc: DateTime.utc(2026, 7, 22),
    );

class _FailingSink implements MaintainiacFirestoreDocumentSink {
  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) => throw StateError('offline');
}
