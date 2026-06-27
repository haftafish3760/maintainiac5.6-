export const mockSeedProjectId = 'demo-maintainiac-rules-test';

export const mockOrg = Object.freeze({
  path: 'orgs/orgA',
  data: {
    ownerUid: 'ownerUid',
    name: 'Maintainiac Emulator Org',
    syncEnabled: true,
    storageMode: 'emulatorOnly',
    createdAt: 1,
    updatedAt: 1,
  },
});

export const mockMembers = Object.freeze([
  {
    path: 'orgs/orgA/members/ownerUid',
    data: {
      uid: 'ownerUid',
      orgId: 'orgA',
      status: 'active',
      role: 'owner',
      permissions: [
        'viewFinancials',
        'viewAuditLog',
        'viewAllExpenses',
        'manageVehicles',
        'editVehicleProfiles',
        'createJobs',
        'editJobs',
      ],
      allowedModules: ['expenses', 'admin', 'vehicles', 'jobs'],
      createdAt: 1,
      updatedAt: 1,
    },
  },
  {
    path: 'orgs/orgA/members/helperUid',
    data: {
      uid: 'helperUid',
      orgId: 'orgA',
      status: 'active',
      role: 'helper',
      permissions: ['recordExpenses', 'addOwnReceipts'],
      allowedModules: ['expenses', 'receipts'],
      createdAt: 1,
      updatedAt: 1,
    },
  },
]);

export const mockVehicle = Object.freeze({
  path: 'orgs/orgA/vehicles/truck1',
  data: {
    nickname: 'Truck 1',
    type: 'truck',
    status: 'active',
    assignedMemberIds: ['ownerUid'],
    createdByUid: 'ownerUid',
    updatedByUid: 'ownerUid',
    createdAt: 1,
    updatedAt: 1,
  },
});

export const mockSeedRecords = Object.freeze([
  mockOrg,
  ...mockMembers,
  mockVehicle,
]);
