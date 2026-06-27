import 'employee_permission_models.dart';

EmployeePermissionArea expensePermissionArea() {
  return EmployeePermissionArea(
    key: 'expenses',
    title: 'Expenses',
    summary:
        'Expense records, receipts, categories, reminders, recaps, exports, and settings.',
    highImpact: true,
    items: [
      const EmployeePermissionItem(
        key: 'expenseRecords',
        title: 'expense records',
        description:
            'The saved expense entry itself, including date, amount, category, vehicle, and work context.',
        verbs: [
          PermissionVerb.view,
          PermissionVerb.create,
          PermissionVerb.edit,
          PermissionVerb.delete,
        ],
        highImpact: true,
      ),
      const EmployeePermissionItem(
        key: 'receiptProof',
        title: 'receipt proof files',
        description:
            'Receipt photos, PDFs, imported proof files, and optimized proof copies attached to expenses.',
        verbs: [
          PermissionVerb.view,
          PermissionVerb.create,
          PermissionVerb.edit,
          PermissionVerb.delete,
          PermissionVerb.export,
        ],
        highImpact: true,
      ),
      const EmployeePermissionItem(
        key: 'receiptReview',
        title: 'receipt OCR and review',
        description:
            'OCR results, parser review, corrected receipt fields, and line-item review before saving.',
        verbs: [
          PermissionVerb.view,
          PermissionVerb.create,
          PermissionVerb.edit,
          PermissionVerb.manage,
        ],
        highImpact: true,
      ),
      for (final category in _expenseCategories)
        EmployeePermissionItem(
          key: '${category.$1}Expense',
          title: '${category.$2} expense',
          description:
              'View, create, or edit ${category.$2.toLowerCase()} expense records and receipt lines.',
          verbs: const [
            PermissionVerb.view,
            PermissionVerb.create,
            PermissionVerb.edit,
            PermissionVerb.delete,
          ],
          highImpact: category.$3,
        ),
      const EmployeePermissionItem(
        key: 'personalExpenses',
        title: 'personal expenses',
        description:
            'Allow this employee to record personal expense lines or personal receipts in the company account.',
        verbs: [
          PermissionVerb.view,
          PermissionVerb.create,
          PermissionVerb.edit,
          PermissionVerb.delete,
        ],
        highImpact: true,
      ),
      const EmployeePermissionItem(
        key: 'splitExpenses',
        title: 'split business and personal expenses',
        description:
            'Mixed receipts where some lines are business, some are personal, or a line is split by percent.',
        verbs: [
          PermissionVerb.view,
          PermissionVerb.create,
          PermissionVerb.edit,
        ],
        highImpact: true,
      ),
      const EmployeePermissionItem(
        key: 'expenseReminders',
        title: 'expense reminders',
        description:
            'Reminders for bills, missed receipts, recurring expenses, and receipt follow-up.',
        verbs: [
          PermissionVerb.view,
          PermissionVerb.create,
          PermissionVerb.edit,
          PermissionVerb.delete,
        ],
      ),
      const EmployeePermissionItem(
        key: 'expenseRecaps',
        title: 'expense recaps and reports',
        description:
            'Daily, weekly, monthly, 90-day, year-to-date, vehicle, fuel, category, and profit-related expense recap tiles.',
        verbs: [PermissionVerb.view, PermissionVerb.export],
        highImpact: true,
      ),
      const EmployeePermissionItem(
        key: 'expenseExports',
        title: 'expense exports',
        description:
            'CSV exports, audit packets, receipt proof packets, and tax/accountant expense reports.',
        verbs: [
          PermissionVerb.view,
          PermissionVerb.create,
          PermissionVerb.export,
        ],
        highImpact: true,
      ),
      const EmployeePermissionItem(
        key: 'expenseSettings',
        title: 'expense settings',
        description:
            'Expense screen settings, recap tile visibility, receipt storage choices, OCR defaults, and reminder channels.',
        verbs: [
          PermissionVerb.view,
          PermissionVerb.edit,
          PermissionVerb.manage,
        ],
        highImpact: true,
      ),
    ],
  );
}

const _expenseCategories = [
  ('fuel', 'Fuel', true),
  ('materials', 'Materials', true),
  ('tools', 'Tools', true),
  ('maintenance', 'Maintenance', true),
  ('repairs', 'Repair', true),
  ('parkingTolls', 'Parking / tolls', false),
  ('meals', 'Meals', false),
  ('lodging', 'Lodging', false),
  ('office', 'Office', false),
  ('uniforms', 'Uniforms', false),
  ('permits', 'Permits', true),
  ('subcontractor', 'Subcontractor', true),
  ('insurance', 'Insurance', true),
  ('rentals', 'Rental', true),
  ('shipping', 'Shipping', false),
  ('other', 'Other', false),
];
