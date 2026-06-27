import '../profiles/user_profile_models.dart';
import '../state/app_state.dart';

enum OperationalCompanyMode {
  solo('Solo operator'),
  companyOwner('Company owner'),
  companyMember('Company member'),
  customerPortal('Customer portal');

  const OperationalCompanyMode(this.label);

  final String label;
}

enum OperationalDashboardMode {
  gigDriver('Gig driver'),
  soloContractor('Solo contractor'),
  fleetOwner('Fleet owner'),
  employee('Employee'),
  customer('Customer');

  const OperationalDashboardMode(this.label);

  final String label;
}

enum OperationalMileageMode {
  manual('Manual mileage'),
  workday('Workday tracking'),
  employeeShift('Employee shift'),
  fleetReview('Fleet review'),
  customerHidden('Not shown');

  const OperationalMileageMode(this.label);

  final String label;
}

enum OperationalSyncMode {
  localOnly('Local only'),
  firebaseBackup('Firebase backup'),
  companySync('Company sync');

  const OperationalSyncMode(this.label);

  final String label;
}

class ActiveOperationalContext {
  const ActiveOperationalContext({
    required this.userProfileId,
    required this.userName,
    required this.profileType,
    required this.role,
    required this.permissions,
    required this.companyMode,
    required this.dashboardMode,
    required this.mileageMode,
    required this.syncMode,
    required this.workProfileId,
    required this.workProfileName,
    required this.activeVehicleId,
    required this.activeVehicleLabel,
    required this.activeVehicleUsage,
    required this.updatedAt,
    this.companyId = '',
    this.companyName = '',
  });

  final String userProfileId;
  final String userName;
  final UserProfileType profileType;
  final UserRole role;
  final Set<UserPermission> permissions;
  final OperationalCompanyMode companyMode;
  final OperationalDashboardMode dashboardMode;
  final OperationalMileageMode mileageMode;
  final OperationalSyncMode syncMode;
  final String workProfileId;
  final String workProfileName;
  final String activeVehicleId;
  final String activeVehicleLabel;
  final VehicleUsage activeVehicleUsage;
  final DateTime updatedAt;
  final String companyId;
  final String companyName;

  bool can(UserPermission permission) {
    if (role == UserRole.owner) return true;
    return permissions.contains(permission);
  }

  bool get showsMileage =>
      mileageMode != OperationalMileageMode.customerHidden &&
      can(UserPermission.recordMileage);

  bool get isContractorDashboard =>
      dashboardMode == OperationalDashboardMode.soloContractor ||
      dashboardMode == OperationalDashboardMode.fleetOwner;

  bool get isFleetContext =>
      companyMode == OperationalCompanyMode.companyOwner ||
      dashboardMode == OperationalDashboardMode.fleetOwner;

  bool get isEmployeeContext =>
      companyMode == OperationalCompanyMode.companyMember ||
      dashboardMode == OperationalDashboardMode.employee;

  ActiveOperationalContext copyWith({
    String? userProfileId,
    String? userName,
    UserProfileType? profileType,
    UserRole? role,
    Set<UserPermission>? permissions,
    OperationalCompanyMode? companyMode,
    OperationalDashboardMode? dashboardMode,
    OperationalMileageMode? mileageMode,
    OperationalSyncMode? syncMode,
    String? workProfileId,
    String? workProfileName,
    String? activeVehicleId,
    String? activeVehicleLabel,
    VehicleUsage? activeVehicleUsage,
    DateTime? updatedAt,
    String? companyId,
    String? companyName,
  }) {
    return ActiveOperationalContext(
      userProfileId: userProfileId ?? this.userProfileId,
      userName: userName ?? this.userName,
      profileType: profileType ?? this.profileType,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      companyMode: companyMode ?? this.companyMode,
      dashboardMode: dashboardMode ?? this.dashboardMode,
      mileageMode: mileageMode ?? this.mileageMode,
      syncMode: syncMode ?? this.syncMode,
      workProfileId: workProfileId ?? this.workProfileId,
      workProfileName: workProfileName ?? this.workProfileName,
      activeVehicleId: activeVehicleId ?? this.activeVehicleId,
      activeVehicleLabel: activeVehicleLabel ?? this.activeVehicleLabel,
      activeVehicleUsage: activeVehicleUsage ?? this.activeVehicleUsage,
      updatedAt: updatedAt ?? this.updatedAt,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userProfileId': userProfileId,
      'userName': userName,
      'profileType': profileType.name,
      'role': role.name,
      'permissions': permissions.map((permission) => permission.name).toList(),
      'companyMode': companyMode.name,
      'dashboardMode': dashboardMode.name,
      'mileageMode': mileageMode.name,
      'syncMode': syncMode.name,
      'workProfileId': workProfileId,
      'workProfileName': workProfileName,
      'activeVehicleId': activeVehicleId,
      'activeVehicleLabel': activeVehicleLabel,
      'activeVehicleUsage': activeVehicleUsage.name,
      'updatedAt': updatedAt.toIso8601String(),
      'companyId': companyId,
      'companyName': companyName,
    };
  }

  factory ActiveOperationalContext.fromMap(Map<dynamic, dynamic> map) {
    final role = _enumByName(UserRole.values, map['role']) ?? UserRole.owner;
    return ActiveOperationalContext(
      userProfileId: _string(map['userProfileId'], fallback: 'local-owner'),
      userName: _string(map['userName'], fallback: 'Owner'),
      profileType:
          _enumByName(UserProfileType.values, map['profileType']) ??
          UserProfileType.contractor,
      role: role,
      permissions: _permissionSet(map['permissions'], role),
      companyMode:
          _enumByName(OperationalCompanyMode.values, map['companyMode']) ??
          _companyModeForRole(role),
      dashboardMode:
          _enumByName(OperationalDashboardMode.values, map['dashboardMode']) ??
          _dashboardModeFor(role, UserProfileType.contractor),
      mileageMode:
          _enumByName(OperationalMileageMode.values, map['mileageMode']) ??
          _mileageModeFor(role, UserProfileType.contractor),
      syncMode:
          _enumByName(OperationalSyncMode.values, map['syncMode']) ??
          OperationalSyncMode.localOnly,
      workProfileId: _string(map['workProfileId'], fallback: 'main-work'),
      workProfileName: _string(map['workProfileName'], fallback: 'Main Work'),
      activeVehicleId: _string(
        map['activeVehicleId'],
        fallback: 'work_truck_1',
      ),
      activeVehicleLabel: _string(
        map['activeVehicleLabel'],
        fallback: 'Work Truck 1',
      ),
      activeVehicleUsage:
          _enumByName(VehicleUsage.values, map['activeVehicleUsage']) ??
          VehicleUsage.businessPersonal,
      updatedAt: DateTime.tryParse(_string(map['updatedAt'])) ?? DateTime.now(),
      companyId: _string(map['companyId']),
      companyName: _string(map['companyName']),
    );
  }

  factory ActiveOperationalContext.fromProfile({
    required UserProfileRecord profile,
    required String activeVehicleId,
    required String activeVehicleLabel,
    required VehicleUsage activeVehicleUsage,
    DateTime? updatedAt,
  }) {
    return ActiveOperationalContext(
      userProfileId: profile.id,
      userName: profile.name,
      profileType: profile.type,
      role: profile.role,
      permissions: Set<UserPermission>.from(profile.permissions),
      companyMode: _companyModeForRole(profile.role),
      dashboardMode: _dashboardModeFor(profile.role, profile.type),
      mileageMode: _mileageModeFor(profile.role, profile.type),
      syncMode: profile.cloudBackupEnabled
          ? OperationalSyncMode.firebaseBackup
          : OperationalSyncMode.localOnly,
      workProfileId: profile.type.name,
      workProfileName: profile.type.label,
      activeVehicleId: activeVehicleId,
      activeVehicleLabel: activeVehicleLabel,
      activeVehicleUsage: activeVehicleUsage,
      updatedAt: updatedAt ?? DateTime.now(),
      companyId: profile.businessName.trim().isEmpty ? '' : profile.id,
      companyName: profile.businessName,
    );
  }
}

OperationalDashboardMode _dashboardModeFor(
  UserRole role,
  UserProfileType profileType,
) {
  if (profileType == UserProfileType.customer) {
    return OperationalDashboardMode.customer;
  }
  if (role == UserRole.helper ||
      role == UserRole.technician ||
      role == UserRole.leadTechnician ||
      role == UserRole.driver ||
      role == UserRole.customerPortal ||
      role == UserRole.viewer) {
    return OperationalDashboardMode.employee;
  }
  if (profileType == UserProfileType.driver) {
    return OperationalDashboardMode.gigDriver;
  }
  if (role == UserRole.owner) {
    return OperationalDashboardMode.soloContractor;
  }
  if (role == UserRole.admin ||
      role == UserRole.officeManager ||
      role == UserRole.dispatcher ||
      role == UserRole.fieldManager ||
      role == UserRole.manager ||
      role == UserRole.inventoryClerk ||
      role == UserRole.bookkeeper) {
    return OperationalDashboardMode.fleetOwner;
  }
  return OperationalDashboardMode.employee;
}

OperationalMileageMode _mileageModeFor(
  UserRole role,
  UserProfileType profileType,
) {
  if (profileType == UserProfileType.customer) {
    return OperationalMileageMode.customerHidden;
  }
  if (role == UserRole.helper ||
      role == UserRole.technician ||
      role == UserRole.leadTechnician ||
      role == UserRole.driver) {
    return OperationalMileageMode.employeeShift;
  }
  if (role == UserRole.viewer ||
      role == UserRole.officeManager ||
      role == UserRole.dispatcher ||
      role == UserRole.inventoryClerk ||
      role == UserRole.bookkeeper) {
    return OperationalMileageMode.fleetReview;
  }
  return OperationalMileageMode.workday;
}

OperationalCompanyMode _companyModeForRole(UserRole role) {
  return switch (role) {
    UserRole.owner => OperationalCompanyMode.solo,
    UserRole.admin ||
    UserRole.officeManager ||
    UserRole.dispatcher ||
    UserRole.fieldManager ||
    UserRole.manager ||
    UserRole.inventoryClerk ||
    UserRole.bookkeeper => OperationalCompanyMode.companyOwner,
    UserRole.helper ||
    UserRole.leadTechnician ||
    UserRole.technician ||
    UserRole.driver ||
    UserRole.customerPortal ||
    UserRole.viewer => OperationalCompanyMode.companyMember,
  };
}

Set<UserPermission> _permissionSet(Object? value, UserRole role) {
  final permissions = permissionsForRole(role).toSet();
  if (value is Iterable) {
    permissions.addAll(
      value
          .whereType<String>()
          .map((name) => _enumByName(UserPermission.values, name))
          .whereType<UserPermission>(),
    );
  }
  return permissions;
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
