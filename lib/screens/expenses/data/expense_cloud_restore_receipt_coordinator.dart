import 'expense_cloud_restore_codec.dart';
import 'expense_cloud_restore_planner.dart';
import 'expense_cloud_restore_session.dart';
import 'expense_ledger_store.dart';

/// Applies only cloud receipts that are still absent locally. Every created
/// record is checkpointed immediately; any conflict pauses the restore for
/// explicit review instead of overwriting a device record.
class ExpenseCloudRestoreReceiptCoordinator {
  const ExpenseCloudRestoreReceiptCoordinator({
    required this.ledger,
    required this.sessions,
  });

  final ExpenseLedgerController ledger;
  final ExpenseCloudRestoreSessionStore sessions;

  Future<ExpenseCloudRestoreReceiptResult> restoreMissing({
    required String sessionId,
    required Iterable<ExpenseCloudRestoredReceipt> cloudRecords,
    DateTime? nowUtc,
  }) async {
    var created = 0;
    final reviewPlans = <ExpenseCloudReceiptRestorePlan>[];
    try {
      for (final cloudRecord in cloudRecords) {
        final plan = ExpenseCloudRestorePlanner.planReceipt(
          ledger: ledger,
          cloudRecord: cloudRecord,
        );
        if (plan.disposition != ExpenseCloudRestoreDisposition.createLocal) {
          reviewPlans.add(plan);
          continue;
        }
        final applied = await ExpenseCloudRestorePlanner.createIfMissing(
          ledger: ledger,
          plan: plan,
        );
        if (!applied.wasCreated) {
          reviewPlans.add(plan);
          continue;
        }
        created += 1;
        final session = sessions.sessionById(sessionId);
        if (session == null) throw StateError('Restore session was not found.');
        await sessions.updateProgress(
          id: sessionId,
          completedDownloadBytes: session.completedDownloadBytes,
          completedRecords: session.completedRecords + 1,
          nowUtc: nowUtc,
        );
      }
    } catch (error) {
      await sessions.fail(
        sessionId,
        'Receipt restore could not continue.',
        nowUtc: nowUtc,
      );
      rethrow;
    }

    if (reviewPlans.isNotEmpty) {
      await sessions.pause(sessionId, nowUtc: nowUtc);
      return ExpenseCloudRestoreReceiptResult.reviewRequired(
        created: created,
        reviewPlans: reviewPlans,
      );
    }
    final session = sessions.sessionById(sessionId);
    if (session != null && session.hasCompletedTransfer) {
      await sessions.complete(sessionId, nowUtc: nowUtc);
    }
    return ExpenseCloudRestoreReceiptResult.completed(created);
  }
}

class ExpenseCloudRestoreReceiptResult {
  const ExpenseCloudRestoreReceiptResult._({
    required this.createdCount,
    required this.reviewPlans,
  });

  const ExpenseCloudRestoreReceiptResult.completed(int created)
    : this._(createdCount: created, reviewPlans: const []);

  const ExpenseCloudRestoreReceiptResult.reviewRequired({
    required int created,
    required List<ExpenseCloudReceiptRestorePlan> reviewPlans,
  }) : this._(createdCount: created, reviewPlans: reviewPlans);

  final int createdCount;
  final List<ExpenseCloudReceiptRestorePlan> reviewPlans;

  bool get needsReview => reviewPlans.isNotEmpty;
}
