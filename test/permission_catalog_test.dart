import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/profiles/employee_add_permission_setup_models.dart';
import 'package:maintaniac/screens/profiles/employee_permission_catalog.dart';
import 'package:maintaniac/screens/profiles/employee_permissions_screen.dart';
import 'package:maintaniac/screens/settings/system_settings.dart';
import 'package:maintaniac/shared/context/operational_context_store.dart';
import 'package:maintaniac/shared/profiles/employee_directory_store.dart';
import 'package:maintaniac/shared/profiles/user_profile_models.dart';
import 'package:maintaniac/shared/profiles/user_profile_store.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

void main() {
  test(
    'permission catalog covers every app area without mixing estimates into invoices',
    () {
      expect(
        employeePermissionCatalog.map((module) => module.key),
        containsAll({
          'admin',
          'employees',
          'jobs',
          'estimates',
          'invoices',
          'expenses',
          'receipts',
          'inventory',
          'vehicles',
          'maintenance',
          'calendar',
          'reports',
          'customerPortal',
        }),
      );

      for (final module in employeePermissionCatalog) {
        expect(
          module.permissions,
          isNotEmpty,
          reason: '${module.title} must expose real permissions.',
        );
      }

      final keys = employeePermissionCatalog
          .expand((module) => module.permissions)
          .map((permission) => permission.key)
          .toList();
      expect(
        keys.toSet().length,
        keys.length,
        reason: 'Permission keys must be unique.',
      );

      final invoices = employeePermissionCatalog.singleWhere(
        (module) => module.key == 'invoices',
      );
      expect(
        invoices.permissions.map((permission) => permission.resource).toSet(),
        isNot(contains('Estimates')),
      );
      expect(
        invoices.permissions.map((permission) => permission.key),
        containsAll({
          'invoices.invoices.own.view',
          'invoices.invoices.other.edit',
          'invoices.invoicePdfFiles.own.view',
          'invoices.invoiceStatus.own.manage',
          'invoices.invoiceTemplates.other.edit',
        }),
      );

      final estimates = employeePermissionCatalog.singleWhere(
        (module) => module.key == 'estimates',
      );
      expect(
        estimates.permissions.map((permission) => permission.key),
        containsAll({
          'estimates.estimates.own.view',
          'estimates.estimates.other.edit',
          'estimates.estimateConversion.own.manage',
          'estimates.estimateApprovals.other.edit',
        }),
      );
    },
  );

  test(
    'expense permission catalog covers records, categories, personal use, reminders, reports, and settings',
    () {
      final expenses = employeePermissionCatalog.singleWhere(
        (module) => module.key == 'expenses',
      );
      final itemKeys = expenses.items.map((item) => item.key).toSet();

      expect(
        itemKeys,
        containsAll({
          'expenseRecords',
          'receiptProof',
          'receiptReview',
          'fuelExpense',
          'materialsExpense',
          'toolsExpense',
          'maintenanceExpense',
          'repairsExpense',
          'parkingTollsExpense',
          'mealsExpense',
          'lodgingExpense',
          'officeExpense',
          'uniformsExpense',
          'permitsExpense',
          'subcontractorExpense',
          'insuranceExpense',
          'rentalsExpense',
          'shippingExpense',
          'otherExpense',
          'personalExpenses',
          'splitExpenses',
          'expenseReminders',
          'expenseRecaps',
          'expenseExports',
          'expenseSettings',
        }),
      );

      final permissionKeys = expenses.permissions
          .map((permission) => permission.key)
          .toSet();
      expect(
        permissionKeys,
        containsAll({
          'expenses.expenseRecords.own.view',
          'expenses.expenseRecords.other.create',
          'expenses.receiptProof.own.export',
          'expenses.receiptReview.own.manage',
          'expenses.personalExpenses.own.create',
          'expenses.splitExpenses.own.edit',
          'expenses.expenseReminders.other.edit',
          'expenses.expenseRecaps.other.view',
          'expenses.expenseExports.own.export',
          'expenses.expenseSettings.own.manage',
        }),
      );
    },
  );

  test(
    'add employee quick expense setup includes the release-track expense workflow',
    () {
      final expenseGroup = addPermissionGroups.singleWhere(
        (group) => group.title == 'Expenses and Receipts',
      );
      final ruleIds = {
        for (final rule in expenseGroup.rules) '${rule.area}.${rule.item}',
      };

      expect(
        ruleIds,
        containsAll({
          'expenses.expenseRecords',
          'expenses.receiptProof',
          'expenses.receiptReview',
          'expenses.fuelExpense',
          'expenses.materialsExpense',
          'expenses.toolsExpense',
          'expenses.parkingTollsExpense',
          'expenses.mealsExpense',
          'expenses.personalExpenses',
          'expenses.splitExpenses',
          'expenses.expenseReminders',
          'expenses.expenseRecaps',
          'expenses.expenseExports',
        }),
      );
      expect(ruleIds, contains('receipts.receiptCapture'));
    },
  );

  test('add employee setup includes every permission catalog item', () {
    final catalogItems = {
      for (final area in employeePermissionCatalog)
        for (final item in area.items) '${area.key}.${item.key}',
    };
    final addSetupItems = {
      for (final group in addPermissionGroups)
        for (final rule in group.rules) '${rule.area}.${rule.item}',
    };

    expect(
      addSetupItems,
      containsAll(catalogItems),
      reason: 'Add New Employee permission setup must not leave app areas out.',
    );
  });

  testWidgets('menu shows employee permissions only to profile managers', (
    tester,
  ) async {
    await _pumpMenu(tester, UserProfileRecord.starterContractor());

    expect(find.text('Account Access'), findsOneWidget);
    expect(find.text('Employee Profiles and Permissions'), findsOneWidget);

    final helper = UserProfileRecord(
      id: 'helper',
      name: 'Helper',
      type: UserProfileType.contractor,
      role: UserRole.helper,
      permissions: permissionsForRole(UserRole.helper),
    );
    await _pumpMenu(tester, helper);

    expect(find.text('Account Access'), findsNothing);
    expect(find.text('Employee Profiles and Permissions'), findsNothing);
    expect(find.text('Screens'), findsOneWidget);
  });

  testWidgets('employee editor can add an employee and queue invite', (
    tester,
  ) async {
    await _pumpEmployeeEditor(tester, UserProfileRecord.starterContractor());

    await tester.tap(find.text('Add New Employee'));
    await tester.pumpAndSettle();

    expect(find.text('Add Employee'), findsOneWidget);
    expect(find.text('Role and Permissions'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('set-up-permissions-button')),
      findsOneWidget,
    );
    expect(find.text('Set Up Permissions'), findsOneWidget);
    expect(find.textContaining('permission actions'), findsOneWidget);
    expect(find.text('Permission starting point'), findsNothing);
    expect(find.text('Review Setup'), findsNothing);
    expect(find.text('Save Setup'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('set-up-permissions-button')));
    await tester.pumpAndSettle();

    expect(find.text('Small Crew Setup'), findsOneWidget);
    expect(find.text('Workday, Hours, and Calendar'), findsOneWidget);
    expect(find.text('Assigned Jobs and Job Proof'), findsOneWidget);
    expect(find.text('Vehicles and Mileage'), findsOneWidget);
    expect(find.text('Expenses and Receipts'), findsOneWidget);
    expect(find.text('Their own / assigned records'), findsWidgets);
    expect(find.text('Other employees / team records'), findsWidgets);
    expect(find.text('View'), findsWidgets);
    expect(find.text('Create'), findsWidgets);
    expect(find.text('Edit'), findsWidgets);
    expect(find.text('Advanced'), findsWidgets);
    expect(find.text('Own'), findsNothing);
    expect(find.text('Team'), findsNothing);
    expect(find.text('Search app areas'), findsNothing);

    await tester.tap(find.text('Advanced').first);
    await tester.pumpAndSettle();

    expect(find.text('Workday, Hours, and Calendar Advanced'), findsOneWidget);
    expect(find.text('calendar days'), findsOneWidget);
    expect(find.text('employee hours and time cards'), findsOneWidget);
    expect(find.text('Invoices, Estimates, and Payments'), findsNothing);
    expect(find.text('Search app areas'), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply Permissions'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Jordan Helper');
    await tester.enterText(find.byType(TextFormField).at(1), '5550102000');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'jordan@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Crew title (optional)'),
      'Foreman',
    );

    await tester.tap(find.text('Save Employee').first);
    await tester.pumpAndSettle();

    expect(find.text('Jordan Helper'), findsOneWidget);
    expect(find.text('Ready to invite'), findsNothing);

    await tester.tap(find.text('Jordan Helper'));
    await tester.pumpAndSettle();
    expect(find.text('Ready to invite'), findsOneWidget);
    expect(find.text('Foreman'), findsOneWidget);
    await tester.tap(find.text('Queue Invite'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jordan Helper'));
    await tester.pumpAndSettle();
    expect(find.text('Invite queued'), findsOneWidget);
  });

  testWidgets('employee profile opens with information and recap only', (
    tester,
  ) async {
    await _pumpEmployeeEditor(tester, UserProfileRecord.starterContractor());

    expect(find.text('Alex Supervisor'), findsOneWidget);
    expect(find.text('(555) 010-1001'), findsNothing);

    await tester.tap(find.text('Alex Supervisor'));
    await tester.pumpAndSettle();

    expect(find.text('Employee Information'), findsOneWidget);
    expect(find.text('(555) 010-1001'), findsOneWidget);
    expect(find.text('Work Truck 1'), findsWidgets);
    expect(find.text('Employee Recap'), findsNothing);
    expect(find.text('Employee Calendar'), findsOneWidget);
    expect(find.text('Week Activity'), findsNothing);
    expect(find.text('Current Permissions'), findsNothing);

    await tester.tap(find.text('Permissions'));
    await tester.pumpAndSettle();

    expect(find.text('Alex Supervisor Access'), findsOneWidget);
    expect(find.text('Access Summary'), findsOneWidget);
    expect(find.text('Edit Permissions'), findsOneWidget);
  });

  testWidgets(
    'permission editor explains other employee access in the same action block',
    (tester) async {
      await _pumpEmployeeEditor(tester, UserProfileRecord.starterContractor());

      await tester.tap(find.text('Alex Supervisor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Permissions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Permissions'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Search app areas'),
        'invoice pdf',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Invoices').first);
      await tester.pumpAndSettle();

      expect(find.text('invoice PDF delivery'), findsOneWidget);
      expect(find.text('View invoice pdf delivery'), findsOneWidget);

      expect(
        find.text('Can they view other employees\' invoice pdf delivery?'),
        findsOneWidget,
      );
      await tester.tap(
        find.text('Can they view other employees\' invoice pdf delivery?'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Specific employees:'), findsWidgets);
      expect(find.text('Alex Supervisor / Field Manager'), findsWidgets);
    },
  );

  testWidgets('permission definitions explain the permission contract', (
    tester,
  ) async {
    await _pumpEmployeeEditor(tester, UserProfileRecord.starterContractor());

    await tester.tap(
      find.byKey(const ValueKey('employee-permission-definitions-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Permission Definitions'), findsOneWidget);
    expect(find.text('Permission Levels'), findsOneWidget);
    expect(find.text('Record Actions'), findsOneWidget);
    expect(find.text('Employee Controls'), findsOneWidget);
    expect(find.text('Custom Roles'), findsOneWidget);
    expect(find.text('Backend Enforcement'), findsOneWidget);
    expect(find.text('App Areas Covered'), findsOneWidget);
    expect(find.text('High-impact Defaults'), findsOneWidget);
  });
}

Future<void> _pumpMenu(WidgetTester tester, UserProfileRecord profile) async {
  final appState = AppStateController();
  final odometer = GlobalOdometerController();
  final context = OperationalContextController.memory(profile: profile);
  addTearDown(appState.dispose);
  addTearDown(odometer.dispose);
  addTearDown(context.dispose);

  await tester.pumpWidget(
    AppStateScope(
      controller: appState,
      child: GlobalOdometerScope(
        controller: odometer,
        child: OperationalContextScope(
          controller: context,
          child: const MaterialApp(home: SystemSettingsScreen()),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpEmployeeEditor(
  WidgetTester tester,
  UserProfileRecord profile,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 4200);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final appState = AppStateController();
  final odometer = GlobalOdometerController();
  final profiles = UserProfileController.memory(activeProfile: profile);
  final context = OperationalContextController.memory(profile: profile);
  final directory = EmployeeDirectoryController.memory();
  addTearDown(appState.dispose);
  addTearDown(odometer.dispose);
  addTearDown(profiles.dispose);
  addTearDown(context.dispose);
  addTearDown(directory.dispose);

  await tester.pumpWidget(
    AppStateScope(
      controller: appState,
      child: GlobalOdometerScope(
        controller: odometer,
        child: OperationalContextScope(
          controller: context,
          child: UserProfileScope(
            controller: profiles,
            child: MaterialApp(
              home: EmployeePermissionsScreen(directoryController: directory),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
