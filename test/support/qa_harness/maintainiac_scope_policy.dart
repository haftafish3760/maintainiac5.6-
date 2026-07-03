import 'maintainiac_qa_environment.dart';

class MaintainiacScopeSubject {
  const MaintainiacScopeSubject({
    required this.userId,
    required this.accountId,
    this.companyId = '',
    this.employeeId = '',
    this.vehicleIds = const {},
    this.permissions = const {},
  });

  final String userId;
  final String accountId;
  final String companyId;
  final String employeeId;
  final Set<String> vehicleIds;
  final Set<String> permissions;
}

class MaintainiacScopedRecord {
  const MaintainiacScopedRecord({
    required this.id,
    required this.accountId,
    this.companyId = '',
    this.employeeId = '',
    this.vehicleId = '',
    this.requiredPermission = 'read',
  });

  final String id;
  final String accountId;
  final String companyId;
  final String employeeId;
  final String vehicleId;
  final String requiredPermission;
}

class MaintainiacScopePolicyProbe {
  const MaintainiacScopePolicyProbe();

  bool canAccess(
    MaintainiacScopeSubject subject,
    MaintainiacScopedRecord record,
  ) {
    if (subject.accountId != record.accountId) return false;
    if (record.companyId.isNotEmpty && subject.companyId != record.companyId) {
      return false;
    }
    if (record.employeeId.isNotEmpty &&
        subject.employeeId != record.employeeId) {
      return false;
    }
    if (record.vehicleId.isNotEmpty &&
        !subject.vehicleIds.contains(record.vehicleId)) {
      return false;
    }
    return subject.permissions.contains(record.requiredPermission) ||
        subject.permissions.contains('admin');
  }

  List<String> deniedReasons(
    MaintainiacScopeSubject subject,
    MaintainiacScopedRecord record,
  ) {
    final reasons = <String>[];
    if (subject.accountId != record.accountId) reasons.add('account_mismatch');
    if (record.companyId.isNotEmpty && subject.companyId != record.companyId) {
      reasons.add('company_mismatch');
    }
    if (record.employeeId.isNotEmpty &&
        subject.employeeId != record.employeeId) {
      reasons.add('employee_mismatch');
    }
    if (record.vehicleId.isNotEmpty &&
        !subject.vehicleIds.contains(record.vehicleId)) {
      reasons.add('vehicle_not_assigned');
    }
    if (!subject.permissions.contains(record.requiredPermission) &&
        !subject.permissions.contains('admin')) {
      reasons.add('permission_missing');
    }
    return reasons;
  }

  MaintainiacScopeSubject ownerFrom(MaintainiacQaEnvironment env) {
    return MaintainiacScopeSubject(
      userId: env.user.id,
      accountId: env.account.id,
      vehicleIds: {env.vehicle.id},
      permissions: env.permissions.allowed,
    );
  }
}
