import '../../shared/profiles/user_profile_models.dart';
import 'employee_permission_catalog.dart';
import 'employee_permission_models.dart';

Set<String> structuredPermissionsForRoleName(String roleName) {
  final role = _roleByName(roleName) ?? UserRole.viewer;
  final permissions = permissionsForRole(role);
  final enabled = <String>{};
  for (final area in employeePermissionCatalog) {
    for (final item in area.items) {
      if (area.key == 'admin' && item.key == 'companyProfile') {
        enabled.add(permissionKey(area, item, PermissionVerb.view, 'own'));
      }
      final allow = _roleCanTouchArea(permissions, area.key);
      if (!allow) {
        continue;
      }
      for (final verb in item.verbs) {
        enabled.add(permissionKey(area, item, verb, 'own'));
        if (_roleCanTouchOthers(role, verb, area.highImpact)) {
          enabled.add(permissionKey(area, item, verb, 'other'));
        }
      }
    }
  }
  return enabled;
}

UserRole? _roleByName(String roleName) {
  for (final role in UserRole.values) {
    if (role.name == roleName) {
      return role;
    }
  }
  return null;
}

bool _roleCanTouchArea(Set<UserPermission> permissions, String area) {
  return switch (area) {
    'admin' => permissions.any((p) => p.group == PermissionGroup.company),
    'employees' => permissions.contains(UserPermission.manageProfiles),
    'jobs' => permissions.any((p) => p.group == PermissionGroup.jobsSchedule),
    'estimates' || 'invoices' || 'payments' => permissions.any(
      (p) => p.group == PermissionGroup.invoicesEstimates,
    ),
    'expenses' || 'receipts' => permissions.any(
      (p) => p.group == PermissionGroup.expensesReceipts,
    ),
    'inventory' => permissions.any(
      (p) => p.group == PermissionGroup.inventoryMaterials,
    ),
    'vehicles' => permissions.any(
      (p) => p.group == PermissionGroup.vehiclesMileage,
    ),
    'maintenance' => permissions.any(
      (p) => p.group == PermissionGroup.maintenance,
    ),
    'calendar' => permissions.any(
      (p) =>
          p.group == PermissionGroup.jobsSchedule ||
          p.group == PermissionGroup.vehiclesMileage,
    ),
    'reports' => permissions.any(
      (p) => p.group == PermissionGroup.reportsExports,
    ),
    'customerPortal' => permissions.any(
      (p) => p.group == PermissionGroup.customerPortal,
    ),
    _ => false,
  };
}

bool _roleCanTouchOthers(UserRole role, PermissionVerb verb, bool highImpact) {
  if (role == UserRole.owner || role == UserRole.admin) {
    return true;
  }
  if (verb == PermissionVerb.delete || verb == PermissionVerb.manage) {
    return false;
  }
  return switch (role) {
    UserRole.officeManager || UserRole.fieldManager || UserRole.manager => true,
    UserRole.bookkeeper => !highImpact,
    UserRole.dispatcher =>
      verb == PermissionVerb.view || verb == PermissionVerb.assign,
    UserRole.leadTechnician =>
      verb == PermissionVerb.view || verb == PermissionVerb.create,
    _ => false,
  };
}
