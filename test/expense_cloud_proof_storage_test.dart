import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_storage.dart';

void main() {
  test('uploads a tenant-scoped proof without a local device path', () async {
    final objectStore = _MemoryObjectStore();
    final storage = ExpenseCloudProofStorage(objectStore: objectStore);

    final reference = await storage.uploadProof(
      organizationId: 'org_1',
      userId: 'user_1',
      receiptId: 'receipt_1',
      proofId: 'proof_1',
      uploadGrantId: 'grant_1',
      bytes: Uint8List.fromList([1, 2, 3]),
      contentType: 'image/jpeg',
    );

    expect(
      reference.storagePath,
      'orgs/org_1/proof-uploads/user_1/grant_1/proof_1',
    );
    expect(objectStore.metadata.values.single, {
      'orgId': 'org_1',
      'uid': 'user_1',
      'receiptId': 'receipt_1',
      'proofId': 'proof_1',
      'contentSha256':
          '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81',
    });
  });

  test('downloads only the exact recorded proof byte count', () async {
    final objectStore = _MemoryObjectStore();
    final storage = ExpenseCloudProofStorage(objectStore: objectStore);
    final reference = await storage.uploadProof(
      organizationId: 'org_1',
      userId: 'user_1',
      receiptId: 'receipt_1',
      proofId: 'proof_1',
      uploadGrantId: 'grant_1',
      bytes: Uint8List.fromList([1, 2, 3]),
      contentType: 'image/jpeg',
    );

    expect(
      await storage.downloadProof(reference),
      Uint8List.fromList([1, 2, 3]),
    );

    objectStore.bytes[reference.storagePath] = Uint8List.fromList([1, 2]);
    await expectLater(() => storage.downloadProof(reference), throwsStateError);

    objectStore.bytes[reference.storagePath] = Uint8List.fromList([3, 2, 1]);
    await expectLater(() => storage.downloadProof(reference), throwsStateError);
  });

  test('rejects unsafe identifiers and non-image proof data', () async {
    final storage = ExpenseCloudProofStorage(objectStore: _MemoryObjectStore());

    await expectLater(
      () => storage.uploadProof(
        organizationId: 'org/other',
        userId: 'user_1',
        receiptId: 'receipt_1',
        proofId: 'proof_1',
        uploadGrantId: 'grant_1',
        bytes: Uint8List.fromList([1]),
        contentType: 'image/jpeg',
      ),
      throwsArgumentError,
    );
    await expectLater(
      () => storage.uploadProof(
        organizationId: 'org_1',
        userId: 'user_1',
        receiptId: 'receipt_1',
        proofId: 'proof_1',
        uploadGrantId: 'grant_1',
        bytes: Uint8List.fromList([1]),
        contentType: 'application/pdf',
      ),
      throwsArgumentError,
    );
  });
}

class _MemoryObjectStore implements ExpenseCloudProofObjectStore {
  final bytes = <String, Uint8List>{};
  final metadata = <String, Map<String, String>>{};

  @override
  Future<Uint8List> download({
    required String path,
    required int maxBytes,
  }) async {
    final value = bytes[path];
    if (value == null || value.length > maxBytes) {
      throw StateError('Missing proof.');
    }
    return value;
  }

  @override
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required Map<String, String> metadata,
  }) async {
    this.bytes[path] = bytes;
    this.metadata[path] = metadata;
  }
}
