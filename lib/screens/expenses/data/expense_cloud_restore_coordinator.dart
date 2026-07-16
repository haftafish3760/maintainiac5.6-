import 'expense_cloud_proof_storage.dart';
import 'expense_cloud_restore_codec.dart';
import 'expense_cloud_restore_proof_coordinator.dart';
import 'expense_cloud_restore_receipt_coordinator.dart';
import 'expense_cloud_restore_session.dart';
import 'expense_cloud_restore_storage_plan.dart';

/// Runs a safe Expense restore in dependency order: local records first, then
/// proof files only for a user-authorized full restore. Conflicts pause before
/// any proof transfer, and neither stage overwrites a local record.
class ExpenseCloudRestoreCoordinator {
  const ExpenseCloudRestoreCoordinator({
    required this.receipts,
    required this.proofs,
    required this.sessions,
  });

  final ExpenseCloudRestoreReceiptCoordinator receipts;
  final ExpenseCloudRestoreProofCoordinator proofs;
  final ExpenseCloudRestoreSessionStore sessions;

  Future<ExpenseCloudRestoreResult> restore({
    required String sessionId,
    required Iterable<ExpenseCloudRestoredReceipt> cloudRecords,
    required Iterable<ExpenseCloudProofReference> proofReferences,
    DateTime? nowUtc,
  }) async {
    final receiptResult = await receipts.restoreMissing(
      sessionId: sessionId,
      cloudRecords: cloudRecords,
      nowUtc: nowUtc,
    );
    if (receiptResult.needsReview) {
      return ExpenseCloudRestoreResult.reviewRequired(receiptResult);
    }
    final session = sessions.sessionById(sessionId);
    if (session == null) throw StateError('Restore session was not found.');
    if (session.isTerminal) {
      return ExpenseCloudRestoreResult.completed(
        receipts: receiptResult.createdCount,
        proofs: 0,
      );
    }
    if (session.mode == ExpenseCloudRestoreMode.full) {
      final proofResult = await proofs.restoreFullProofs(
        sessionId: sessionId,
        references: proofReferences,
        nowUtc: nowUtc,
      );
      return ExpenseCloudRestoreResult.completed(
        receipts: receiptResult.createdCount,
        proofs: proofResult.restoredCount,
      );
    }
    return ExpenseCloudRestoreResult.completed(
      receipts: receiptResult.createdCount,
      proofs: 0,
    );
  }
}

class ExpenseCloudRestoreResult {
  const ExpenseCloudRestoreResult._({
    required this.createdReceiptCount,
    required this.restoredProofCount,
    required this.receiptResult,
  });

  const ExpenseCloudRestoreResult.completed({
    required int receipts,
    required int proofs,
  }) : this._(
         createdReceiptCount: receipts,
         restoredProofCount: proofs,
         receiptResult: null,
       );

  ExpenseCloudRestoreResult.reviewRequired(
    ExpenseCloudRestoreReceiptResult result,
  ) : this._(
        createdReceiptCount: result.createdCount,
        restoredProofCount: 0,
        receiptResult: result,
      );

  final int createdReceiptCount;
  final int restoredProofCount;
  final ExpenseCloudRestoreReceiptResult? receiptResult;

  bool get needsReview => receiptResult?.needsReview ?? false;
}
