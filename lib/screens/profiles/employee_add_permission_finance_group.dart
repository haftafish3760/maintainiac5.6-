// Employee permission setup: estimate, invoice, and payment group catalog only.
part of 'employee_add_permission_setup_models.dart';

const _financePermissionGroup = AddCrewPermissionGroup(
  title: 'Invoices, Estimates, and Payments',
  detail: 'Customer money, paperwork, invoice status, estimates, and payments.',
  office: AddPermissionPreset(
    own: ownViewCreateEdit,
    other: otherViewCreateEdit,
  ),
  rules: [
    AddPermissionRule('estimates', 'estimates', _viewCreateEditVerbs),
    AddPermissionRule('estimates', 'estimateApprovals', [
      PermissionVerb.view,
      PermissionVerb.edit,
    ]),
    AddPermissionRule('estimates', 'estimateTemplates', _viewCreateEditVerbs),
    AddPermissionRule('estimates', 'estimateConversion', [
      PermissionVerb.view,
      PermissionVerb.create,
    ]),
    AddPermissionRule('invoices', 'invoices', _viewCreateEditVerbs),
    AddPermissionRule('invoices', 'invoicePdfFiles', [PermissionVerb.view]),
    AddPermissionRule('invoices', 'invoiceTemplates', _viewCreateEditVerbs),
    AddPermissionRule('invoices', 'invoiceStatus', [
      PermissionVerb.view,
      PermissionVerb.edit,
    ]),
    AddPermissionRule('payments', 'customerPayments', _viewCreateEditVerbs),
    AddPermissionRule('payments', 'unpaidBalances', [PermissionVerb.view]),
    AddPermissionRule('payments', 'paymentProof', _viewCreateEditVerbs),
  ],
);
