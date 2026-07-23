import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  test(
    'review evidence survives restart and resolved recurrence reopens',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'maintainiac_restore_review_',
      );
      addTearDown(() async {
        await Hive.close();
        await directory.delete(recursive: true);
      });
      Hive.init(directory.path);
      var store = await MaintainiacRestoreReviewStore.create(
        storageCheck: _enoughSpace,
      );
      final remote = _reviewRecord(revision: 2, amount: 99);
      final local = _reviewRecord(revision: 2, amount: 40);
      final recorded = await store.record(
        type: MaintainiacRestoreReviewType.conflict,
        remote: remote,
        local: local,
        nowUtc: DateTime.utc(2026, 7, 22),
      );
      final resolved = await store.resolve(
        recorded.id,
        MaintainiacRestoreResolution.keepLocal,
        nowUtc: DateTime.utc(2026, 7, 22, 1),
      );
      expect(resolved.state, MaintainiacRestoreReviewState.resolved);
      expect(store.pendingFor('account-a'), isEmpty);

      await Hive.close();
      Hive.init(directory.path);
      store = await MaintainiacRestoreReviewStore.create(
        storageCheck: _enoughSpace,
      );
      final restored = store.issueById(recorded.id);
      expect(restored?.resolution, MaintainiacRestoreResolution.keepLocal);
      expect(restored?.revision, 2);

      final reopened = await store.record(
        type: MaintainiacRestoreReviewType.conflict,
        remote: remote,
        local: local,
        nowUtc: DateTime.utc(2026, 7, 22, 2),
      );
      expect(reopened.state, MaintainiacRestoreReviewState.pending);
      expect(reopened.resolution, isNull);
      expect(reopened.revision, 3);
      expect(store.pendingFor('account-a'), hasLength(1));
    },
  );

  test('foreign account review evidence is isolated', () async {
    final store = MaintainiacRestoreReviewStore.memory(
      storageCheck: _enoughSpace,
    );
    await store.record(
      type: MaintainiacRestoreReviewType.corrupt,
      remote: _reviewRecord(revision: 1, amount: 10),
    );
    expect(store.pendingFor('account-a'), hasLength(1));
    expect(store.pendingFor('account-b'), isEmpty);
    expect(store.issueById('not-a-hash'), isNull);
  });

  test('one corrupt review cannot hide valid recovery decisions', () async {
    final directory = await Directory.systemTemp.createTemp(
      'maintainiac_restore_review_corrupt_',
    );
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    Hive.init(directory.path);
    final store = await MaintainiacRestoreReviewStore.create(
      storageCheck: _enoughSpace,
    );
    final valid = await store.record(
      type: MaintainiacRestoreReviewType.corrupt,
      remote: _reviewRecord(revision: 1, amount: 10),
    );
    const corruptId =
        'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
    await Hive.box<dynamic>(
      MaintainiacRestoreReviewStore.boxName,
    ).put(corruptId, {'state': 'broken'});

    expect(store.pendingFor('account-a').single.id, valid.id);
    expect(store.issueById(corruptId), isNull);
    expect(store.corruptIssueIds, [corruptId]);
  });
}

MaintainiacRestoreReviewRecord _reviewRecord({
  required int revision,
  required int amount,
}) {
  final record = MaintainiacDurableRecord(
    module: 'expenses',
    id: 'expense-1',
    payload: {'amount': amount},
    lifecycle: MaintainiacRecordLifecycle(
      createdAt: DateTime.utc(2026, 7, 22),
      updatedAt: DateTime.utc(2026, 7, 22, 0, revision),
      revision: revision,
    ),
  );
  return MaintainiacRestoreReviewRecord(
    accountScopeId: 'account-a',
    record: record,
    schemaVersion: 1,
    contentSha256: MaintainiacRestoreApplier.contentSha256For(
      record,
      accountScopeId: 'account-a',
    ),
  );
}

Future<AppStorageCheck> _enoughSpace({required int operationBytes}) async =>
    AppStorageCheck(
      availableBytes: 1024 * 1024 * 1024,
      operationBytes: operationBytes,
      requiredBytes: operationBytes,
      purpose: AppStoragePurpose.restoreImport,
    );
