import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  test('large restore records resume across byte-bounded pages', () async {
    final documents = [
      _document('settings-large-1'),
      _document('settings-large-2'),
    ];
    final transferBytes = documents.fold<int>(
      0,
      (total, document) =>
          total + utf8.encode(jsonEncode(document.data)).length,
    );
    final records = MaintainiacDurableRecordStore.memory();
    final sessions = MaintainiacRestoreSessionStore.memory(
      storageCheck: ({required operationBytes}) async => AppStorageCheck(
        availableBytes: 100 * 1024 * 1024,
        operationBytes: operationBytes,
        requiredBytes: operationBytes,
        purpose: AppStoragePurpose.restoreImport,
      ),
    );
    await sessions.prepare(
      id: 'restore-large',
      accountScopeId: 'org-a.user-a',
      deviceId: 'device-a',
      authorizationId: 'authorization-a',
      mode: MaintainiacRestoreMode.recordsOnly,
      storagePlan: MaintainiacRestoreStoragePlan(
        structuredBytes: transferBytes,
        thumbnailBytes: 0,
        proofBytes: 0,
        temporaryBytes: 0,
        availableBytes: 100 * 1024 * 1024,
      ),
      totalItems: documents.length,
    );
    await sessions.start('restore-large');
    final runner = MaintainiacCloudRestoreRunner(
      gateway: MaintainiacDurableCloudRestoreGateway(
        source: _Source(documents),
        identityProvider: const _Identity(),
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

    final first = await runner.processNextPage(
      organizationId: 'org-a',
      sessionId: 'restore-large',
      pageSize: 9,
    );
    final second = await runner.processNextPage(
      organizationId: 'org-a',
      sessionId: 'restore-large',
      pageSize: 9,
    );

    expect(first.completed, isFalse);
    expect(first.session.completedItems, 1);
    expect(second.completed, isTrue);
    expect(second.session.completedItems, 2);
    expect(records.recordsFor('settings'), hasLength(2));
  });
}

MaintainiacDurableCloudDocument _document(String id) {
  final draft = MaintainiacFirestoreDurableRecordCodec.encode(
    organizationId: 'org-a',
    uid: 'user-a',
    accountScopeId: 'org-a.user-a',
    schemaVersion: 1,
    record: MaintainiacDurableRecord(
      module: 'settings',
      id: id,
      payload: {'value': 'x' * (430 * 1024)},
      lifecycle: MaintainiacRecordLifecycle(
        createdAt: DateTime.utc(2026, 7, 23),
        updatedAt: DateTime.utc(2026, 7, 23),
      ),
    ),
  );
  return MaintainiacDurableCloudDocument(
    id: draft.path.split('/').last,
    data: draft.data,
  );
}

class _Source implements MaintainiacDurableCloudRecordSource {
  _Source(this.documents);

  final List<MaintainiacDurableCloudDocument> documents;

  @override
  Future<List<MaintainiacDurableCloudDocument>> fetchPage({
    required String organizationId,
    required String uid,
    required int limit,
    String? afterRecordKey,
  }) async {
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
  const _Identity();

  @override
  String get currentUid => 'user-a';
}
