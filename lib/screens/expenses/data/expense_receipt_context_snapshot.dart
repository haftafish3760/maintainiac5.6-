part of 'expense_ledger_models.dart';

/// Immutable ownership context captured with an Expense receipt or draft.
/// Profile, vehicle, and job names can change later without rewriting history.
class ExpenseReceiptContextSnapshot {
  const ExpenseReceiptContextSnapshot({
    this.workProfileId = '',
    this.workProfileName = '',
    this.vehicleId = '',
    this.vehicleLabel = '',
    this.jobId = '',
    this.jobLabel = '',
  });

  factory ExpenseReceiptContextSnapshot.fromMap(
    Map<dynamic, dynamic>? map, {
    String fallbackWorkProfileId = '',
    String fallbackVehicleId = '',
  }) {
    final workProfileId = _expenseString(map?['workProfileId']).trim();
    final vehicleId = _expenseString(map?['vehicleId']).trim();
    return ExpenseReceiptContextSnapshot(
      workProfileId: workProfileId.isEmpty
          ? fallbackWorkProfileId.trim()
          : workProfileId,
      workProfileName: _expenseString(map?['workProfileName']).trim(),
      vehicleId: vehicleId.isEmpty ? fallbackVehicleId.trim() : vehicleId,
      vehicleLabel: _expenseString(map?['vehicleLabel']).trim(),
      jobId: _expenseString(map?['jobId']).trim(),
      jobLabel: _expenseString(map?['jobLabel']).trim(),
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
  bool get isEmpty => !hasWorkProfile && !hasVehicle && !hasJob;

  Map<String, String> toMap() => {
    'workProfileId': workProfileId,
    'workProfileName': workProfileName,
    'vehicleId': vehicleId,
    'vehicleLabel': vehicleLabel,
    'jobId': jobId,
    'jobLabel': jobLabel,
  };
}
