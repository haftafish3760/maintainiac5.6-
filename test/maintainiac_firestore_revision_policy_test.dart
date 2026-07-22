import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_revision_policy.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'firestore_revision_policy_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('revision policy writes newer records and no-ops exact retries', () {
    final existing = revisioned(3, total: 25);

    expect(
      MaintainiacFirestoreRevisionPolicy.decide(
        incoming: revisioned(4, total: 30),
        existing: existing,
      ).action,
      MaintainiacFirestoreRevisionAction.write,
    );
    expect(
      MaintainiacFirestoreRevisionPolicy.decide(
        incoming: Map<String, Object?>.from(existing),
        existing: existing,
      ).action,
      MaintainiacFirestoreRevisionAction.noOp,
    );
  });

  test('revision policy blocks stale and divergent same-revision writes', () {
    final existing = revisioned(3, total: 25);
    for (final incoming in [
      revisioned(2, total: 20),
      revisioned(3, total: 99),
    ]) {
      expect(
        MaintainiacFirestoreRevisionPolicy.decide(
          incoming: incoming,
          existing: existing,
        ).action,
        MaintainiacFirestoreRevisionAction.conflict,
      );
    }
  });

  test(
    'coordinator durably blocks a conflict instead of retrying it',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      const path = 'orgs/ORG-1/expenses/expense_1';
      await queue.enqueue(
        MaintainiacFirestoreDocumentDraft(path: path, data: revisioned(2)),
        queuedAtUtc: DateTime.utc(2026, 7, 22, 12),
      );
      final result = await MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: const _ConflictSink(),
        uploadEnabled: true,
      ).uploadPending(nowUtc: DateTime.utc(2026, 7, 22, 13));

      expect(result.status, MaintainiacFirestoreUploadStatus.conflict);
      expect(result.conflictedCount, 1);
      expect(queue.pendingRecords, isEmpty);
      expect(queue.records.single.requiresConflictReview, isTrue);
      expect(queue.nextBatch(nowUtc: DateTime.utc(2026, 7, 23)), isEmpty);
    },
  );
}

Map<String, Object?> revisioned(int revision, {int total = 25}) => {
  'schema': 'expense_receipt_backup_v1',
  'id': 'expense_1',
  'orgId': 'ORG-1',
  'createdByUid': 'USER-1',
  'updatedByUid': 'USER-1',
  'createdAt': '2026-07-22T12:00:00.000Z',
  'updatedAt': '2026-07-22T12:05:00.000Z',
  'deletedAt': null,
  'recordState': 'active',
  'localRevision': revision,
  'enteredTotalCents': total,
};

class _ConflictSink implements MaintainiacFirestoreDocumentSink {
  const _ConflictSink();

  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) => throw MaintainiacFirestoreRevisionConflict(
    path: path,
    localRevision: data['localRevision'] as int?,
    remoteRevision: 3,
  );
}
