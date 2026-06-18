enum UserProfileType {
  contractor('Contractor'),
  driver('Driver'),
  customer('Customer');

  const UserProfileType(this.label);

  final String label;
}

enum UserRole {
  owner('Owner'),
  admin('Admin'),
  manager('Manager'),
  helper('Helper'),
  viewer('Viewer');

  const UserRole(this.label);

  final String label;
}

enum UserPermission {
  manageProfiles('Manage profiles'),
  manageVehicles('Manage vehicles'),
  manageJobs('Manage jobs'),
  createInvoices('Create invoices'),
  approveInvoices('Approve invoices'),
  viewFinancials('View financials'),
  manageInventory('Manage inventory'),
  recordMileage('Record mileage'),
  recordExpenses('Record expenses'),
  viewOnly('View only');

  const UserPermission(this.label);

  final String label;
}

class UserProfileRecord {
  const UserProfileRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.role,
    required this.permissions,
    this.businessName = '',
    this.cloudBackupEnabled = false,
    this.customerFacingEnabled = false,
    this.activeVehicleIds = const [],
  });

  final String id;
  final String name;
  final UserProfileType type;
  final UserRole role;
  final Set<UserPermission> permissions;
  final String businessName;
  final bool cloudBackupEnabled;
  final bool customerFacingEnabled;
  final List<String> activeVehicleIds;

  bool can(UserPermission permission) {
    if (role == UserRole.owner) return true;
    return permissions.contains(permission);
  }

  String get displayName => businessName.trim().isEmpty ? name : businessName;
  String get primaryVehicleId =>
      activeVehicleIds.isEmpty ? '' : activeVehicleIds.first;

  UserProfileRecord copyWith({
    String? id,
    String? name,
    UserProfileType? type,
    UserRole? role,
    Set<UserPermission>? permissions,
    String? businessName,
    bool? cloudBackupEnabled,
    bool? customerFacingEnabled,
    List<String>? activeVehicleIds,
  }) {
    return UserProfileRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      businessName: businessName ?? this.businessName,
      cloudBackupEnabled: cloudBackupEnabled ?? this.cloudBackupEnabled,
      customerFacingEnabled:
          customerFacingEnabled ?? this.customerFacingEnabled,
      activeVehicleIds: activeVehicleIds ?? this.activeVehicleIds,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.name,
    'role': role.name,
    'permissions': permissions.map((item) => item.name).toList(),
    'businessName': businessName,
    'cloudBackupEnabled': cloudBackupEnabled,
    'customerFacingEnabled': customerFacingEnabled,
    'activeVehicleIds': activeVehicleIds,
  };

  factory UserProfileRecord.fromMap(Map<dynamic, dynamic> map) {
    final role = _enumByName(UserRole.values, map['role']) ?? UserRole.owner;
    return UserProfileRecord(
      id: _string(map['id'], fallback: 'local-owner'),
      name: _string(map['name'], fallback: 'Owner'),
      type:
          _enumByName(UserProfileType.values, map['type']) ??
          UserProfileType.contractor,
      role: role,
      permissions: _permissionsForRole(role)
        ..addAll(_permissionSet(map['permissions'])),
      businessName: _string(map['businessName']),
      cloudBackupEnabled: map['cloudBackupEnabled'] == true,
      customerFacingEnabled: map['customerFacingEnabled'] == true,
      activeVehicleIds: _stringList(map['activeVehicleIds']),
    );
  }

  static UserProfileRecord starterContractor() {
    return UserProfileRecord(
      id: 'local-owner',
      name: 'Owner',
      type: UserProfileType.contractor,
      role: UserRole.owner,
      permissions: _permissionsForRole(UserRole.owner),
      businessName: 'My Company',
      cloudBackupEnabled: false,
    );
  }
}

Set<UserPermission> permissionsForRole(UserRole role) =>
    Set.unmodifiable(_permissionsForRole(role));

Set<UserPermission> _permissionsForRole(UserRole role) {
  return switch (role) {
    UserRole.owner => UserPermission.values.toSet(),
    UserRole.admin => {
      UserPermission.manageVehicles,
      UserPermission.manageJobs,
      UserPermission.createInvoices,
      UserPermission.approveInvoices,
      UserPermission.viewFinancials,
      UserPermission.manageInventory,
      UserPermission.recordMileage,
      UserPermission.recordExpenses,
    },
    UserRole.manager => {
      UserPermission.manageJobs,
      UserPermission.createInvoices,
      UserPermission.manageInventory,
      UserPermission.recordMileage,
      UserPermission.recordExpenses,
    },
    UserRole.helper => {
      UserPermission.recordMileage,
      UserPermission.recordExpenses,
      UserPermission.manageInventory,
    },
    UserRole.viewer => {UserPermission.viewOnly},
  };
}

Set<UserPermission> _permissionSet(Object? value) {
  if (value is! Iterable) return {};
  return value
      .whereType<String>()
      .map((name) => _enumByName(UserPermission.values, name))
      .whereType<UserPermission>()
      .toSet();
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

List<String> _stringList(Object? value) {
  if (value is! Iterable) return const [];
  return value
      .whereType<String>()
      .where((item) => item.trim().isNotEmpty)
      .toList();
}
