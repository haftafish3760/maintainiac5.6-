import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  test('client and callable durable-write limits remain aligned', () {
    final source = File(
      'functions/durable_record_commit.js',
    ).readAsStringSync();

    expect(
      source,
      contains(
        'const MAX_DOCUMENTS = '
        '${MaintainiacFirestoreUploadPolicy.maxBatchSize};',
      ),
    );
    expect(
      source,
      contains(
        'const MAX_DOCUMENT_BYTES = '
        '${MaintainiacFirestoreUploadPolicy.maxDocumentBytes ~/ 1024} * 1024;',
      ),
    );
    expect(
      source,
      contains(
        'const MAX_BATCH_BYTES = '
        '${MaintainiacFirestoreUploadPolicy.maxBatchBytes ~/ (1024 * 1024)} '
        '* 1024 * 1024;',
      ),
    );
  });

  test('every accepted cloud record fits restore paging boundaries', () {
    final source = File('functions/restore_snapshot.js').readAsStringSync();
    final match = RegExp(
      r'const MAX_CHUNK_BYTES = ([0-9]+) \* 1024;',
    ).firstMatch(source);

    expect(match, isNotNull);
    final snapshotChunkBytes = int.parse(match!.group(1)!) * 1024;
    expect(
      MaintainiacRestoreBatchProcessor.maximumBatchBytes,
      MaintainiacFirestoreUploadPolicy.maxDocumentBytes,
    );
    expect(
      snapshotChunkBytes,
      greaterThan(MaintainiacFirestoreUploadPolicy.maxDocumentBytes),
    );
    expect(snapshotChunkBytes, lessThan(1024 * 1024));
  });

  test('client batch hashing matches the callable canonical JSON contract', () {
    expect(
      maintainiacFirestoreBatchSha256([
        MaintainiacFirestoreDocumentDraft(
          path: 'orgs/org-a/records/${'a' * 64}',
          data: const {
            'schema': 'maintainiac_durable_record_v1',
            'z': 2,
            'a': 1,
          },
        ),
      ]),
      '071bd0380dde0567ed3d2af299f4e1ce75d10e53b0d696f13b9dfb1d78804a03',
    );
  });

  test('client record hashing matches the callable canonical JSON contract', () {
    final record = MaintainiacDurableRecord(
      module: 'settings',
      id: 'settings-1',
      payload: const {'theme': 'dark'},
      lifecycle: MaintainiacRecordLifecycle(
        createdAt: DateTime.utc(2026, 7, 22),
        updatedAt: DateTime.utc(2026, 7, 22),
      ),
    );

    expect(
      MaintainiacRestoreApplier.contentSha256For(
        record,
        accountScopeId: 'org-a.user-a',
      ),
      'c310e1a75e38ff7a3b0e3ba2d29a596d3a52c05502335d638180ec6161d924f4',
    );
  });
}
