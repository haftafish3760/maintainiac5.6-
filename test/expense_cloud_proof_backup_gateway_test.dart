import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_backup_gateway.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_finalizer.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_reference_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_storage.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_upload_coordinator.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_upload_grant.dart';

void main() {
  test(
    'issues a grant before persisting a finalized proof reference',
    () async {
      final issued = _GrantIssuer();
      final references = ExpenseCloudProofReferenceStore.memory();
      final gateway = ExpenseCloudProofBackupGateway(
        grantIssuer: issued,
        coordinator: ExpenseCloudProofUploadCoordinator(
          cloudStorage: ExpenseCloudProofStorage(objectStore: _ObjectStore()),
          finalizer: _Finalizer(),
          references: references,
          queueReceiptMetadata: (_) async {},
        ),
      );

      final proof = await gateway.backup(
        organizationId: 'org_1',
        userId: 'user_1',
        receiptId: 'receipt_1',
        proofId: 'proof_1',
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/jpeg',
      );

      expect(issued.requestedBytes, 3);
      expect(proof.isFinalized, isTrue);
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
}

class _GrantIssuer implements ExpenseCloudProofUploadGrantIssuer {
  int? requestedBytes;

  @override
  Future<ExpenseCloudProofUploadGrant> issue({
    required String organizationId,
    required String proofId,
    required int requestedBytes,
  }) async {
    this.requestedBytes = requestedBytes;
    return ExpenseCloudProofUploadGrant(
      id: 'grant_1',
      maximumBytes: requestedBytes,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 1)),
    );
  }
}

class _Finalizer implements ExpenseCloudProofFinalizer {
  @override
  Future<void> finalize(ExpenseCloudProofReference reference) async {}
}

class _ObjectStore implements ExpenseCloudProofObjectStore {
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
