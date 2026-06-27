enum HostedSyncModule {
  mileage('mileage', 'Mileage', 'mileageRecords'),
  expenses('expenses', 'Expenses', 'expenses'),
  receiptProofs('receiptProofs', 'Receipt proof files', 'proofs'),
  jobs('jobs', 'Jobs', 'jobs'),
  estimates('estimates', 'Estimates', 'estimates'),
  invoices('invoices', 'Invoices', 'invoices'),
  inventoryItems('inventoryItems', 'Inventory items', 'inventoryItems'),
  inventoryTransactions(
    'inventoryTransactions',
    'Inventory transactions',
    'inventoryTransactions',
  ),
  maintenanceRecords(
    'maintenanceRecords',
    'Maintenance records',
    'maintenanceRecords',
  ),
  vehicles('vehicles', 'Vehicles', 'vehicles'),
  employeePermissions('employeePermissions', 'Employee permissions', 'members'),
  employeeInvites('employeeInvites', 'Employee invites', 'invites'),
  calendarTimeline('calendarTimeline', 'Calendar timeline', 'records'),
  customerPortal('customerPortal', 'Customer portal', 'customerPortal'),
  settings('settings', 'Settings', 'settings'),
  auditEvents('auditEvents', 'Audit events', 'auditEvents'),
  exports('exports', 'Exports', 'exports');

  const HostedSyncModule(this.id, this.label, this.collectionId);

  final String id;
  final String label;
  final String collectionId;
}

class HostedSyncScope {
  const HostedSyncScope._();

  static const List<HostedSyncModule> backupModules = [
    HostedSyncModule.mileage,
    HostedSyncModule.expenses,
    HostedSyncModule.receiptProofs,
    HostedSyncModule.jobs,
    HostedSyncModule.estimates,
    HostedSyncModule.invoices,
    HostedSyncModule.inventoryItems,
    HostedSyncModule.inventoryTransactions,
    HostedSyncModule.maintenanceRecords,
    HostedSyncModule.vehicles,
    HostedSyncModule.employeePermissions,
    HostedSyncModule.employeeInvites,
    HostedSyncModule.calendarTimeline,
    HostedSyncModule.customerPortal,
    HostedSyncModule.settings,
    HostedSyncModule.auditEvents,
    HostedSyncModule.exports,
  ];

  static const List<HostedSyncModule> proofEligibleModules = [
    HostedSyncModule.expenses,
    HostedSyncModule.jobs,
    HostedSyncModule.inventoryItems,
    HostedSyncModule.maintenanceRecords,
    HostedSyncModule.customerPortal,
  ];

  static const List<HostedSyncModule> ownerControlledModules = [
    HostedSyncModule.employeePermissions,
    HostedSyncModule.employeeInvites,
    HostedSyncModule.settings,
    HostedSyncModule.auditEvents,
    HostedSyncModule.exports,
  ];

  static List<String> get backupModuleIds {
    return [for (final module in backupModules) module.id];
  }

  static bool isBackupModule(String moduleId) {
    return backupModules.any((module) => module.id == moduleId);
  }
}
