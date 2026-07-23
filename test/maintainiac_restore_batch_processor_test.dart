import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  const mb = 1024 * 1024;
  late MaintainiacDurableRecordStore records;
  late MaintainiacRestoreSessionStore sessions;
  late MaintainiacRestoreBatchProcessor processor;

  setUp(() async {
    records = MaintainiacDurableRecordStore.memory();
    sessions = MaintainiacRestoreSessionStore.memory(
      storageCheck: ({required operationBytes}) async => AppStorageCheck(
        availableBytes: 500 * mb,
        operationBytes: operationBytes,
        requiredBytes: operationBytes,
        purpose: AppStoragePurpose.restoreImport,
      ),
    );
    await sessions.prepare(
      id: 'restore-1',
      accountScopeId: 'account-a',
      deviceId: 'device-a',
      authorizationId: 'authorization-a',
      mode: MaintainiacRestoreMode.recordsOnly,
      storagePlan: const MaintainiacRestoreStoragePlan(
        structuredBytes: 200,
        thumbnailBytes: 0,
        proofBytes: 0,
        temporaryBytes: 0,
        availableBytes: 500 * mb,
      ),
      totalItems: 2,
    );
    await sessions.start('restore-1');
    processor = MaintainiacRestoreBatchProcessor(
      sessions: sessions,
      applier: MaintainiacRestoreApplier(
        store: records,
        reviewStore: MaintainiacRestoreReviewStore.memory(),
        migrations: MaintainiacRestoreMigrationRegistry(const []),
        accountScopeId: 'account-a',
        maximumSupportedSchemaVersion: 1,
      ),
    );
  });

  test(
    'page progress advances only after every record is classified',
    () async {
      final session = sessions.sessionById('restore-1')!;
      final result = await processor.process(
        sessionId: session.id,
        expectedSessionRevision: session.revision,
        nextCursor: 'a' * 64,
        items: [_item('one', 1, 100), _item('two', 1, 100)],
      );
      expect(result.status, MaintainiacRestoreBatchStatus.applied);
      expect(result.session.completedItems, 2);
      expect(result.session.completedBytes, 200);
      expect(records.recordsFor('expenses'), hasLength(2));
      expect(
        (await sessions.complete('restore-1')).state,
        MaintainiacRestoreSessionState.completed,
      );
    },
  );

  test('cross-account page is rejected before any record write', () async {
    final session = sessions.sessionById('restore-1')!;
    await expectLater(
      processor.process(
        sessionId: session.id,
        expectedSessionRevision: session.revision,
        nextCursor: 'a' * 64,
        items: [_item('one', 1, 100, accountScopeId: 'account-b')],
      ),
      throwsStateError,
    );
    expect(records.recordsFor('expenses'), isEmpty);
    expect(sessions.sessionById('restore-1')?.completedItems, 0);
  });

  test('corrupt page fails resumably without advancing its cursor', () async {
    final session = sessions.sessionById('restore-1')!;
    final corrupt = MaintainiacRestoreBatchItem(
      envelope: MaintainiacRestoreEnvelope(
        accountScopeId: 'account-a',
        record: _record('two', 1),
        schemaVersion: 1,
        contentSha256: 'f' * 64,
      ),
      transferBytes: 100,
    );
    final result = await processor.process(
      sessionId: session.id,
      expectedSessionRevision: session.revision,
      nextCursor: 'a' * 64,
      items: [_item('one', 1, 100), corrupt],
    );
    expect(result.status, MaintainiacRestoreBatchStatus.blocked);
    expect(result.session.state, MaintainiacRestoreSessionState.failed);
    expect(result.session.completedItems, 0);
    expect(result.session.cursor, isNull);
    expect(records.recordFor('expenses', 'one'), isNotNull);
  });

  test(
    'duplicate records and malformed cursors fail before any write',
    () async {
      final session = sessions.sessionById('restore-1')!;
      for (final input
          in <({String cursor, List<MaintainiacRestoreBatchItem> items})>[
            (cursor: 'bad-cursor', items: [_item('one', 1, 100)]),
            (
              cursor: 'a' * 64,
              items: [_item('one', 1, 100), _item('one', 1, 100)],
            ),
          ]) {
        await expectLater(
          processor.process(
            sessionId: session.id,
            expectedSessionRevision: session.revision,
            nextCursor: input.cursor,
            items: input.items,
          ),
          throwsStateError,
        );
      }

      expect(records.recordsFor('expenses'), isEmpty);
      expect(sessions.sessionById('restore-1')?.completedItems, 0);
    },
  );

  test('oversized restore pages fail before any record write', () async {
    final session = sessions.sessionById('restore-1')!;

    await expectLater(
      processor.process(
        sessionId: session.id,
        expectedSessionRevision: session.revision,
        nextCursor: 'a' * 64,
        items: [
          _item(
            'one',
            1,
            MaintainiacRestoreBatchProcessor.maximumBatchBytes + 1,
          ),
        ],
      ),
      throwsStateError,
    );

    expect(records.recordsFor('expenses'), isEmpty);
  });
}

MaintainiacRestoreBatchItem _item(
  String id,
  int revision,
  int bytes, {
  String accountScopeId = 'account-a',
}) => MaintainiacRestoreBatchItem(
  envelope: MaintainiacRestoreEnvelope.forRecord(
    accountScopeId: accountScopeId,
    record: _record(id, revision),
    schemaVersion: 1,
  ),
  transferBytes: bytes,
);

MaintainiacDurableRecord _record(String id, int revision) =>
    MaintainiacDurableRecord(
      module: 'expenses',
      id: id,
      payload: {'amount': revision * 10},
      lifecycle: MaintainiacRecordLifecycle(
        createdAt: DateTime.utc(2026, 7, 22),
        updatedAt: DateTime.utc(2026, 7, 22, 0, revision),
        revision: revision,
      ),
    );
