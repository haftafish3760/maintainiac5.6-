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
}
