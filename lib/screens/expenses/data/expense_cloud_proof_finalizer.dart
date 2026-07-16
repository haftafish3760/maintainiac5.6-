import 'package:cloud_functions/cloud_functions.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_storage.dart';

/// Server boundary that irrevocably closes a short-lived proof upload grant.
abstract interface class ExpenseCloudProofFinalizer {
  Future<void> finalize(ExpenseCloudProofReference reference);
}

class FirebaseExpenseCloudProofFinalizer implements ExpenseCloudProofFinalizer {
  FirebaseExpenseCloudProofFinalizer({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  @override
  Future<void> finalize(ExpenseCloudProofReference reference) async {
    final result = await _functions
        .httpsCallable('finalizeExpenseProofUpload')
        .call<Map<String, dynamic>>({
          'organizationId': reference.organizationId,
          'receiptId': reference.receiptId,
          'proofId': reference.proofId,
          'grantId': reference.uploadGrantId,
          'contentSha256': reference.contentHashSha256,
        });
    final data = result.data;
    if (data['status'] != 'finalized' ||
        data['byteCount'] != reference.byteCount ||
        data['contentSha256'] != reference.contentHashSha256) {
      throw StateError('The cloud proof finalization response is invalid.');
    }
  }
}
