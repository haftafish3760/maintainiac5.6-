import 'dart:typed_data';

import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_reference_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_finalizer.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_storage.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_upload_grant.dart';

typedef ExpenseCloudProofMetadataQueue =
    Future<void> Function(String receiptId);

/// Coordinates the only safe order for a user-authorized proof backup:
/// transfer bytes, durably record the verified reference, then queue metadata.
/// It never deletes or alters the local proof.
class ExpenseCloudProofUploadCoordinator {
  const ExpenseCloudProofUploadCoordinator({
    required this.cloudStorage,
    required this.finalizer,
    required this.references,
    required this.queueReceiptMetadata,
  });

  final ExpenseCloudProofStorage cloudStorage;
  final ExpenseCloudProofFinalizer finalizer;
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
    await finalizer.finalize(reference);
    final finalized = reference.finalized();
    await references.save(finalized);
    await queueReceiptMetadata(receiptId);
    return finalized;
  }

  Future<ExpenseCloudProofReference> uploadWithGrant({
    required String organizationId,
    required String userId,
    required String receiptId,
    required String proofId,
    required ExpenseCloudProofUploadGrant grant,
    required Uint8List bytes,
    required String contentType,
  }) {
    if (!grant.isUsable || bytes.length > grant.maximumBytes) {
      throw StateError('The proof upload grant cannot authorize these bytes.');
    }
    return uploadAndQueue(
      organizationId: organizationId,
      userId: userId,
      receiptId: receiptId,
      proofId: proofId,
      uploadGrantId: grant.id,
      bytes: bytes,
      contentType: contentType,
    );
  }
}
