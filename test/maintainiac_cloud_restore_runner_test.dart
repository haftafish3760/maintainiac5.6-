import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  const mb = 1024 * 1024;

  test(
    'paginated restore resumes by cursor and completes exactly once',
    () async {
      const identity = _Identity('user-a');
      final source = _PagedSource([
        _document('settings', 'settings-1'),
        _document('profiles', 'profile-1'),
      ]);
      final gateway = MaintainiacDurableCloudRestoreGateway(
        source: source,
        identityProvider: identity,
      );
      final planPage = await gateway.fetchPage(
        organizationId: 'org-a',
        pageSize: 9,
      );
      final transferBytes = planPage.items.fold<int>(
        0,
        (total, item) => total + item.transferBytes,
      );
      final records = MaintainiacDurableRecordStore.memory();
      final sessions = MaintainiacRestoreSessionStore.memory(
        storageCheck: ({required operationBytes}) async => AppStorageCheck(
          availableBytes: 500 * mb,
          operationBytes: operationBytes,
          requiredBytes: operationBytes,
          purpose: AppStoragePurpose.restoreImport,
        ),
      );
      await sessions.prepare(
        id: 'restore-1',
        accountScopeId: 'org-a.user-a',
        deviceId: 'device-a',
        authorizationId: 'authorization-a',
        mode: MaintainiacRestoreMode.recordsOnly,
        storagePlan: MaintainiacRestoreStoragePlan(
          structuredBytes: transferBytes,
          thumbnailBytes: 0,
          proofBytes: 0,
          temporaryBytes: 0,
          availableBytes: 500 * mb,
        ),
        totalItems: 2,
      );
      await sessions.start('restore-1');
      final runner = MaintainiacCloudRestoreRunner(
        gateway: gateway,
        sessions: sessions,
        batches: MaintainiacRestoreBatchProcessor(
          sessions: sessions,
          applier: MaintainiacRestoreApplier(
            store: records,
            reviewStore: MaintainiacRestoreReviewStore.memory(),
            migrations: MaintainiacRestoreMigrationRegistry(const []),
            accountScopeId: 'org-a.user-a',
            maximumSupportedSchemaVersion: 1,
          ),
        ),
      );

      final first = await runner.processNextPage(
        organizationId: 'org-a',
        sessionId: 'restore-1',
        pageSize: 1,
      );
      final second = await runner.processNextPage(
        organizationId: 'org-a',
        sessionId: 'restore-1',
        pageSize: 1,
      );

      expect(first.completed, isFalse);
      expect(first.session.completedItems, 1);
      expect(second.completed, isTrue);
      expect(second.session.state, MaintainiacRestoreSessionState.completed);
      expect(records.recordsFor('settings'), hasLength(1));
      expect(records.recordsFor('profiles'), hasLength(1));
    },
  );

  test(
    'an unexpectedly empty cloud page fails without false completion',
    () async {
      final sessions = MaintainiacRestoreSessionStore.memory(
        storageCheck: ({required operationBytes}) async => AppStorageCheck(
          availableBytes: 500 * mb,
          operationBytes: operationBytes,
          requiredBytes: operationBytes,
          purpose: AppStoragePurpose.restoreImport,
        ),
      );
      await sessions.prepare(
        id: 'restore-1',
        accountScopeId: 'org-a.user-a',
        deviceId: 'device-a',
        authorizationId: 'authorization-a',
        mode: MaintainiacRestoreMode.recordsOnly,
        storagePlan: const MaintainiacRestoreStoragePlan(
          structuredBytes: 100,
          thumbnailBytes: 0,
          proofBytes: 0,
          temporaryBytes: 0,
          availableBytes: 500 * mb,
        ),
        totalItems: 1,
      );
      await sessions.start('restore-1');
      final records = MaintainiacDurableRecordStore.memory();
      final runner = MaintainiacCloudRestoreRunner(
        gateway: MaintainiacDurableCloudRestoreGateway(
          source: _PagedSource(const []),
          identityProvider: const _Identity('user-a'),
        ),
        sessions: sessions,
        batches: MaintainiacRestoreBatchProcessor(
          sessions: sessions,
          applier: MaintainiacRestoreApplier(
            store: records,
            reviewStore: MaintainiacRestoreReviewStore.memory(),
            migrations: MaintainiacRestoreMigrationRegistry(const []),
            accountScopeId: 'org-a.user-a',
            maximumSupportedSchemaVersion: 1,
          ),
        ),
      );

      final result = await runner.processNextPage(
        organizationId: 'org-a',
        sessionId: 'restore-1',
      );

      expect(result.completed, isFalse);
      expect(result.session.state, MaintainiacRestoreSessionState.failed);
      expect(result.session.completedItems, 0);
      expect(records.recordsFor('settings'), isEmpty);
    },
  );

  test('an authorized empty restore completes without a cloud page', () async {
    final sessions = MaintainiacRestoreSessionStore.memory(
      storageCheck: ({required operationBytes}) async => AppStorageCheck(
        availableBytes: 500 * mb,
        operationBytes: operationBytes,
        requiredBytes: operationBytes,
        purpose: AppStoragePurpose.restoreImport,
      ),
    );
    await sessions.prepare(
      id: 'restore-empty',
      accountScopeId: 'org-a.user-a',
      deviceId: 'device-a',
      authorizationId: 'authorization-a',
      mode: MaintainiacRestoreMode.recordsOnly,
      storagePlan: const MaintainiacRestoreStoragePlan(
        structuredBytes: 0,
        thumbnailBytes: 0,
        proofBytes: 0,
        temporaryBytes: 0,
        availableBytes: 500 * mb,
      ),
      totalItems: 0,
    );
    await sessions.start('restore-empty');
    final source = _PagedSource(const []);
    final runner = MaintainiacCloudRestoreRunner(
      gateway: MaintainiacDurableCloudRestoreGateway(
        source: source,
        identityProvider: const _Identity('user-a'),
      ),
      sessions: sessions,
      batches: MaintainiacRestoreBatchProcessor(
        sessions: sessions,
        applier: MaintainiacRestoreApplier(
          store: MaintainiacDurableRecordStore.memory(),
          reviewStore: MaintainiacRestoreReviewStore.memory(),
          migrations: MaintainiacRestoreMigrationRegistry(const []),
          accountScopeId: 'org-a.user-a',
          maximumSupportedSchemaVersion: 1,
        ),
      ),
    );
    final result = await runner.processNextPage(
      organizationId: 'org-a',
      sessionId: 'restore-empty',
    );
    expect(result.completed, isTrue);
    expect(result.session.state, MaintainiacRestoreSessionState.completed);
    expect(source.calls, 0);
  });

  test(
    'concurrent page requests download and apply a final page once',
    () async {
      final document = _document('settings', 'settings-1');
      final source = _PagedSource([document]);
      final gateway = MaintainiacDurableCloudRestoreGateway(
        source: source,
        identityProvider: const _Identity('user-a'),
      );
      final page = await gateway.fetchPage(
        organizationId: 'org-a',
        pageSize: 1,
      );
      final sessions = MaintainiacRestoreSessionStore.memory(
        storageCheck: ({required operationBytes}) async => AppStorageCheck(
          availableBytes: 500 * mb,
          operationBytes: operationBytes,
          requiredBytes: operationBytes,
          purpose: AppStoragePurpose.restoreImport,
        ),
      );
      await sessions.prepare(
        id: 'restore-concurrent',
        accountScopeId: 'org-a.user-a',
        deviceId: 'device-a',
        authorizationId: 'authorization-a',
        mode: MaintainiacRestoreMode.recordsOnly,
        storagePlan: MaintainiacRestoreStoragePlan(
          structuredBytes: page.items.single.transferBytes,
          thumbnailBytes: 0,
          proofBytes: 0,
          temporaryBytes: 0,
          availableBytes: 500 * mb,
        ),
        totalItems: 1,
      );
      await sessions.start('restore-concurrent');
      final records = MaintainiacDurableRecordStore.memory();
      final runner = MaintainiacCloudRestoreRunner(
        gateway: gateway,
        sessions: sessions,
        batches: MaintainiacRestoreBatchProcessor(
          sessions: sessions,
          applier: MaintainiacRestoreApplier(
            store: records,
            reviewStore: MaintainiacRestoreReviewStore.memory(),
            migrations: MaintainiacRestoreMigrationRegistry(const []),
            accountScopeId: 'org-a.user-a',
            maximumSupportedSchemaVersion: 1,
          ),
        ),
      );
      final planReadCalls = source.calls;

      final results = await Future.wait([
        runner.processNextPage(
          organizationId: 'org-a',
          sessionId: 'restore-concurrent',
        ),
        runner.processNextPage(
          organizationId: 'org-a',
          sessionId: 'restore-concurrent',
        ),
      ]);

      expect(source.calls - planReadCalls, 1);
      expect(results.every((result) => result.completed), isTrue);
      expect(records.recordsFor('settings'), hasLength(1));
    },
  );

  test(
    'hosted completion can retry after local records are committed',
    () async {
      const identity = _Identity('user-a');
      final source = _PagedSource([_document('settings', 'settings-1')]);
      final gateway = MaintainiacDurableCloudRestoreGateway(
        source: source,
        identityProvider: identity,
      );
      final plan = await gateway.fetchPage(
        organizationId: 'org-a',
        pageSize: 1,
      );
      final transferBytes = plan.items.single.transferBytes;
      final sessions = MaintainiacRestoreSessionStore.memory(
        storageCheck: ({required operationBytes}) async => AppStorageCheck(
          availableBytes: 500 * mb,
          operationBytes: operationBytes,
          requiredBytes: operationBytes,
          purpose: AppStoragePurpose.restoreImport,
        ),
      );
      await sessions.prepare(
        id: 'restore-1',
        accountScopeId: 'org-a.user-a',
        deviceId: 'device-a',
        authorizationId: 'authorization-a',
        mode: MaintainiacRestoreMode.recordsOnly,
        storagePlan: MaintainiacRestoreStoragePlan(
          structuredBytes: transferBytes,
          thumbnailBytes: 0,
          proofBytes: 0,
          temporaryBytes: 0,
          availableBytes: 500 * mb,
        ),
        totalItems: 1,
      );
      await sessions.start('restore-1');
      final records = MaintainiacDurableRecordStore.memory();
      final progress = _RetryProgressSink(failOnCall: 2);
      final runner = MaintainiacCloudRestoreRunner(
        gateway: gateway,
        sessions: sessions,
        progressSink: progress,
        batches: MaintainiacRestoreBatchProcessor(
          sessions: sessions,
          applier: MaintainiacRestoreApplier(
            store: records,
            reviewStore: MaintainiacRestoreReviewStore.memory(),
            migrations: MaintainiacRestoreMigrationRegistry(const []),
            accountScopeId: 'org-a.user-a',
            maximumSupportedSchemaVersion: 1,
          ),
        ),
      );

      await expectLater(
        runner.processNextPage(
          organizationId: 'org-a',
          sessionId: 'restore-1',
          pageSize: 1,
        ),
        throwsStateError,
      );
      expect(
        sessions.sessionById('restore-1')?.state,
        MaintainiacRestoreSessionState.completed,
      );
      expect(records.recordsFor('settings'), hasLength(1));

      final retried = await runner.processNextPage(
        organizationId: 'org-a',
        sessionId: 'restore-1',
        pageSize: 1,
      );
      expect(retried.completed, isTrue);
      expect(progress.calls, 3);
      expect(records.recordsFor('settings'), hasLength(1));
    },
  );
}

MaintainiacDurableCloudDocument _document(String module, String id) {
  final encoded = MaintainiacFirestoreDurableRecordCodec.encode(
    organizationId: 'org-a',
    uid: 'user-a',
    accountScopeId: 'org-a.user-a',
    schemaVersion: 1,
    record: MaintainiacDurableRecord(
      module: module,
      id: id,
      payload: const {'value': 1},
      lifecycle: MaintainiacRecordLifecycle(
        createdAt: DateTime.utc(2026, 7, 22),
        updatedAt: DateTime.utc(2026, 7, 22),
      ),
    ),
  );
  return MaintainiacDurableCloudDocument(
    id: encoded.path.split('/').last,
    data: encoded.data,
  );
}

class _PagedSource implements MaintainiacDurableCloudRecordSource {
  _PagedSource(this.documents);

  final List<MaintainiacDurableCloudDocument> documents;
  int calls = 0;

  @override
  Future<List<MaintainiacDurableCloudDocument>> fetchPage({
    required String organizationId,
    required String uid,
    required int limit,
    String? afterRecordKey,
  }) async {
    calls += 1;
    final sorted = [...documents]..sort((a, b) => a.id.compareTo(b.id));
    return sorted
        .where(
          (document) =>
              afterRecordKey == null ||
              document.id.compareTo(afterRecordKey) > 0,
        )
        .take(limit)
        .toList(growable: false);
  }
}

class _Identity implements MaintainiacCloudIdentityProvider {
  const _Identity(this.currentUid);

  @override
  final String? currentUid;
}

class _RetryProgressSink implements MaintainiacRestoreProgressSink {
  _RetryProgressSink({required this.failOnCall});

  final int failOnCall;
  int calls = 0;

  @override
  Future<void> reconcile(MaintainiacRestoreSession session) async {
    calls += 1;
    if (calls == failOnCall) throw StateError('simulated hosted outage');
  }
}
