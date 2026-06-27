enum UserRole {
  owner('Owner'),
  admin('Admin'),
  officeManager('Office Manager'),
  dispatcher('Dispatcher'),
  fieldManager('Field Manager'),
  leadTechnician('Lead Technician'),
  technician('Technician'),
  manager('Manager'),
  helper('Helper'),
  driver('Driver'),
  inventoryClerk('Inventory Clerk'),
  bookkeeper('Bookkeeper'),
  customerPortal('Customer Portal'),
  viewer('Viewer');

  const UserRole(this.label);

  final String label;
}

enum PermissionGroup {
  company('Company and admin'),
  vehiclesMileage('Vehicles and mileage'),
  jobsSchedule('Jobs and schedule'),
  invoicesEstimates('Invoices and estimates'),
  expensesReceipts('Expenses and receipts'),
  inventoryMaterials('Inventory and materials'),
  maintenance('Maintenance'),
  reportsExports('Reports and export'),
  customerPortal('Customer portal');

  const PermissionGroup(this.label);

  final String label;
}

enum UserPermission {
  manageProfiles('Manage profiles', PermissionGroup.company),
  manageCompanyProfile('Manage company profile', PermissionGroup.company),
  inviteEmployees('Invite employees', PermissionGroup.company),
  manageRoles('Manage roles and permissions', PermissionGroup.company),
  viewAuditLog('View audit log', PermissionGroup.company),
  manageCloudSync('Manage cloud sync', PermissionGroup.company),
  manageBilling('Manage billing', PermissionGroup.company),
  viewCompanySettings('View company settings', PermissionGroup.company),
  viewOnly('View only', PermissionGroup.company),
  manageVehicles('Manage vehicles', PermissionGroup.vehiclesMileage),
  viewAssignedVehicles(
    'View assigned vehicles',
    PermissionGroup.vehiclesMileage,
  ),
  viewAllVehicles('View all vehicles', PermissionGroup.vehiclesMileage),
  editVehicleProfiles('Edit vehicle profiles', PermissionGroup.vehiclesMileage),
  assignVehicles('Assign vehicles', PermissionGroup.vehiclesMileage),
  recordMileage('Record mileage', PermissionGroup.vehiclesMileage),
  startOwnMileageSession(
    'Start own mileage session',
    PermissionGroup.vehiclesMileage,
  ),
  editOwnMileage('Edit own mileage', PermissionGroup.vehiclesMileage),
  editTeamMileage('Edit team mileage', PermissionGroup.vehiclesMileage),
  viewFleetMileageReports(
    'View fleet mileage reports',
    PermissionGroup.vehiclesMileage,
  ),
  manageJobs('Manage jobs', PermissionGroup.jobsSchedule),
  viewAssignedJobs('View assigned jobs', PermissionGroup.jobsSchedule),
  viewAllJobs('View all jobs', PermissionGroup.jobsSchedule),
  createJobs('Create jobs', PermissionGroup.jobsSchedule),
  editJobs('Edit jobs', PermissionGroup.jobsSchedule),
  assignJobs('Assign jobs', PermissionGroup.jobsSchedule),
  closeJobs('Close jobs', PermissionGroup.jobsSchedule),
  viewJobProfit('View job profit', PermissionGroup.jobsSchedule),
  manageSchedule('Manage schedule', PermissionGroup.jobsSchedule),
  createInvoices('Create invoices', PermissionGroup.invoicesEstimates),
  approveInvoices('Approve invoices', PermissionGroup.invoicesEstimates),
  createEstimates('Create estimates', PermissionGroup.invoicesEstimates),
  sendEstimates('Send estimates', PermissionGroup.invoicesEstimates),
  approveEstimates('Approve estimates', PermissionGroup.invoicesEstimates),
  sendInvoices('Send invoices', PermissionGroup.invoicesEstimates),
  recordPayments('Record payments', PermissionGroup.invoicesEstimates),
  viewUnpaidBalances('View unpaid balances', PermissionGroup.invoicesEstimates),
  editInvoiceTemplates(
    'Edit invoice templates',
    PermissionGroup.invoicesEstimates,
  ),
  viewOwnExpenses('View own expenses', PermissionGroup.expensesReceipts),
  addOwnExpenses('Add own expenses', PermissionGroup.expensesReceipts),
  uploadOwnReceipts('Upload own receipts', PermissionGroup.expensesReceipts),
  editOwnExpenses('Edit own expenses', PermissionGroup.expensesReceipts),
  deleteOwnExpenses('Delete own expenses', PermissionGroup.expensesReceipts),
  viewTeamExpenses('View team expenses', PermissionGroup.expensesReceipts),
  addTeamExpenses('Add expenses for others', PermissionGroup.expensesReceipts),
  editTeamExpenses('Edit team expenses', PermissionGroup.expensesReceipts),
  deleteTeamExpenses('Delete team expenses', PermissionGroup.expensesReceipts),
  approveExpenses('Approve expenses', PermissionGroup.expensesReceipts),
  viewOwnerOnlyExpenses(
    'View owner-only expenses',
    PermissionGroup.expensesReceipts,
  ),
  exportExpenseRecords(
    'Export expense records',
    PermissionGroup.expensesReceipts,
  ),
  manageReceiptParsing(
    'Manage receipt parsing',
    PermissionGroup.expensesReceipts,
  ),
  recordPersonalExpenses(
    'Record personal expenses',
    PermissionGroup.expensesReceipts,
  ),
  manageExpenseReminders(
    'Manage expense reminders',
    PermissionGroup.expensesReceipts,
  ),
  viewExpenseRecaps('View expense recaps', PermissionGroup.expensesReceipts),
  manageExpenseSettings(
    'Manage expense settings',
    PermissionGroup.expensesReceipts,
  ),
  manageInventory('Manage inventory', PermissionGroup.inventoryMaterials),
  viewAssignedInventory(
    'View assigned inventory',
    PermissionGroup.inventoryMaterials,
  ),
  viewAllInventory('View all inventory', PermissionGroup.inventoryMaterials),
  addStock('Add stock', PermissionGroup.inventoryMaterials),
  useMaterials('Use materials', PermissionGroup.inventoryMaterials),
  transferMaterials('Transfer materials', PermissionGroup.inventoryMaterials),
  adjustInventoryCounts(
    'Adjust inventory counts',
    PermissionGroup.inventoryMaterials,
  ),
  manageTradePacks('Manage trade packs', PermissionGroup.inventoryMaterials),
  viewMaterialCostHistory(
    'View material cost history',
    PermissionGroup.inventoryMaterials,
  ),
  logMaintenance('Log maintenance', PermissionGroup.maintenance),
  viewAssignedMaintenance(
    'View assigned maintenance',
    PermissionGroup.maintenance,
  ),
  viewAllMaintenance('View all maintenance', PermissionGroup.maintenance),
  editMaintenanceRecords(
    'Edit maintenance records',
    PermissionGroup.maintenance,
  ),
  manageMaintenanceSchedules(
    'Manage maintenance schedules',
    PermissionGroup.maintenance,
  ),
  viewFinancials('View financials', PermissionGroup.reportsExports),
  viewOwnReports('View own reports', PermissionGroup.reportsExports),
  viewCompanyReports('View company reports', PermissionGroup.reportsExports),
  exportRecords('Export records', PermissionGroup.reportsExports),
  exportAuditPackets('Export audit packets', PermissionGroup.reportsExports),
  exportProofFiles('Export proof files', PermissionGroup.reportsExports),
  viewProfitLoss('View profit and loss', PermissionGroup.reportsExports),
  manageCustomerPortal(
    'Manage customer portal',
    PermissionGroup.customerPortal,
  ),
  createCustomerProfile(
    'Create customer profile',
    PermissionGroup.customerPortal,
  ),
  shareEstimates('Share estimates', PermissionGroup.customerPortal),
  shareInvoices('Share invoices', PermissionGroup.customerPortal),
  shareJobProgress('Share job progress', PermissionGroup.customerPortal),
  shareSelectedProof('Share selected proof', PermissionGroup.customerPortal),
  hidePrivateReceiptLines(
    'Hide private receipt lines',
    PermissionGroup.customerPortal,
  );

  const UserPermission(this.label, this.group);

  final String label;
  final PermissionGroup group;
}

class RolePermissionTemplate {
  const RolePermissionTemplate({
    required this.role,
    required this.summary,
    required this.permissions,
  });

  final UserRole role;
  final String summary;
  final Set<UserPermission> permissions;
}

extension UserRoleDetails on UserRole {
  String get summary => roleTemplateFor(this).summary;
}

Set<UserPermission> permissionsForRole(UserRole role) =>
    Set.unmodifiable(_permissionsForRole(role));

RolePermissionTemplate roleTemplateFor(UserRole role) {
  return RolePermissionTemplate(
    role: role,
    summary: _roleSummary(role),
    permissions: _permissionsForRole(role),
  );
}

List<RolePermissionTemplate> get rolePermissionTemplates => [
  for (final role in UserRole.values) roleTemplateFor(role),
];

List<UserPermission> permissionsForGroup(PermissionGroup group) {
  return [
    for (final permission in UserPermission.values)
      if (permission.group == group) permission,
  ];
}

Set<UserPermission> _permissionsForRole(UserRole role) {
  return switch (role) {
    UserRole.owner => UserPermission.values.toSet(),
    UserRole.admin => _adminPermissions,
    UserRole.officeManager => _officeManagerPermissions,
    UserRole.dispatcher => _dispatcherPermissions,
    UserRole.fieldManager => _fieldManagerPermissions,
    UserRole.leadTechnician => _leadTechnicianPermissions,
    UserRole.technician => _technicianPermissions,
    UserRole.manager => _legacyManagerPermissions,
    UserRole.helper => _helperPermissions,
    UserRole.driver => _driverPermissions,
    UserRole.inventoryClerk => _inventoryClerkPermissions,
    UserRole.bookkeeper => _bookkeeperPermissions,
    UserRole.customerPortal => _customerPortalPermissions,
    UserRole.viewer => {UserPermission.viewOnly},
  };
}

const _adminPermissions = {
  UserPermission.manageProfiles,
  UserPermission.manageCompanyProfile,
  UserPermission.inviteEmployees,
  UserPermission.manageRoles,
  UserPermission.viewAuditLog,
  UserPermission.manageCloudSync,
  UserPermission.viewCompanySettings,
  UserPermission.manageVehicles,
  UserPermission.viewAllVehicles,
  UserPermission.manageJobs,
  UserPermission.viewAllJobs,
  UserPermission.createJobs,
  UserPermission.editJobs,
  UserPermission.assignJobs,
  UserPermission.closeJobs,
  UserPermission.createInvoices,
  UserPermission.approveInvoices,
  UserPermission.createEstimates,
  UserPermission.sendEstimates,
  UserPermission.approveEstimates,
  UserPermission.sendInvoices,
  UserPermission.recordPayments,
  UserPermission.viewUnpaidBalances,
  UserPermission.viewFinancials,
  UserPermission.manageInventory,
  UserPermission.viewAllInventory,
  UserPermission.recordMileage,
  UserPermission.viewOwnExpenses,
  UserPermission.addOwnExpenses,
  UserPermission.uploadOwnReceipts,
  UserPermission.viewTeamExpenses,
  UserPermission.approveExpenses,
  UserPermission.logMaintenance,
  UserPermission.viewAllMaintenance,
  UserPermission.viewCompanyReports,
  UserPermission.exportRecords,
  UserPermission.manageCustomerPortal,
};

const _officeManagerPermissions = {
  UserPermission.viewCompanySettings,
  UserPermission.viewAllJobs,
  UserPermission.manageSchedule,
  UserPermission.createJobs,
  UserPermission.editJobs,
  UserPermission.createEstimates,
  UserPermission.sendEstimates,
  UserPermission.createInvoices,
  UserPermission.sendInvoices,
  UserPermission.recordPayments,
  UserPermission.viewUnpaidBalances,
  UserPermission.viewTeamExpenses,
  UserPermission.addTeamExpenses,
  UserPermission.approveExpenses,
  UserPermission.viewCompanyReports,
  UserPermission.exportRecords,
  UserPermission.manageCustomerPortal,
  UserPermission.shareEstimates,
  UserPermission.shareInvoices,
  UserPermission.shareJobProgress,
};

const _dispatcherPermissions = {
  UserPermission.viewAssignedVehicles,
  UserPermission.viewAllVehicles,
  UserPermission.viewAssignedJobs,
  UserPermission.viewAllJobs,
  UserPermission.createJobs,
  UserPermission.editJobs,
  UserPermission.assignJobs,
  UserPermission.manageSchedule,
  UserPermission.viewAssignedInventory,
  UserPermission.viewAllMaintenance,
};

const _fieldManagerPermissions = {
  UserPermission.viewAssignedVehicles,
  UserPermission.viewAllVehicles,
  UserPermission.recordMileage,
  UserPermission.startOwnMileageSession,
  UserPermission.editOwnMileage,
  UserPermission.editTeamMileage,
  UserPermission.viewAssignedJobs,
  UserPermission.viewAllJobs,
  UserPermission.createJobs,
  UserPermission.editJobs,
  UserPermission.assignJobs,
  UserPermission.closeJobs,
  UserPermission.createEstimates,
  UserPermission.createInvoices,
  UserPermission.viewTeamExpenses,
  UserPermission.addTeamExpenses,
  UserPermission.editTeamExpenses,
  UserPermission.manageInventory,
  UserPermission.viewAllInventory,
  UserPermission.addStock,
  UserPermission.useMaterials,
  UserPermission.transferMaterials,
  UserPermission.logMaintenance,
  UserPermission.viewAllMaintenance,
};

const _leadTechnicianPermissions = {
  UserPermission.viewAssignedVehicles,
  UserPermission.recordMileage,
  UserPermission.startOwnMileageSession,
  UserPermission.editOwnMileage,
  UserPermission.viewAssignedJobs,
  UserPermission.editJobs,
  UserPermission.closeJobs,
  UserPermission.createEstimates,
  UserPermission.viewOwnExpenses,
  UserPermission.addOwnExpenses,
  UserPermission.uploadOwnReceipts,
  UserPermission.editOwnExpenses,
  UserPermission.viewAssignedInventory,
  UserPermission.addStock,
  UserPermission.useMaterials,
  UserPermission.transferMaterials,
  UserPermission.logMaintenance,
  UserPermission.viewAssignedMaintenance,
  UserPermission.shareJobProgress,
  UserPermission.shareSelectedProof,
};

const _technicianPermissions = {
  UserPermission.viewAssignedVehicles,
  UserPermission.recordMileage,
  UserPermission.startOwnMileageSession,
  UserPermission.editOwnMileage,
  UserPermission.viewAssignedJobs,
  UserPermission.editJobs,
  UserPermission.viewOwnExpenses,
  UserPermission.addOwnExpenses,
  UserPermission.uploadOwnReceipts,
  UserPermission.editOwnExpenses,
  UserPermission.viewAssignedInventory,
  UserPermission.useMaterials,
  UserPermission.logMaintenance,
  UserPermission.viewAssignedMaintenance,
  UserPermission.shareJobProgress,
};

const _legacyManagerPermissions = {
  UserPermission.manageJobs,
  UserPermission.viewAllJobs,
  UserPermission.createJobs,
  UserPermission.editJobs,
  UserPermission.assignJobs,
  UserPermission.createInvoices,
  UserPermission.manageInventory,
  UserPermission.viewAllInventory,
  UserPermission.recordMileage,
  UserPermission.viewOwnExpenses,
  UserPermission.addOwnExpenses,
  UserPermission.uploadOwnReceipts,
  UserPermission.viewTeamExpenses,
  UserPermission.logMaintenance,
  UserPermission.viewAllMaintenance,
};

const _helperPermissions = {
  UserPermission.viewAssignedVehicles,
  UserPermission.recordMileage,
  UserPermission.startOwnMileageSession,
  UserPermission.viewAssignedJobs,
  UserPermission.viewOwnExpenses,
  UserPermission.addOwnExpenses,
  UserPermission.uploadOwnReceipts,
  UserPermission.viewAssignedInventory,
  UserPermission.useMaterials,
  UserPermission.logMaintenance,
  UserPermission.viewAssignedMaintenance,
};

const _driverPermissions = {
  UserPermission.viewAssignedVehicles,
  UserPermission.recordMileage,
  UserPermission.startOwnMileageSession,
  UserPermission.editOwnMileage,
  UserPermission.viewOwnExpenses,
  UserPermission.addOwnExpenses,
  UserPermission.uploadOwnReceipts,
  UserPermission.viewOwnReports,
  UserPermission.logMaintenance,
  UserPermission.viewAssignedMaintenance,
};

const _inventoryClerkPermissions = {
  UserPermission.viewAssignedVehicles,
  UserPermission.viewAllVehicles,
  UserPermission.manageInventory,
  UserPermission.viewAllInventory,
  UserPermission.addStock,
  UserPermission.transferMaterials,
  UserPermission.adjustInventoryCounts,
  UserPermission.manageTradePacks,
  UserPermission.viewMaterialCostHistory,
  UserPermission.exportRecords,
};

const _bookkeeperPermissions = {
  UserPermission.viewAllJobs,
  UserPermission.createInvoices,
  UserPermission.sendInvoices,
  UserPermission.recordPayments,
  UserPermission.viewUnpaidBalances,
  UserPermission.viewFinancials,
  UserPermission.viewTeamExpenses,
  UserPermission.addTeamExpenses,
  UserPermission.editTeamExpenses,
  UserPermission.approveExpenses,
  UserPermission.exportExpenseRecords,
  UserPermission.viewCompanyReports,
  UserPermission.exportRecords,
  UserPermission.exportAuditPackets,
  UserPermission.exportProofFiles,
  UserPermission.viewProfitLoss,
};

const _customerPortalPermissions = {
  UserPermission.viewOnly,
  UserPermission.shareJobProgress,
  UserPermission.shareSelectedProof,
};

String _roleSummary(UserRole role) {
  return switch (role) {
    UserRole.owner => 'Full account owner with every permission.',
    UserRole.admin => 'Trusted operator for company setup and daily control.',
    UserRole.officeManager =>
      'Office workflow for schedules, billing, and reports.',
    UserRole.dispatcher => 'Assigns work and watches the operating schedule.',
    UserRole.fieldManager =>
      'Field supervisor for jobs, crews, vehicles, and materials.',
    UserRole.leadTechnician =>
      'Senior field user with job and material responsibility.',
    UserRole.technician =>
      'Field user for assigned jobs, mileage, and records.',
    UserRole.manager => 'Legacy manager template kept for existing profiles.',
    UserRole.helper => 'Limited field user for assigned work only.',
    UserRole.driver => 'Driver-focused mileage, receipts, and vehicle records.',
    UserRole.inventoryClerk =>
      'Inventory user for stock, transfers, counts, and trade packs.',
    UserRole.bookkeeper => 'Financial records, invoices, expenses, and export.',
    UserRole.customerPortal => 'Customer-facing access only.',
    UserRole.viewer => 'Read-only starting point.',
  };
}
