import 'user_profile_models.dart';

enum EmployeeInviteStatus {
  draft('Draft'),
  readyToInvite('Ready to invite'),
  inviteQueued('Invite queued'),
  active('Active'),
  disabled('Disabled');

  const EmployeeInviteStatus(this.label);

  final String label;
}

class EmployeeDirectoryRecord {
  const EmployeeDirectoryRecord({
    required this.id,
    required this.ownerProfileId,
    required this.name,
    required this.phone,
    required this.email,
    required this.roleLabel,
    required this.roleName,
    required this.customizedRole,
    required this.permissions,
    required this.structuredPermissions,
    required this.allowedEmployeeRoleNames,
    required this.allowedEmployeeRoleNamesByPermission,
    required this.allowedEmployeeIdsByPermission,
    required this.allowedModules,
    required this.allowedExpenseCategories,
    required this.payType,
    required this.payFrequency,
    required this.grossRate,
    required this.payPeriodStartDay,
    required this.overtimePolicy,
    required this.overtimeRate,
    required this.assignedVehicleLabel,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerProfileId;
  final String name;
  final String phone;
  final String email;
  final String roleLabel;
  final String roleName;
  final bool customizedRole;
  final Set<UserPermission> permissions;
  final Set<String> structuredPermissions;
  final Set<String> allowedEmployeeRoleNames;
  final Map<String, Set<String>> allowedEmployeeRoleNamesByPermission;
  final Map<String, Set<String>> allowedEmployeeIdsByPermission;
  final Set<String> allowedModules;
  final Set<String> allowedExpenseCategories;
  final String payType;
  final String payFrequency;
  final String grossRate;
  final String payPeriodStartDay;
  final String overtimePolicy;
  final String overtimeRate;
  final String assignedVehicleLabel;
  final EmployeeInviteStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasInviteEmail => email.contains('@') && email.contains('.');
  bool get canQueueInvite =>
      status == EmployeeInviteStatus.readyToInvite && hasInviteEmail;
  bool get isActive => status != EmployeeInviteStatus.disabled;

  EmployeeDirectoryRecord copyWith({
    String? id,
    String? ownerProfileId,
    String? name,
    String? phone,
    String? email,
    String? roleLabel,
    String? roleName,
    bool? customizedRole,
    Set<UserPermission>? permissions,
    Set<String>? structuredPermissions,
    Set<String>? allowedEmployeeRoleNames,
    Map<String, Set<String>>? allowedEmployeeRoleNamesByPermission,
    Map<String, Set<String>>? allowedEmployeeIdsByPermission,
    Set<String>? allowedModules,
    Set<String>? allowedExpenseCategories,
    String? payType,
    String? payFrequency,
    String? grossRate,
    String? payPeriodStartDay,
    String? overtimePolicy,
    String? overtimeRate,
    String? assignedVehicleLabel,
    EmployeeInviteStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmployeeDirectoryRecord(
      id: id ?? this.id,
      ownerProfileId: ownerProfileId ?? this.ownerProfileId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      roleLabel: roleLabel ?? this.roleLabel,
      roleName: roleName ?? this.roleName,
      customizedRole: customizedRole ?? this.customizedRole,
      permissions: permissions ?? this.permissions,
      structuredPermissions:
          structuredPermissions ?? this.structuredPermissions,
      allowedEmployeeRoleNames:
          allowedEmployeeRoleNames ?? this.allowedEmployeeRoleNames,
      allowedEmployeeRoleNamesByPermission:
          allowedEmployeeRoleNamesByPermission ??
          this.allowedEmployeeRoleNamesByPermission,
      allowedEmployeeIdsByPermission:
          allowedEmployeeIdsByPermission ?? this.allowedEmployeeIdsByPermission,
      allowedModules: allowedModules ?? this.allowedModules,
      allowedExpenseCategories:
          allowedExpenseCategories ?? this.allowedExpenseCategories,
      payType: payType ?? this.payType,
      payFrequency: payFrequency ?? this.payFrequency,
      grossRate: grossRate ?? this.grossRate,
      payPeriodStartDay: payPeriodStartDay ?? this.payPeriodStartDay,
      overtimePolicy: overtimePolicy ?? this.overtimePolicy,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      assignedVehicleLabel: assignedVehicleLabel ?? this.assignedVehicleLabel,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'ownerProfileId': ownerProfileId,
    'name': name,
    'phone': phone,
    'email': email,
    'roleLabel': roleLabel,
    'roleName': roleName,
    'customizedRole': customizedRole,
    'permissions': permissions.map((item) => item.name).toList()..sort(),
    'structuredPermissions': structuredPermissions.toList()..sort(),
    'allowedEmployeeRoleNames': allowedEmployeeRoleNames.toList()..sort(),
    'allowedEmployeeRoleNamesByPermission': _roleAccessMapToMap(
      allowedEmployeeRoleNamesByPermission,
    ),
    'allowedEmployeeIdsByPermission': _roleAccessMapToMap(
      allowedEmployeeIdsByPermission,
    ),
    'allowedModules': allowedModules.toList()..sort(),
    'allowedExpenseCategories': allowedExpenseCategories.toList()..sort(),
    'payType': payType,
    'payFrequency': payFrequency,
    'grossRate': grossRate,
    'payPeriodStartDay': payPeriodStartDay,
    'overtimePolicy': overtimePolicy,
    'overtimeRate': overtimeRate,
    'assignedVehicleLabel': assignedVehicleLabel,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Map<String, dynamic> toInvitePayload() => {
    'employeeId': id,
    'displayName': name,
    'email': email,
    'role': roleName,
    'roleLabel': roleLabel,
    'customizedRole': customizedRole,
    'permissions': permissions.map((item) => item.name).toList()..sort(),
    'structuredPermissions': structuredPermissions.toList()..sort(),
    'allowedEmployeeRoleNames': allowedEmployeeRoleNames.toList()..sort(),
    'allowedEmployeeRoleNamesByPermission': _roleAccessMapToMap(
      allowedEmployeeRoleNamesByPermission,
    ),
    'allowedEmployeeIdsByPermission': _roleAccessMapToMap(
      allowedEmployeeIdsByPermission,
    ),
    'allowedModules': allowedModules.toList()..sort(),
    'allowedExpenseCategories': allowedExpenseCategories.toList()..sort(),
    'status': status.name,
  };

  factory EmployeeDirectoryRecord.fromMap(Map<dynamic, dynamic> map) {
    final permissions = _permissionSet(map['permissions']);
    final structuredPermissions = _stringSet(map['structuredPermissions']);
    return EmployeeDirectoryRecord(
      id: _string(map['id'], fallback: _newEmployeeId()),
      ownerProfileId: _string(map['ownerProfileId'], fallback: 'local-owner'),
      name: _string(map['name']),
      phone: _string(map['phone']),
      email: _string(map['email']),
      roleLabel: _string(map['roleLabel'], fallback: 'Custom'),
      roleName: _string(map['roleName'], fallback: UserRole.viewer.name),
      customizedRole: map['customizedRole'] == true,
      permissions: permissions,
      structuredPermissions: structuredPermissions.isEmpty
          ? _structuredPermissionsForFallback(map)
          : structuredPermissions,
      allowedEmployeeRoleNames: _stringSet(map['allowedEmployeeRoleNames']),
      allowedEmployeeRoleNamesByPermission: _roleAccessMapFromMap(
        map['allowedEmployeeRoleNamesByPermission'],
      ),
      allowedEmployeeIdsByPermission: _roleAccessMapFromMap(
        map['allowedEmployeeIdsByPermission'],
      ),
      allowedModules: _stringSet(map['allowedModules']).isEmpty
          ? allowedModulesForPermissions(permissions)
          : _stringSet(map['allowedModules']),
      allowedExpenseCategories: _stringSet(map['allowedExpenseCategories']),
      payType: _string(map['payType'], fallback: 'notTracked'),
      payFrequency: _string(map['payFrequency'], fallback: 'weekly'),
      grossRate: _string(map['grossRate']),
      payPeriodStartDay: _string(map['payPeriodStartDay'], fallback: 'monday'),
      overtimePolicy: _string(map['overtimePolicy'], fallback: 'none'),
      overtimeRate: _string(map['overtimeRate']),
      assignedVehicleLabel: _string(map['assignedVehicleLabel']),
      status:
          _enumByName(EmployeeInviteStatus.values, map['status']) ??
          EmployeeInviteStatus.draft,
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  factory EmployeeDirectoryRecord.create({
    required String ownerProfileId,
    required String name,
    required String phone,
    required String email,
    required String roleLabel,
    required String roleName,
    required bool customizedRole,
    required Set<UserPermission> permissions,
    Set<String> structuredPermissions = const {},
    Set<String> allowedEmployeeRoleNames = const {},
    Map<String, Set<String>> allowedEmployeeRoleNamesByPermission = const {},
    Map<String, Set<String>> allowedEmployeeIdsByPermission = const {},
    Set<String>? allowedModules,
    Set<String> allowedExpenseCategories = const {},
    required String payType,
    required String payFrequency,
    required String grossRate,
    String payPeriodStartDay = 'monday',
    String overtimePolicy = 'none',
    String overtimeRate = '',
    String assignedVehicleLabel = '',
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final normalizedEmail = email.trim().toLowerCase();
    final status =
        normalizedEmail.contains('@') && normalizedEmail.contains('.')
        ? EmployeeInviteStatus.readyToInvite
        : EmployeeInviteStatus.draft;
    return EmployeeDirectoryRecord(
      id: _newEmployeeId(timestamp),
      ownerProfileId: ownerProfileId,
      name: name.trim(),
      phone: phone.trim(),
      email: normalizedEmail,
      roleLabel: roleLabel,
      roleName: roleName,
      customizedRole: customizedRole,
      permissions: permissions,
      structuredPermissions: structuredPermissions,
      allowedEmployeeRoleNames: allowedEmployeeRoleNames,
      allowedEmployeeRoleNamesByPermission:
          allowedEmployeeRoleNamesByPermission,
      allowedEmployeeIdsByPermission: allowedEmployeeIdsByPermission,
      allowedModules:
          allowedModules ?? allowedModulesForPermissions(permissions),
      allowedExpenseCategories: allowedExpenseCategories,
      payType: payType,
      payFrequency: payFrequency,
      grossRate: grossRate.trim(),
      payPeriodStartDay: payPeriodStartDay,
      overtimePolicy: overtimePolicy,
      overtimeRate: overtimeRate.trim(),
      assignedVehicleLabel: assignedVehicleLabel.trim(),
      status: status,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }
}

Set<String> allowedModulesForPermissions(Set<UserPermission> permissions) {
  final modules = <String>{};
  for (final permission in permissions) {
    switch (permission.group) {
      case PermissionGroup.company:
        modules.add('admin');
      case PermissionGroup.vehiclesMileage:
        modules.addAll({'vehicles', 'mileage'});
      case PermissionGroup.jobsSchedule:
        modules.addAll({'jobs', 'calendar'});
      case PermissionGroup.invoicesEstimates:
        modules.addAll({'invoices', 'estimates'});
      case PermissionGroup.expensesReceipts:
        modules.addAll({'expenses', 'receipts'});
      case PermissionGroup.inventoryMaterials:
        modules.add('inventory');
      case PermissionGroup.maintenance:
        modules.add('maintenance');
      case PermissionGroup.reportsExports:
        modules.addAll({'reports', 'exports'});
      case PermissionGroup.customerPortal:
        modules.add('customerPortal');
    }
  }
  return modules;
}

Set<String> _structuredPermissionsForFallback(Map<dynamic, dynamic> map) {
  final categories = _stringSet(map['allowedExpenseCategories']);
  if (categories.isEmpty) return const {};
  return {
    for (final category in categories)
      for (final action in const ['view', 'create', 'edit'])
        'expenses.$category.own.$action',
  };
}

EmployeeInviteStatus employeeStatusForEmail(
  String email,
  EmployeeInviteStatus currentStatus,
) {
  final normalizedEmail = email.trim().toLowerCase();
  final hasEmail =
      normalizedEmail.contains('@') && normalizedEmail.contains('.');
  if (!hasEmail) return EmployeeInviteStatus.draft;
  return switch (currentStatus) {
    EmployeeInviteStatus.inviteQueued ||
    EmployeeInviteStatus.active ||
    EmployeeInviteStatus.disabled => currentStatus,
    EmployeeInviteStatus.draft ||
    EmployeeInviteStatus.readyToInvite => EmployeeInviteStatus.readyToInvite,
  };
}

String employeePaySummary(EmployeeDirectoryRecord record) {
  if (record.payType == 'notTracked') return 'Not tracked';
  final frequency = _labelForName(record.payFrequency, {
    'weekly': 'Weekly',
    'biweekly': 'Every 2 weeks',
    'semimonthly': 'Twice a month',
    'monthly': 'Monthly',
  });
  final rate = record.grossRate.isEmpty ? 'rate not added' : record.grossRate;
  final startDay = _labelForName(record.payPeriodStartDay, {
    'monday': 'Monday-Sunday',
    'tuesday': 'Tuesday-Monday',
    'wednesday': 'Wednesday-Tuesday',
    'thursday': 'Thursday-Wednesday',
    'friday': 'Friday-Thursday',
    'saturday': 'Saturday-Friday',
    'sunday': 'Sunday-Saturday',
  });
  final overtime = employeeOvertimeSummary(record);
  if (record.payType == 'salary') {
    return '$frequency salary / $rate / period $startDay / $overtime';
  }
  return 'Hourly / $rate per hour / $frequency / period $startDay / $overtime';
}

String employeeOvertimeSummary(EmployeeDirectoryRecord record) {
  return switch (record.overtimePolicy) {
    'timeAndHalf' => 'overtime: 1.5x',
    'custom' =>
      record.overtimeRate.isEmpty
          ? 'overtime: custom rate not set'
          : 'overtime: ${record.overtimeRate}',
    _ => 'no overtime',
  };
}

String _labelForName(String name, Map<String, String> labels) {
  return labels[name] ?? name;
}

Set<UserPermission> _permissionSet(Object? value) {
  if (value is! Iterable) return {};
  return value
      .whereType<String>()
      .map((name) => _enumByName(UserPermission.values, name))
      .whereType<UserPermission>()
      .toSet();
}

Set<String> _stringSet(Object? value) {
  if (value is! Iterable) return {};
  return value.whereType<String>().map((item) => item.trim()).toSet()
    ..removeWhere((item) => item.isEmpty);
}

Map<String, Set<String>> _roleAccessMapFromMap(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.key is String && _stringSet(entry.value).isNotEmpty)
        (entry.key as String): _stringSet(entry.value),
  };
}

Map<String, List<String>> _roleAccessMapToMap(
  Map<String, Set<String>> roleAccess,
) {
  return {
    for (final entry in roleAccess.entries)
      if (entry.value.isNotEmpty) entry.key: entry.value.toList()..sort(),
  };
}

T? _enumByName<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

String _string(Object? value, {String fallback = ''}) {
  final text = value is String ? value.trim() : '';
  return text.isEmpty ? fallback : text;
}

DateTime _date(Object? value) {
  return value is String
      ? DateTime.tryParse(value) ?? DateTime.now()
      : DateTime.now();
}

String _newEmployeeId([DateTime? now]) {
  return 'employee-${(now ?? DateTime.now()).microsecondsSinceEpoch}';
}
