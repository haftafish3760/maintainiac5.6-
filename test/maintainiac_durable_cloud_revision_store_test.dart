import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'durable_cloud_revision_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('cloud acknowledgment survives a local restart', () async {
    final store = await MaintainiacDurableCloudRevisionStore.create();
    final uploaded = _uploaded();
    await store.acknowledge([uploaded], nowUtc: DateTime.utc(2026, 7, 22, 1));
    await Hive.close();
    Hive.init(hiveDirectory.path);
    final reopened = await MaintainiacDurableCloudRevisionStore.create();

    expect(reopened.checkpointFor(uploaded.path)?.localRevision, 2);
    expect(reopened.isAcknowledged(_draft()), isTrue);
  });

  test('a different revision or hash is never treated as clean', () async {
    final store = MaintainiacDurableCloudRevisionStore.memory();
    await store.acknowledge([
      _uploaded(),
    ], nowUtc: DateTime.utc(2026, 7, 22, 1));
    final changed = MaintainiacFirestoreDocumentDraft(
      path: _draft().path,
      data: {..._draft().data, 'localRevision': 3},
    );

    expect(store.isAcknowledged(changed), isFalse);
  });

  test('corrupt checkpoint paths and account scopes fail closed', () {
    final valid = {
      'path': _draft().path,
      'accountScopeId': 'org-a.user-a',
      'localRevision': 2,
      'contentSha256': List.filled(64, 'b').join(),
      'acknowledgedAtUtc': DateTime.utc(2026, 7, 22).toIso8601String(),
    };

    expect(
      () => MaintainiacDurableCloudRevision.fromMap({
        ...valid,
        'path': 'orgs/org-a/records/not-a-record-hash',
      }),
      throwsFormatException,
    );
    expect(
      () => MaintainiacDurableCloudRevision.fromMap({
        ...valid,
        'accountScopeId': 'other-org.user-a',
      }),
      throwsFormatException,
    );
  });
}

MaintainiacFirestoreDocumentDraft _draft() => MaintainiacFirestoreDocumentDraft(
  path: 'orgs/org-a/records/${List.filled(64, 'a').join()}',
  data: {
    'schema': 'maintainiac_durable_record_v1',
    'accountScopeId': 'org-a.user-a',
    'localRevision': 2,
    'contentSha256': List.filled(64, 'b').join(),
  },
);

MaintainiacFirestoreQueuedDocument _uploaded() =>
    MaintainiacFirestoreQueuedDocument(
      id: 'queued-1',
      path: _draft().path,
      data: _draft().data,
      queuedAtUtc: DateTime.utc(2026, 7, 22),
    );
