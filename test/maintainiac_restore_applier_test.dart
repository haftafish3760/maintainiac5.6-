import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  test('content hash matches the server canonicalization vector', () {
    final time = DateTime.utc(2026, 7, 22);
    final record = MaintainiacDurableRecord(
      module: 'settings',
      id: 'record-1',
      payload: const {
        'title': 'HDWR',
        'ratio': 12.0,
        'nested': {'enabled': true},
        'count': 1,
      },
      lifecycle: MaintainiacRecordLifecycle(
        createdAt: time,
        updatedAt: time,
        auditEvents: const ['2026-07-22T00:00:00.000Z created record'],
      ),
    );

    expect(
      MaintainiacRestoreApplier.contentSha256For(
        record,
        accountScopeId: 'orgVector.userVector',
      ),
      '9e34025a498e8ef5c2c1f14d11ba90f16b8081df239c403e033552de7ab01426',
    );
  });

  late MaintainiacDurableRecordStore store;
  late MaintainiacRestoreReviewStore reviews;
  late MaintainiacRestoreApplier applier;

  setUp(() {
    store = MaintainiacDurableRecordStore.memory();
    reviews = MaintainiacRestoreReviewStore.memory();
    applier = MaintainiacRestoreApplier(
      store: store,
      reviewStore: reviews,
      migrations: MaintainiacRestoreMigrationRegistry(const []),
      accountScopeId: 'account-a',
      maximumSupportedSchemaVersion: 2,
    );
  });

  test('newer cloud record applies and exact retry is idempotent', () async {
    final remote = _record(revision: 2, amount: 25);
    final envelope = MaintainiacRestoreEnvelope.forRecord(
      accountScopeId: 'account-a',
      record: remote,
      schemaVersion: 2,
    );
    final first = await applier.apply(envelope);
    final retry = await applier.apply(envelope);
    expect(first.disposition, MaintainiacRestoreDisposition.applyRemote);
    expect(retry.disposition, MaintainiacRestoreDisposition.alreadyCurrent);
    expect(store.recordFor('expenses', 'expense-1')?.payload['amount'], 25);
    expect(store.recordFor('expenses', 'expense-1')?.lifecycle.revision, 2);
  });

  test(
    'newer local and divergent equal revisions are never overwritten',
    () async {
      await store.applyRestoredRecord(
        _record(revision: 4, amount: 40),
        expectedLocalRevision: null,
      );
      final older = await applier.apply(
        MaintainiacRestoreEnvelope.forRecord(
          accountScopeId: 'account-a',
          record: _record(revision: 3, amount: 30),
          schemaVersion: 2,
        ),
      );
      final divergent = await applier.apply(
        MaintainiacRestoreEnvelope.forRecord(
          accountScopeId: 'account-a',
          record: _record(revision: 4, amount: 99),
          schemaVersion: 2,
        ),
      );
      expect(older.disposition, MaintainiacRestoreDisposition.keepNewerLocal);
      expect(divergent.disposition, MaintainiacRestoreDisposition.conflict);
      expect(store.recordFor('expenses', 'expense-1')?.payload['amount'], 40);
      final pending = reviews.pendingFor('account-a');
      expect(pending, hasLength(1));
      expect(pending.single.type, MaintainiacRestoreReviewType.conflict);
      expect(pending.single.local?.record.payload['amount'], 40);
      expect(pending.single.remote.record.payload['amount'], 99);
    },
  );

  test(
    'bad hash and unsupported schema are rejected without a write',
    () async {
      final record = _record(revision: 1, amount: 10);
      final badHash = await applier.apply(
        MaintainiacRestoreEnvelope(
          accountScopeId: 'account-a',
          record: record,
          schemaVersion: 2,
          contentSha256: 'a' * 64,
        ),
      );
      final unsupported = await applier.apply(
        MaintainiacRestoreEnvelope.forRecord(
          accountScopeId: 'account-a',
          record: record,
          schemaVersion: 3,
        ),
      );
      expect(badHash.disposition, MaintainiacRestoreDisposition.rejectCorrupt);
      expect(
        unsupported.disposition,
        MaintainiacRestoreDisposition.rejectCorrupt,
      );
      expect(store.recordFor('expenses', 'expense-1'), isNull);
      expect(reviews.pendingFor('account-a'), hasLength(2));
      expect(
        reviews.pendingFor('account-a').map((issue) => issue.type).toSet(),
        {MaintainiacRestoreReviewType.corrupt},
      );
    },
  );

  test('canonical hash is stable across payload map insertion order', () {
    final left = _record(revision: 1, amount: 10, reversed: false);
    final right = _record(revision: 1, amount: 10, reversed: true);
    expect(
      MaintainiacRestoreApplier.contentSha256For(
        left,
        accountScopeId: 'account-a',
      ),
      MaintainiacRestoreApplier.contentSha256For(
        right,
        accountScopeId: 'account-a',
      ),
    );
  });

  test('atomic restore write rejects a local revision race', () async {
    await store.applyRestoredRecord(
      _record(revision: 1, amount: 10),
      expectedLocalRevision: null,
    );
    await expectLater(
      store.applyRestoredRecord(
        _record(revision: 2, amount: 20),
        expectedLocalRevision: null,
      ),
      throwsStateError,
    );
    expect(store.recordFor('expenses', 'expense-1')?.payload['amount'], 10);
  });
}

MaintainiacDurableRecord _record({
  required int revision,
  required int amount,
  bool reversed = false,
}) {
  final payload = reversed
      ? <String, dynamic>{'note': 'local-first', 'amount': amount}
      : <String, dynamic>{'amount': amount, 'note': 'local-first'};
  return MaintainiacDurableRecord(
    module: 'expenses',
    id: 'expense-1',
    payload: payload,
    lifecycle: MaintainiacRecordLifecycle(
      createdAt: DateTime.utc(2026, 7, 20),
      updatedAt: DateTime.utc(2026, 7, 20, 0, revision),
      revision: revision,
      auditEvents: const ['created'],
    ),
  );
}
