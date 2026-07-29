// Employee permission setup: expense and receipt group catalog only.
part of 'employee_add_permission_setup_models.dart';

const _viewCreateEditVerbs = [
  PermissionVerb.view,
  PermissionVerb.create,
  PermissionVerb.edit,
];

const _expensesAndReceiptsPermissionGroup = AddCrewPermissionGroup(
  title: 'Expenses and Receipts',
  detail:
      'Record expenses, attach receipt proof, classify business or personal use, and review receipt OCR.',
  helper: AddPermissionPreset(own: ownViewCreateEdit),
  technician: AddPermissionPreset(own: ownViewCreateEdit),
  driver: AddPermissionPreset(own: ownViewCreateEdit),
  office: AddPermissionPreset(
    own: ownViewCreateEdit,
    other: otherViewCreateEdit,
  ),
  rules: [
    AddPermissionRule('expenses', 'expenseRecords', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'receiptProof', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'receiptReview', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'fuelExpense', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'materialsExpense', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'toolsExpense', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'maintenanceExpense', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'repairsExpense', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'parkingTollsExpense', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'mealsExpense', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'lodgingExpense', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'officeExpense', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'uniformsExpense', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'permitsExpense', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'subcontractorExpense', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'insuranceExpense', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'rentalsExpense', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'shippingExpense', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'otherExpense', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'personalExpenses', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'splitExpenses', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'expenseReminders', _viewCreateEditVerbs),
    AddPermissionRule('expenses', 'expenseRecaps', [PermissionVerb.view]),
    AddPermissionRule('expenses', 'expenseExports', [
      PermissionVerb.view,
      PermissionVerb.create,
    ]),
    AddPermissionRule('expenses', 'expenseSettings', [
      PermissionVerb.view,
      PermissionVerb.edit,
    ]),
    AddPermissionRule('receipts', 'receiptCapture', _viewCreateEditVerbs),
    AddPermissionRule('receipts', 'receiptParsing', [
      PermissionVerb.view,
      PermissionVerb.edit,
    ]),
    AddPermissionRule('receipts', 'receiptExports', [PermissionVerb.view]),
  ],
);
