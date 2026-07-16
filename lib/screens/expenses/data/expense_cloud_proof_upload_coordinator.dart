import 'dart:typed_data';

import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_reference_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_storage.dart';

typedef ExpenseCloudProofMetadataQueue =
    Future<void> Function(String receiptId);

/// Coordinates the only safe order for a user-authorized proof backup:
/// transfer bytes, durably record the verified reference, then queue metadata.
/// It never deletes or alters the local proof.
class ExpenseCloudProofUploadCoordinator {
  const ExpenseCloudProofUploadCoordinator({
    required this.cloudStorage,
    required this.references,
    required this.queueReceiptMetadata,
  });

  final ExpenseCloudProofStorage cloudStorage;
  final ExpenseCloudProofReferenceStore references;
  final ExpenseCloudProofMetadataQueue queueReceiptMetadata;

  Future<ExpenseCloudProofReference> uploadAndQueue({
    required String organizationId,
    required String userId,
    required String receiptId,
    required String proofId,
    required String uploadGrantId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final reference = await cloudStorage.uploadProof(
      organizationId: organizationId,
      userId: userId,
      receiptId: receiptId,
      proofId: proofId,
      uploadGrantId: uploadGrantId,
      bytes: bytes,
      contentType: contentType,
    );
    await references.save(reference);
    await queueReceiptMetadata(receiptId);
    return reference;
  }
}
