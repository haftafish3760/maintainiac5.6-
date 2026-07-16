import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_reference_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_storage.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_upload_coordinator.dart';

void main() {
  test(
    'queues metadata only after the verified reference is durable',
    () async {
      final queued = <String>[];
      final references = ExpenseCloudProofReferenceStore.memory();
      final coordinator = ExpenseCloudProofUploadCoordinator(
        cloudStorage: ExpenseCloudProofStorage(
          objectStore: _MemoryObjectStore(),
        ),
        references: references,
      queueReceiptMetadata: (receiptId) async => queued.add(receiptId),
      );

      await coordinator.uploadAndQueue(
        organizationId: 'org_1',
        userId: 'user_1',
        receiptId: 'receipt_1',
        proofId: 'proof_1',
        uploadGrantId: 'grant_1',
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/jpeg',
      );

      expect(queued, ['receipt_1']);
      expect(
        references.referencesForReceipt(
          organizationId: 'org_1',
          userId: 'user_1',
          receiptId: 'receipt_1',
        ),
        hasLength(1),
      );
    },
  );

  test(
    'does not queue metadata when durable reference storage fails',
    () async {
      final queued = <String>[];
      final coordinator = ExpenseCloudProofUploadCoordinator(
        cloudStorage: ExpenseCloudProofStorage(
          objectStore: _MemoryObjectStore(),
        ),
        references: ExpenseCloudProofReferenceStore.memory(
          storageCheck: () => throw StateError('No local storage'),
        ),
      queueReceiptMetadata: (receiptId) async => queued.add(receiptId),
      );

      await expectLater(
        () => coordinator.uploadAndQueue(
          organizationId: 'org_1',
          userId: 'user_1',
          receiptId: 'receipt_1',
          proofId: 'proof_1',
          uploadGrantId: 'grant_1',
          bytes: Uint8List.fromList([1, 2, 3]),
          contentType: 'image/jpeg',
        ),
        throwsStateError,
      );
      expect(queued, isEmpty);
    },
  );
}

class _MemoryObjectStore implements ExpenseCloudProofObjectStore {
  @override
  Future<Uint8List> download({required String path, required int maxBytes}) =>
      throw UnimplementedError();

  @override
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required Map<String, String> metadata,
  }) async {}
}
