part of 'expense_ledger_models.dart';

/// Immutable context captured with an expense. Changing the active work or
/// vehicle later must never rewrite a historical expense.
class ExpenseReceiptContextSnapshot {
  const ExpenseReceiptContextSnapshot({
    this.workProfileId = '',
    this.workProfileName = '',
    this.vehicleId = '',
    this.vehicleLabel = '',
    this.jobId = '',
    this.jobLabel = '',
  });

  factory ExpenseReceiptContextSnapshot.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const ExpenseReceiptContextSnapshot();
    return ExpenseReceiptContextSnapshot(
      workProfileId: _expenseString(map['workProfileId']).trim(),
      workProfileName: _expenseString(map['workProfileName']).trim(),
      vehicleId: _expenseString(map['vehicleId']).trim(),
      vehicleLabel: _expenseString(map['vehicleLabel']).trim(),
      jobId: _expenseString(map['jobId']).trim(),
      jobLabel: _expenseString(map['jobLabel']).trim(),
    );
  }

  final String workProfileId;
  final String workProfileName;
  final String vehicleId;
  final String vehicleLabel;
  final String jobId;
  final String jobLabel;

  bool get hasWorkProfile => workProfileId.isNotEmpty;
  bool get hasVehicle => vehicleId.isNotEmpty;
  bool get hasJob => jobId.isNotEmpty;

  Map<String, String> toMap() => {
    'workProfileId': workProfileId,
    'workProfileName': workProfileName,
    'vehicleId': vehicleId,
    'vehicleLabel': vehicleLabel,
    'jobId': jobId,
    'jobLabel': jobLabel,
  };
}
