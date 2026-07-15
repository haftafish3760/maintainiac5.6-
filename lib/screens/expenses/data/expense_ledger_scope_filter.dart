import 'expense_ledger_models.dart';

/// Optional, exact scope for a recap. Empty fields mean "all" for that axis.
class ExpenseLedgerScopeFilter {
  const ExpenseLedgerScopeFilter({
    this.workProfileId = '',
    this.vehicleId = '',
    this.jobId = '',
  });

  final String workProfileId;
  final String vehicleId;
  final String jobId;

  bool matches(ExpenseReceiptRecord receipt) {
    final context = receipt.contextSnapshot;
    return (workProfileId.trim().isEmpty ||
            context.workProfileId == workProfileId.trim()) &&
        (vehicleId.trim().isEmpty || context.vehicleId == vehicleId.trim()) &&
        (jobId.trim().isEmpty || context.jobId == jobId.trim());
  }
}
