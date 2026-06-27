import 'user_permissions.dart';

export 'user_permissions.dart';

enum UserProfileType {
  contractor('Contractor'),
  driver('Driver'),
  customer('Customer');

  const UserProfileType(this.label);

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

  UserProfileRecord sanitized() {
    final safeRole = role;
    final safeType = type;
    final basePermissions = permissionsForRole(safeRole);
    final cleanedVehicles = <String>[];
    for (final vehicleId in activeVehicleIds) {
      final normalized = vehicleId.trim();
      if (normalized.isEmpty || cleanedVehicles.contains(normalized)) continue;
      cleanedVehicles.add(normalized);
    }
    return UserProfileRecord(
      id: id.trim().isEmpty ? 'local-owner' : id.trim(),
      name: name.trim().isEmpty ? 'Owner' : name.trim(),
      type: safeType,
      role: safeRole,
      permissions: {...basePermissions, ...permissions},
      businessName: businessName.trim(),
      cloudBackupEnabled: cloudBackupEnabled,
      customerFacingEnabled:
          safeType == UserProfileType.contractor && customerFacingEnabled,
      activeVehicleIds: cleanedVehicles,
    );
  }

  bool wasRepairedFrom(Map<dynamic, dynamic> source) {
    final repaired = sanitized().toMap();
    return _string(source['id'], fallback: 'local-owner') != repaired['id'] ||
        _string(source['name'], fallback: 'Owner') != repaired['name'] ||
        source['type'] != repaired['type'] ||
        source['role'] != repaired['role'] ||
        source['businessName'] != repaired['businessName'] ||
        source['cloudBackupEnabled'] != repaired['cloudBackupEnabled'] ||
        source['customerFacingEnabled'] != repaired['customerFacingEnabled'] ||
        !_sameStringList(
          _stringList(source['activeVehicleIds']),
          repaired['activeVehicleIds'] as List<String>,
        );
  }

  factory UserProfileRecord.fromMap(Map<dynamic, dynamic> map) {
    final role = _enumByName(UserRole.values, map['role']) ?? UserRole.owner;
    return UserProfileRecord(
      id: _string(map['id'], fallback: 'local-owner'),
      name: _string(map['name'], fallback: 'Owner'),
      type:
          _enumByName(UserProfileType.values, map['type']) ??
          UserProfileType.contractor,
      role: role,
      permissions: permissionsForRole(role).toSet()
        ..addAll(_permissionSet(map)),
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
      permissions: permissionsForRole(UserRole.owner),
      businessName: 'My Company',
      cloudBackupEnabled: false,
    );
  }
}

Set<UserPermission> _permissionSet(Map<dynamic, dynamic> map) {
  final value = map['permissions'];
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
  final items = <String>[];
  for (final item in value.whereType<String>()) {
    final normalized = item.trim();
    if (normalized.isEmpty || items.contains(normalized)) continue;
    items.add(normalized);
  }
  return items;
}

bool _sameStringList(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
