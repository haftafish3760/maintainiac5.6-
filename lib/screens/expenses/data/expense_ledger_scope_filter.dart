import 'expense_ledger_models.dart';

/// Exact historical scope for Expense queries. Empty axes mean "all".
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
    final receiptWorkProfileId = context.workProfileId.isEmpty
        ? receipt.workProfileId ?? ''
        : context.workProfileId;
    final receiptVehicleId = context.vehicleId.isEmpty
        ? receipt.vehicleId ?? ''
        : context.vehicleId;
    final requestedWorkProfileId = workProfileId.trim();
    final requestedVehicleId = vehicleId.trim();
    final requestedJobId = jobId.trim();
    return (requestedWorkProfileId.isEmpty ||
            receiptWorkProfileId == requestedWorkProfileId) &&
        (requestedVehicleId.isEmpty ||
            receiptVehicleId == requestedVehicleId) &&
        (requestedJobId.isEmpty || context.jobId == requestedJobId);
  }
}
