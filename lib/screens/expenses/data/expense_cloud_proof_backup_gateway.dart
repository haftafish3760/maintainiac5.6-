import 'dart:typed_data';

import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_storage.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_upload_coordinator.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_upload_grant.dart';

/// The complete cloud-proof lifecycle used by any future receipt entry point:
/// obtain a server grant, upload, finalize server evidence, store the local
/// reference, then queue only metadata. It never changes a device proof.
class ExpenseCloudProofBackupGateway {
  const ExpenseCloudProofBackupGateway({
    required this.grantIssuer,
    required this.coordinator,
  });

  final ExpenseCloudProofUploadGrantIssuer grantIssuer;
  final ExpenseCloudProofUploadCoordinator coordinator;

  Future<ExpenseCloudProofReference> backup({
    required String organizationId,
    required String userId,
    required String receiptId,
    required String proofId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final grant = await grantIssuer.issue(
      organizationId: organizationId,
      proofId: proofId,
      requestedBytes: bytes.length,
    );
    return coordinator.uploadWithGrant(
      organizationId: organizationId,
      userId: userId,
      receiptId: receiptId,
      proofId: proofId,
      grant: grant,
      bytes: bytes,
      contentType: contentType,
    );
  }
}
