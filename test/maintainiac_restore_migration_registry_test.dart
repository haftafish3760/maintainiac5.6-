import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  test(
    'older cloud payload migrates deterministically before local apply',
    () async {
      final records = MaintainiacDurableRecordStore.memory();
      final reviews = MaintainiacRestoreReviewStore.memory();
      final applier = MaintainiacRestoreApplier(
        store: records,
        reviewStore: reviews,
        migrations: MaintainiacRestoreMigrationRegistry([
          MaintainiacRestoreMigrationStep(
            module: 'expenses',
            fromVersion: 1,
            migrate: (record) => MaintainiacDurableRecord(
              module: record.module,
              id: record.id,
              payload: {...record.payload, 'currency': 'USD'},
              lifecycle: record.lifecycle,
            ),
          ),
        ]),
        accountScopeId: 'account-a',
        maximumSupportedSchemaVersion: 2,
      );
      final result = await applier.apply(_envelope(schemaVersion: 1));
      expect(result.disposition, MaintainiacRestoreDisposition.applyRemote);
      expect(records.recordFor('expenses', 'expense-1')?.payload, {
        'amount': 25,
        'currency': 'USD',
      });
      expect(reviews.pendingFor('account-a'), isEmpty);
    },
  );

  test('missing migration blocks restore and records durable review', () async {
    final records = MaintainiacDurableRecordStore.memory();
    final reviews = MaintainiacRestoreReviewStore.memory();
    final applier = MaintainiacRestoreApplier(
      store: records,
      reviewStore: reviews,
      migrations: MaintainiacRestoreMigrationRegistry(const []),
      accountScopeId: 'account-a',
      maximumSupportedSchemaVersion: 2,
    );
    final result = await applier.apply(_envelope(schemaVersion: 1));
    expect(result.disposition, MaintainiacRestoreDisposition.rejectCorrupt);
    expect(records.recordFor('expenses', 'expense-1'), isNull);
    expect(
      reviews.pendingFor('account-a').single.type,
      MaintainiacRestoreReviewType.migrationRequired,
    );
  });

  test('migration cannot rewrite record identity or lifecycle', () async {
    final records = MaintainiacDurableRecordStore.memory();
    final reviews = MaintainiacRestoreReviewStore.memory();
    final applier = MaintainiacRestoreApplier(
      store: records,
      reviewStore: reviews,
      migrations: MaintainiacRestoreMigrationRegistry([
        MaintainiacRestoreMigrationStep(
          module: 'expenses',
          fromVersion: 1,
          migrate: (record) => MaintainiacDurableRecord(
            module: record.module,
            id: 'substituted-id',
            payload: record.payload,
            lifecycle: record.lifecycle,
          ),
        ),
      ]),
      accountScopeId: 'account-a',
      maximumSupportedSchemaVersion: 2,
    );
    final result = await applier.apply(_envelope(schemaVersion: 1));
    expect(result.disposition, MaintainiacRestoreDisposition.rejectCorrupt);
    expect(records.recordsFor('expenses'), isEmpty);
    expect(reviews.pendingFor('account-a'), hasLength(1));
  });

  test('duplicate migration steps are rejected at registration', () {
    MaintainiacRestoreMigrationStep step() => MaintainiacRestoreMigrationStep(
      module: 'expenses',
      fromVersion: 1,
      migrate: (record) => record,
    );
    expect(
      () => MaintainiacRestoreMigrationRegistry([step(), step()]),
      throwsArgumentError,
    );
  });

  test('migration modules must remain portable to the cloud record path', () {
    expect(
      () => MaintainiacRestoreMigrationRegistry([
        MaintainiacRestoreMigrationStep(
          module: 'm' * (MaintainiacDurableRecordStore.maximumModuleLength + 1),
          fromVersion: 1,
          migrate: (record) => record,
        ),
      ]),
      throwsArgumentError,
    );
  });
}

MaintainiacRestoreEnvelope _envelope({required int schemaVersion}) {
  final record = MaintainiacDurableRecord(
    module: 'expenses',
    id: 'expense-1',
    payload: const {'amount': 25},
    lifecycle: MaintainiacRecordLifecycle(
      createdAt: DateTime.utc(2026, 7, 22),
      updatedAt: DateTime.utc(2026, 7, 22),
    ),
  );
  return MaintainiacRestoreEnvelope.forRecord(
    accountScopeId: 'account-a',
    record: record,
    schemaVersion: schemaVersion,
  );
}
