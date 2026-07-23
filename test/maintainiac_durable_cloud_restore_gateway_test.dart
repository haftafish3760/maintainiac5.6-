import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  test(
    'restore derives tenant scope and returns a bounded cursor page',
    () async {
      final source = _Source([
        _document('settings', 'settings-2', revision: 1),
        _document('settings', 'settings-1', revision: 2),
        _document('settings', 'settings-3', revision: 1),
      ]);
      final gateway = MaintainiacDurableCloudRestoreGateway(
        source: source,
        identityProvider: const _Identity('user-a'),
      );

      final page = await gateway.fetchPage(
        organizationId: 'org-a',
        pageSize: 2,
      );

      expect(page.records, hasLength(2));
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, isNotNull);
      expect(
        page.records.every((item) => item.accountScopeId == 'org-a.user-a'),
        isTrue,
      );
      expect(source.requestedUid, 'user-a');
      expect(source.requestedLimit, 3);
    },
  );

  test('restore rejects another account record before local apply', () async {
    final foreign = _document('settings', 'settings-1', revision: 1);
    final source = _Source([
      MaintainiacDurableCloudDocument(
        id: foreign.id,
        data: {...foreign.data, 'createdByUid': 'user-b'},
      ),
    ]);
    final gateway = MaintainiacDurableCloudRestoreGateway(
      source: source,
      identityProvider: const _Identity('user-a'),
    );

    await expectLater(
      gateway.fetchPage(organizationId: 'org-a'),
      throwsFormatException,
    );
  });

  test('restore rejects duplicate and backward cursor identities', () async {
    final document = _document('settings', 'settings-1', revision: 1);
    final duplicates = MaintainiacDurableCloudRestoreGateway(
      source: _Source([document, document]),
      identityProvider: const _Identity('user-a'),
    );
    await expectLater(
      duplicates.fetchPage(organizationId: 'org-a'),
      throwsFormatException,
    );
    final backward = MaintainiacDurableCloudRestoreGateway(
      source: _Source([document]),
      identityProvider: const _Identity('user-a'),
    );
    await expectLater(
      backward.fetchPage(
        organizationId: 'org-a',
        afterRecordKey: List.filled(64, 'f').join(),
      ),
      throwsFormatException,
    );
  });

  test('restore requires authentication before querying cloud', () async {
    final source = _Source(const []);
    final gateway = MaintainiacDurableCloudRestoreGateway(
      source: source,
      identityProvider: const _Identity(null),
    );

    await expectLater(
      gateway.fetchPage(organizationId: 'org-a'),
      throwsStateError,
    );
    expect(source.requestedLimit, isNull);
  });

  test(
    'restore rejects a source that exceeds the requested page bound',
    () async {
      final gateway = MaintainiacDurableCloudRestoreGateway(
        source: _Source([
          _document('settings', 'settings-1', revision: 1),
          _document('settings', 'settings-2', revision: 1),
          _document('settings', 'settings-3', revision: 1),
        ]),
        identityProvider: const _Identity('user-a'),
      );

      await expectLater(
        gateway.fetchPage(organizationId: 'org-a', pageSize: 1),
        throwsFormatException,
      );
    },
  );

  test('restore pages stay within the local apply byte limit', () async {
    final largePayload = {'value': 'x' * (430 * 1024)};
    final gateway = MaintainiacDurableCloudRestoreGateway(
      source: _Source([
        _document(
          'settings',
          'settings-large-1',
          revision: 1,
          payload: largePayload,
        ),
        _document(
          'settings',
          'settings-large-2',
          revision: 1,
          payload: largePayload,
        ),
      ]),
      identityProvider: const _Identity('user-a'),
    );

    final page = await gateway.fetchPage(organizationId: 'org-a');

    expect(page.items, hasLength(1));
    expect(page.hasMore, isTrue);
    expect(page.nextCursor, page.items.single.recordKey);
    expect(
      page.items.single.transferBytes,
      lessThanOrEqualTo(MaintainiacRestoreBatchProcessor.maximumBatchBytes),
    );
  });
}

MaintainiacDurableCloudDocument _document(
  String module,
  String id, {
  required int revision,
  Map<String, Object?>? payload,
}) {
  final record = MaintainiacDurableRecord(
    module: module,
    id: id,
    payload: payload ?? {'value': revision},
    lifecycle: MaintainiacRecordLifecycle(
      createdAt: DateTime.utc(2026, 7, 22),
      updatedAt: DateTime.utc(2026, 7, 22, 0, revision),
      revision: revision,
    ),
  );
  final encoded = MaintainiacFirestoreDurableRecordCodec.encode(
    organizationId: 'org-a',
    uid: 'user-a',
    accountScopeId: 'org-a.user-a',
    schemaVersion: 1,
    record: record,
  );
  return MaintainiacDurableCloudDocument(
    id: encoded.path.split('/').last,
    data: encoded.data,
  );
}

class _Source implements MaintainiacDurableCloudRecordSource {
  _Source(this.documents);

  final List<MaintainiacDurableCloudDocument> documents;
  String? requestedUid;
  int? requestedLimit;

  @override
  Future<List<MaintainiacDurableCloudDocument>> fetchPage({
    required String organizationId,
    required String uid,
    required int limit,
    String? afterRecordKey,
  }) async {
    requestedUid = uid;
    requestedLimit = limit;
    return documents;
  }
}

class _Identity implements MaintainiacCloudIdentityProvider {
  const _Identity(this.currentUid);

  @override
  final String? currentUid;
}
