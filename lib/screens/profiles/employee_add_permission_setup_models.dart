import 'employee_permission_catalog.dart';
import 'employee_permission_models.dart';

part 'employee_add_permission_expense_group.dart';
part 'employee_add_permission_finance_group.dart';

enum AddPermissionAction {
  view('View'),
  create('Create'),
  edit('Edit');

  const AddPermissionAction(this.label);

  final String label;
}

enum AddCrewPreset { helper, technician, driver, office }

class AddCrewPermissionGroup {
  const AddCrewPermissionGroup({
    required this.title,
    required this.detail,
    required this.rules,
    this.helper = const AddPermissionPreset(),
    this.technician = const AddPermissionPreset(),
    this.driver = const AddPermissionPreset(),
    this.office = const AddPermissionPreset(),
  });

  final String title;
  final String detail;
  final List<AddPermissionRule> rules;
  final AddPermissionPreset helper;
  final AddPermissionPreset technician;
  final AddPermissionPreset driver;
  final AddPermissionPreset office;
}

class AddPermissionPreset {
  const AddPermissionPreset({this.own = const {}, this.other = const {}});

  final Set<AddPermissionAction> own;
  final Set<AddPermissionAction> other;
}

class AddPermissionRule {
  const AddPermissionRule(this.area, this.item, this.verbs);

  final String area;
  final String item;
  final List<PermissionVerb> verbs;

  String get title => _itemModel.title;

  String get description => _itemModel.description;

  bool hasScope(Set<String> enabled, String scope) {
    return verbs.any((verb) => enabled.contains(_key(verb, scope)));
  }

  bool hasAction(
    Set<String> enabled,
    String scope,
    AddPermissionAction action,
  ) {
    return verbsForAction(action).any(
      (verb) => verbs.contains(verb) && enabled.contains(_key(verb, scope)),
    );
  }

  void addAction(
    Set<String> enabled,
    String scope,
    AddPermissionAction action,
  ) {
    for (final verb in verbsForAction(action)) {
      if (!verbs.contains(verb)) continue;
      enabled.add(_key(verb, scope));
    }
  }

  void removeAction(
    Set<String> enabled,
    String scope,
    AddPermissionAction action,
  ) {
    for (final verb in verbsForAction(action)) {
      if (!verbs.contains(verb)) continue;
      enabled.remove(_key(verb, scope));
    }
  }

  void removeScope(
    Set<String> enabled,
    String scope,
    Map<String, Set<String>> roles,
    Map<String, Set<String>> employees,
  ) {
    for (final verb in verbs) {
      final key = _key(verb, scope);
      enabled.remove(key);
      roles.remove(key);
      employees.remove(key);
    }
  }

  void removeFrom(
    Set<String> enabled,
    Map<String, Set<String>> roles,
    Map<String, Set<String>> employees,
  ) {
    for (final verb in verbs) {
      final own = _key(verb, 'own');
      final other = _key(verb, 'other');
      enabled.remove(own);
      enabled.remove(other);
      roles.remove(own);
      roles.remove(other);
      employees.remove(own);
      employees.remove(other);
    }
  }

  String _key(PermissionVerb verb, String scope) {
    return permissionKey(_areaModel, _itemModel, verb, scope);
  }

  EmployeePermissionArea get _areaModel {
    return employeePermissionCatalog.firstWhere(
      (areaModel) => areaModel.key == area,
    );
  }

  EmployeePermissionItem get _itemModel {
    return _areaModel.items.firstWhere((itemModel) => itemModel.key == item);
  }
}

List<PermissionVerb> verbsForAction(AddPermissionAction action) {
  return switch (action) {
    AddPermissionAction.view => const [PermissionVerb.view],
    AddPermissionAction.create => const [PermissionVerb.create],
    AddPermissionAction.edit => const [
      PermissionVerb.edit,
      PermissionVerb.assign,
    ],
  };
}

const ownViewCreateEdit = {
  AddPermissionAction.view,
  AddPermissionAction.create,
  AddPermissionAction.edit,
};

const otherViewCreateEdit = {
  AddPermissionAction.view,
  AddPermissionAction.create,
  AddPermissionAction.edit,
};

const addPermissionGroups = [
  AddCrewPermissionGroup(
    title: 'Workday, Hours, and Calendar',
    detail:
        'Start the day, see schedule details, and record hours or daily work.',
    helper: AddPermissionPreset(own: ownViewCreateEdit),
    technician: AddPermissionPreset(own: ownViewCreateEdit),
    driver: AddPermissionPreset(own: ownViewCreateEdit),
    office: AddPermissionPreset(
      own: ownViewCreateEdit,
      other: otherViewCreateEdit,
    ),
    rules: [
      AddPermissionRule('calendar', 'calendarDays', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('calendar', 'pastCalendarDays', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('calendar', 'calendarSettings', [
        PermissionVerb.view,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('employees', 'employeeTimeCards', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
    ],
  ),
  AddCrewPermissionGroup(
    title: 'Assigned Jobs and Job Proof',
    detail:
        'Open assigned jobs, add notes, photos, proof, materials, and job hours.',
    helper: AddPermissionPreset(own: ownViewCreateEdit),
    technician: AddPermissionPreset(own: ownViewCreateEdit),
    office: AddPermissionPreset(
      own: ownViewCreateEdit,
      other: otherViewCreateEdit,
    ),
    rules: [
      AddPermissionRule('jobs', 'jobs', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('jobs', 'jobSchedule', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('jobs', 'jobEmployees', [
        PermissionVerb.view,
        PermissionVerb.assign,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('jobs', 'jobVehicles', [
        PermissionVerb.view,
        PermissionVerb.assign,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('jobs', 'jobExpenses', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('jobs', 'jobProof', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('jobs', 'jobMaterials', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('jobs', 'jobHours', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('jobs', 'jobProfit', [PermissionVerb.view]),
    ],
  ),
  AddCrewPermissionGroup(
    title: 'Vehicles and Mileage',
    detail: 'See assigned vehicles and record trips, mileage, and vehicle use.',
    helper: AddPermissionPreset(own: ownViewCreateEdit),
    technician: AddPermissionPreset(own: ownViewCreateEdit),
    driver: AddPermissionPreset(own: ownViewCreateEdit),
    office: AddPermissionPreset(
      own: ownViewCreateEdit,
      other: otherViewCreateEdit,
    ),
    rules: [
      AddPermissionRule('vehicles', 'vehicles', [PermissionVerb.view]),
      AddPermissionRule('vehicles', 'vehicleAssignments', [
        PermissionVerb.view,
      ]),
      AddPermissionRule('vehicles', 'mileageTrips', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('vehicles', 'fuelEconomy', [PermissionVerb.view]),
    ],
  ),
  _expensesAndReceiptsPermissionGroup,
  AddCrewPermissionGroup(
    title: 'Materials and Inventory',
    detail: 'Use materials, adjust counts, and move material between work.',
    technician: AddPermissionPreset(own: ownViewCreateEdit),
    office: AddPermissionPreset(
      own: ownViewCreateEdit,
      other: otherViewCreateEdit,
    ),
    rules: [
      AddPermissionRule('inventory', 'materials', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('inventory', 'stockCounts', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('inventory', 'materialTransfers', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('inventory', 'tradePacks', [
        PermissionVerb.view,
        PermissionVerb.create,
      ]),
      AddPermissionRule('inventory', 'materialCosts', [PermissionVerb.view]),
    ],
  ),
  AddCrewPermissionGroup(
    title: 'Maintenance and Repairs',
    detail:
        'Maintenance entries, repair records, service reminders, and maintenance cost recaps.',
    technician: AddPermissionPreset(own: ownViewCreateEdit),
    driver: AddPermissionPreset(own: ownViewCreateEdit),
    office: AddPermissionPreset(
      own: ownViewCreateEdit,
      other: otherViewCreateEdit,
    ),
    rules: [
      AddPermissionRule('maintenance', 'maintenanceEntries', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('maintenance', 'repairEntries', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('maintenance', 'maintenanceSchedule', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('maintenance', 'maintenanceCostRecap', [
        PermissionVerb.view,
      ]),
    ],
  ),
  _financePermissionGroup,
  AddCrewPermissionGroup(
    title: 'Employees and Crew Management',
    detail:
        'Employee profiles, pay information, vehicle assignment, and permissions.',
    office: AddPermissionPreset(
      own: ownViewCreateEdit,
      other: otherViewCreateEdit,
    ),
    rules: [
      AddPermissionRule('employees', 'employeeProfiles', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('employees', 'employeePayInfo', [PermissionVerb.view]),
      AddPermissionRule('employees', 'employeePayHistory', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('employees', 'employeeStatus', [
        PermissionVerb.view,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('employees', 'employeePermissions', [
        PermissionVerb.view,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('jobs', 'jobEmployees', [
        PermissionVerb.view,
        PermissionVerb.assign,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('jobs', 'jobVehicles', [
        PermissionVerb.view,
        PermissionVerb.assign,
        PermissionVerb.edit,
      ]),
    ],
  ),
  AddCrewPermissionGroup(
    title: 'Reports and Export',
    detail:
        'Financial recaps, employee recaps, vehicle recaps, and audit files.',
    office: AddPermissionPreset(
      own: {AddPermissionAction.view},
      other: {AddPermissionAction.view},
    ),
    rules: [
      AddPermissionRule('reports', 'financialRecaps', [
        PermissionVerb.view,
        PermissionVerb.export,
      ]),
      AddPermissionRule('reports', 'employeeRecaps', [
        PermissionVerb.view,
        PermissionVerb.export,
      ]),
      AddPermissionRule('reports', 'vehicleRecaps', [
        PermissionVerb.view,
        PermissionVerb.export,
      ]),
      AddPermissionRule('reports', 'auditExports', [
        PermissionVerb.view,
        PermissionVerb.export,
      ]),
    ],
  ),
  AddCrewPermissionGroup(
    title: 'Account Admin and Cloud',
    detail:
        'Company profile, employee invites, role templates, backup, and account-level controls.',
    office: AddPermissionPreset(
      own: {AddPermissionAction.view},
      other: {AddPermissionAction.view},
    ),
    rules: [
      AddPermissionRule('admin', 'companyProfile', [
        PermissionVerb.view,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('admin', 'employeeInvites', [
        PermissionVerb.view,
        PermissionVerb.create,
      ]),
      AddPermissionRule('admin', 'roleTemplates', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('admin', 'cloudBackup', [
        PermissionVerb.view,
        PermissionVerb.edit,
      ]),
    ],
  ),
  AddCrewPermissionGroup(
    title: 'Customer Portal',
    detail:
        'Customer profiles, job progress, shared proof files, and customer portal visibility.',
    office: AddPermissionPreset(
      own: ownViewCreateEdit,
      other: otherViewCreateEdit,
    ),
    rules: [
      AddPermissionRule('customerPortal', 'customerProfiles', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('customerPortal', 'customerJobProgress', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('customerPortal', 'customerProofFiles', [
        PermissionVerb.view,
        PermissionVerb.create,
        PermissionVerb.edit,
      ]),
      AddPermissionRule('customerPortal', 'portalSettings', [
        PermissionVerb.view,
        PermissionVerb.edit,
      ]),
    ],
  ),
];
