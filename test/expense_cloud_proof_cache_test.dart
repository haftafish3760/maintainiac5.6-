import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_cache.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_storage.dart';

void main() {
  test('uses a verified app-owned cache before downloading again', () async {
    final root = await Directory.systemTemp.createTemp('proof-cache-test-');
    addTearDown(() => root.delete(recursive: true));
    final store = _MemoryObjectStore();
    final cloud = ExpenseCloudProofStorage(objectStore: store);
    final reference = await cloud.uploadProof(
      organizationId: 'org_1',
      userId: 'user_1',
      receiptId: 'receipt_1',
      proofId: 'proof_1',
      uploadGrantId: 'grant_1',
      bytes: Uint8List.fromList([1, 2, 3]),
      contentType: 'image/jpeg',
    );
    final cache = ExpenseCloudProofCache(
      cloudStorage: cloud,
      rootDirectory: () async => root,
      ensureSpace: (_) async {},
    );

    final first = await cache.restore(reference);
    final second = await cache.restore(reference);

    expect(first.wasDownloaded, isTrue);
    expect(second.wasDownloaded, isFalse);
    expect(await second.file.readAsBytes(), Uint8List.fromList([1, 2, 3]));
    expect(store.downloadCount, 1);
  });

  test(
    'does not use a corrupt cache entry and preserves it for recovery',
    () async {
      final root = await Directory.systemTemp.createTemp('proof-cache-test-');
      addTearDown(() => root.delete(recursive: true));
      final store = _MemoryObjectStore();
      final cloud = ExpenseCloudProofStorage(objectStore: store);
      final reference = await cloud.uploadProof(
        organizationId: 'org_1',
        userId: 'user_1',
        receiptId: 'receipt_1',
        proofId: 'proof_1',
        uploadGrantId: 'grant_1',
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/jpeg',
      );
      final cacheFile = File(
        '${root.path}/proof_1--${reference.contentHashSha256}.proof',
      );
      await cacheFile.writeAsBytes([9, 9, 9]);
      final cache = ExpenseCloudProofCache(
        cloudStorage: cloud,
        rootDirectory: () async => root,
        ensureSpace: (_) async {},
      );

      final restored = await cache.restore(reference);

      expect(await restored.file.readAsBytes(), Uint8List.fromList([1, 2, 3]));
      expect(
        await root
            .list()
            .where((item) => item.path.contains('.corrupt.'))
            .length,
        1,
      );
    },
  );

  test('does not download when local storage is insufficient', () async {
    final root = await Directory.systemTemp.createTemp('proof-cache-test-');
    addTearDown(() => root.delete(recursive: true));
    final store = _MemoryObjectStore();
    final cloud = ExpenseCloudProofStorage(objectStore: store);
    final reference = await cloud.uploadProof(
      organizationId: 'org_1',
      userId: 'user_1',
      receiptId: 'receipt_1',
      proofId: 'proof_1',
      uploadGrantId: 'grant_1',
      bytes: Uint8List.fromList([1, 2, 3]),
      contentType: 'image/jpeg',
    );
    final cache = ExpenseCloudProofCache(
      cloudStorage: cloud,
      rootDirectory: () async => root,
      ensureSpace: (_) => throw StateError('Insufficient storage'),
    );

    await expectLater(() => cache.restore(reference), throwsStateError);
    expect(store.downloadCount, 0);
  });
}

class _MemoryObjectStore implements ExpenseCloudProofObjectStore {
  final bytes = <String, Uint8List>{};
  var downloadCount = 0;

  @override
  Future<Uint8List> download({
    required String path,
    required int maxBytes,
  }) async {
    downloadCount += 1;
    return bytes[path]!;
  }

  @override
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required Map<String, String> metadata,
  }) async {
    this.bytes[path] = bytes;
  }
}
