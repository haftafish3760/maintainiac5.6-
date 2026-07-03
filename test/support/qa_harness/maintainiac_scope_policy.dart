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

class MaintainiacScopePolicyCase {
  const MaintainiacScopePolicyCase({
    required this.id,
    required this.subject,
    required this.record,
    required this.expectedAllowed,
    required this.expectedDeniedReasons,
    required this.reason,
  });

  final String id;
  final MaintainiacScopeSubject subject;
  final MaintainiacScopedRecord record;
  final bool expectedAllowed;
  final Set<String> expectedDeniedReasons;
  final String reason;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) {
      failures.add('scope case missing id');
    }
    if (reason.trim().isEmpty) {
      failures.add('$id missing reason');
    }
    final probe = const MaintainiacScopePolicyProbe();
    final actualAllowed = probe.canAccess(subject, record);
    final actualDenied = probe.deniedReasons(subject, record).toSet();
    if (actualAllowed != expectedAllowed) {
      failures.add('$id expected allowed=$expectedAllowed got $actualAllowed');
    }
    if (actualDenied.toString() != expectedDeniedReasons.toString()) {
      failures.add('$id denied reasons do not match expected');
    }
    if (!expectedAllowed && expectedDeniedReasons.isEmpty) {
      failures.add('$id denied case must explain why');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'subjectAccountId': subject.accountId,
      'recordAccountId': record.accountId,
      'recordCompanyId': record.companyId,
      'recordEmployeeId': record.employeeId,
      'recordVehicleId': record.vehicleId,
      'requiredPermission': record.requiredPermission,
      'expectedAllowed': expectedAllowed,
      'expectedDeniedReasons': expectedDeniedReasons.toList()..sort(),
      'reason': reason,
    };
  }
}

class MaintainiacScopePolicyMatrix {
  const MaintainiacScopePolicyMatrix(this.cases);

  final List<MaintainiacScopePolicyCase> cases;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final deniedReasons = <String>{};
    var allowedCount = 0;
    for (final entry in cases) {
      if (!ids.add(entry.id)) {
        failures.add('duplicate scope case ${entry.id}');
      }
      if (entry.expectedAllowed) {
        allowedCount += 1;
      }
      deniedReasons.addAll(entry.expectedDeniedReasons);
      failures.addAll(entry.validate());
    }
    if (allowedCount == 0) {
      failures.add('scope policy matrix has no allowed case');
    }
    for (final required in {
      'account_mismatch',
      'company_mismatch',
      'employee_mismatch',
      'vehicle_not_assigned',
      'permission_missing',
    }) {
      if (!deniedReasons.contains(required)) {
        failures.add('scope policy matrix missing denial $required');
      }
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'caseCount': cases.length,
      'cases': [for (final entry in cases) entry.toJson()],
    };
  }
}

const maintainiacScopePolicyMatrix = MaintainiacScopePolicyMatrix([
  MaintainiacScopePolicyCase(
    id: 'owner_assigned_vehicle_read_allowed',
    subject: MaintainiacScopeSubject(
      userId: 'owner',
      accountId: 'acct_1',
      vehicleIds: {'truck_1'},
      permissions: {'read'},
    ),
    record: MaintainiacScopedRecord(
      id: 'expense_1',
      accountId: 'acct_1',
      vehicleId: 'truck_1',
      requiredPermission: 'read',
    ),
    expectedAllowed: true,
    expectedDeniedReasons: {},
    reason: 'Account owner can read assigned vehicle records.',
  ),
  MaintainiacScopePolicyCase(
    id: 'cross_account_denied',
    subject: MaintainiacScopeSubject(
      userId: 'owner',
      accountId: 'acct_1',
      vehicleIds: {'truck_1'},
      permissions: {'read'},
    ),
    record: MaintainiacScopedRecord(
      id: 'expense_2',
      accountId: 'acct_2',
      vehicleId: 'truck_1',
      requiredPermission: 'read',
    ),
    expectedAllowed: false,
    expectedDeniedReasons: {'account_mismatch'},
    reason: 'No user can read another account by accident.',
  ),
  MaintainiacScopePolicyCase(
    id: 'company_mismatch_denied',
    subject: MaintainiacScopeSubject(
      userId: 'employee',
      accountId: 'acct_1',
      companyId: 'company_1',
      employeeId: 'employee_1',
      permissions: {'read'},
    ),
    record: MaintainiacScopedRecord(
      id: 'job_1',
      accountId: 'acct_1',
      companyId: 'company_2',
      employeeId: 'employee_1',
      requiredPermission: 'read',
    ),
    expectedAllowed: false,
    expectedDeniedReasons: {'company_mismatch'},
    reason: 'Fleet/company records stay scoped to the active company.',
  ),
  MaintainiacScopePolicyCase(
    id: 'employee_mismatch_denied',
    subject: MaintainiacScopeSubject(
      userId: 'employee',
      accountId: 'acct_1',
      companyId: 'company_1',
      employeeId: 'employee_1',
      permissions: {'read'},
    ),
    record: MaintainiacScopedRecord(
      id: 'calendar_1',
      accountId: 'acct_1',
      companyId: 'company_1',
      employeeId: 'employee_2',
      requiredPermission: 'read',
    ),
    expectedAllowed: false,
    expectedDeniedReasons: {'employee_mismatch'},
    reason: 'Employee-scoped records require the matching employee profile.',
  ),
  MaintainiacScopePolicyCase(
    id: 'vehicle_assignment_denied',
    subject: MaintainiacScopeSubject(
      userId: 'employee',
      accountId: 'acct_1',
      companyId: 'company_1',
      employeeId: 'employee_1',
      vehicleIds: {'truck_1'},
      permissions: {'read'},
    ),
    record: MaintainiacScopedRecord(
      id: 'inventory_1',
      accountId: 'acct_1',
      companyId: 'company_1',
      employeeId: 'employee_1',
      vehicleId: 'truck_2',
      requiredPermission: 'read',
    ),
    expectedAllowed: false,
    expectedDeniedReasons: {'vehicle_not_assigned'},
    reason: 'Vehicle inventory requires assigned vehicle access.',
  ),
  MaintainiacScopePolicyCase(
    id: 'permission_missing_denied',
    subject: MaintainiacScopeSubject(
      userId: 'employee',
      accountId: 'acct_1',
      companyId: 'company_1',
      employeeId: 'employee_1',
      vehicleIds: {'truck_1'},
      permissions: {'read'},
    ),
    record: MaintainiacScopedRecord(
      id: 'export_1',
      accountId: 'acct_1',
      companyId: 'company_1',
      employeeId: 'employee_1',
      vehicleId: 'truck_1',
      requiredPermission: 'export',
    ),
    expectedAllowed: false,
    expectedDeniedReasons: {'permission_missing'},
    reason: 'Exports need explicit export permission.',
  ),
]);
