import '../../shared/profiles/user_profile_models.dart';

enum PermissionVerb {
  view('View'),
  create('Create'),
  edit('Edit'),
  delete('Delete'),
  share('Share'),
  export('Export'),
  manage('Manage'),
  assign('Assign'),
  deactivate('Deactivate');

  const PermissionVerb(this.label);

  final String label;
}

const corePermissionVerbs = [
  PermissionVerb.view,
  PermissionVerb.create,
  PermissionVerb.edit,
];
const fullPermissionVerbs = [
  PermissionVerb.view,
  PermissionVerb.create,
  PermissionVerb.edit,
  PermissionVerb.delete,
];
const sharePermissionVerbs = [
  PermissionVerb.view,
  PermissionVerb.create,
  PermissionVerb.edit,
  PermissionVerb.share,
  PermissionVerb.export,
];

class EmployeePermissionArea {
  const EmployeePermissionArea({
    required this.key,
    required this.title,
    required this.summary,
    required this.items,
    this.highImpact = false,
  });

  final String key;
  final String title;
  final String summary;
  final List<EmployeePermissionItem> items;
  final bool highImpact;

  List<EmployeePermissionGrant> get permissions {
    return [
      for (final item in items)
        for (final verb in item.verbs) ...[
          EmployeePermissionGrant(
            key: permissionKey(this, item, verb, 'own'),
            resource: item.title,
          ),
          EmployeePermissionGrant(
            key: permissionKey(this, item, verb, 'other'),
            resource: item.title,
          ),
        ],
    ];
  }
}

class EmployeePermissionItem {
  const EmployeePermissionItem({
    required this.key,
    required this.title,
    required this.description,
    required this.verbs,
    this.highImpact = false,
  });

  final String key;
  final String title;
  final String description;
  final List<PermissionVerb> verbs;
  final bool highImpact;
}

class EmployeePermissionGrant {
  const EmployeePermissionGrant({required this.key, required this.resource});

  final String key;
  final String resource;
}

String permissionKey(
  EmployeePermissionArea area,
  EmployeePermissionItem item,
  PermissionVerb verb,
  String scope,
) {
  return '${area.key}.${item.key}.$scope.${verb.name}';
}

String permissionSentence(
  String employeeName,
  EmployeePermissionItem item,
  PermissionVerb verb,
) {
  return '${verb.label} ${item.title.toLowerCase()}';
}

String otherEmployeeSentence(EmployeePermissionItem item, PermissionVerb verb) {
  return 'Can they ${verb.label.toLowerCase()} other employees\' ${item.title.toLowerCase()}?';
}

String employeeRoleLabel(String roleName) {
  for (final role in UserRole.values) {
    if (role.name == roleName) return role.label;
  }
  if (roleName.trim().isEmpty) return 'Custom';
  return roleName
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
      .trim();
}

List<String> get employeePermissionRoleNames => [
  UserRole.admin.name,
  UserRole.officeManager.name,
  UserRole.dispatcher.name,
  UserRole.fieldManager.name,
  UserRole.leadTechnician.name,
  UserRole.technician.name,
  UserRole.helper.name,
  UserRole.driver.name,
  UserRole.inventoryClerk.name,
  UserRole.bookkeeper.name,
  'projectManager',
  'fleetManager',
  'hrPayroll',
  'custom',
];
