import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_storage.dart';
import 'package:maintaniac/shared/firebase/maintainiac_callable_functions.dart';

/// Server boundary that irrevocably closes a short-lived proof upload grant.
abstract interface class ExpenseCloudProofFinalizer {
  Future<void> finalize(ExpenseCloudProofReference reference);
}

class FirebaseExpenseCloudProofFinalizer implements ExpenseCloudProofFinalizer {
  FirebaseExpenseCloudProofFinalizer({
    MaintainiacCallableFunctionClient? client,
  }) : _client = client ?? FirebaseMaintainiacCallableFunctionClient();

  final MaintainiacCallableFunctionClient _client;

  @override
  Future<void> finalize(ExpenseCloudProofReference reference) async {
    final data = await _client.call(
      name: 'finalizeExpenseProofUpload',
      data: {
        'organizationId': reference.organizationId,
        'receiptId': reference.receiptId,
        'proofId': reference.proofId,
        'grantId': reference.uploadGrantId,
        'contentSha256': reference.contentHashSha256,
      },
    );
    if (data['status'] != 'finalized' ||
        data['byteCount'] != reference.byteCount ||
        data['contentSha256'] != reference.contentHashSha256) {
      throw StateError('The cloud proof finalization response is invalid.');
    }
  }
}
