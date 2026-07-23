import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  late MaintainiacDurableRecordStore records;
  late MaintainiacRestoreReviewStore reviews;
  late MaintainiacRestoreApplier applier;
  late MaintainiacRestoreReviewResolver resolver;

  setUp(() {
    records = MaintainiacDurableRecordStore.memory();
    reviews = MaintainiacRestoreReviewStore.memory();
    applier = MaintainiacRestoreApplier(
      store: records,
      reviewStore: reviews,
      migrations: MaintainiacRestoreMigrationRegistry(const []),
      accountScopeId: 'account-a',
      maximumSupportedSchemaVersion: 1,
    );
    resolver = MaintainiacRestoreReviewResolver(
      records: records,
      reviews: reviews,
    );
  });

  test('keeping local advances revision and closes repeat conflict', () async {
    await records.applyRestoredRecord(
      _record(2, 40),
      expectedLocalRevision: null,
    );
    await applier.apply(_envelope(_record(2, 99)));
    final issue = reviews.pendingFor('account-a').single;
    final resolved = await resolver.resolve(
      issueId: issue.id,
      resolution: MaintainiacRestoreResolution.keepLocal,
    );
    expect(resolved.state, MaintainiacRestoreReviewState.resolved);
    expect(records.recordFor('expenses', 'expense-1')?.payload['amount'], 40);
    expect(records.recordFor('expenses', 'expense-1')?.lifecycle.revision, 3);
    final retry = await applier.apply(_envelope(_record(2, 99)));
    expect(retry.disposition, MaintainiacRestoreDisposition.keepNewerLocal);
    expect(reviews.pendingFor('account-a'), isEmpty);
  });

  test(
    'applying remote is retry safe across review checkpoint failure',
    () async {
      await records.applyRestoredRecord(
        _record(2, 40),
        expectedLocalRevision: null,
      );
      await applier.apply(_envelope(_record(2, 99)));
      final issue = reviews.pendingFor('account-a').single;
      await records.applyRemoteAfterConflict(
        issue.remote.record,
        expectedLocalRevision: 2,
      );
      final resolved = await resolver.resolve(
        issueId: issue.id,
        resolution: MaintainiacRestoreResolution.applyRemote,
      );
      expect(resolved.resolution, MaintainiacRestoreResolution.applyRemote);
      expect(records.recordFor('expenses', 'expense-1')?.payload['amount'], 99);
      final retry = await resolver.resolve(
        issueId: issue.id,
        resolution: MaintainiacRestoreResolution.applyRemote,
      );
      expect(retry.revision, resolved.revision);
    },
  );

  test(
    'corrupt cloud evidence can never be selected as remote truth',
    () async {
      await applier.apply(
        MaintainiacRestoreEnvelope(
          accountScopeId: 'account-a',
          record: _record(1, 99),
          schemaVersion: 1,
          contentSha256: 'f' * 64,
        ),
      );
      final issue = reviews.pendingFor('account-a').single;
      await expectLater(
        resolver.resolve(
          issueId: issue.id,
          resolution: MaintainiacRestoreResolution.applyRemote,
        ),
        throwsStateError,
      );
      expect(reviews.pendingFor('account-a'), hasLength(1));
    },
  );

  test('concurrent identical resolutions are idempotent', () async {
    await records.applyRestoredRecord(
      _record(2, 40),
      expectedLocalRevision: null,
    );
    await applier.apply(_envelope(_record(2, 99)));
    final issue = reviews.pendingFor('account-a').single;

    final resolved = await Future.wait([
      resolver.resolve(
        issueId: issue.id,
        resolution: MaintainiacRestoreResolution.keepLocal,
      ),
      resolver.resolve(
        issueId: issue.id,
        resolution: MaintainiacRestoreResolution.keepLocal,
      ),
    ]);

    expect(resolved.first.revision, resolved.last.revision);
    expect(records.recordFor('expenses', 'expense-1')?.lifecycle.revision, 3);
  });
}

MaintainiacRestoreEnvelope _envelope(MaintainiacDurableRecord record) =>
    MaintainiacRestoreEnvelope.forRecord(
      accountScopeId: 'account-a',
      record: record,
      schemaVersion: 1,
    );

MaintainiacDurableRecord _record(int revision, int amount) =>
    MaintainiacDurableRecord(
      module: 'expenses',
      id: 'expense-1',
      payload: {'amount': amount},
      lifecycle: MaintainiacRecordLifecycle(
        createdAt: DateTime.utc(2026, 7, 22),
        updatedAt: DateTime.utc(2026, 7, 22, 0, revision),
        revision: revision,
      ),
    );
