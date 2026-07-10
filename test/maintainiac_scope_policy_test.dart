import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test(
    'scope policy allows account owner with assigned vehicle permission',
    () {
      const probe = MaintainiacScopePolicyProbe();
      final subject = probe.ownerFrom(MaintainiacQaEnvironment.standard());
      const record = MaintainiacScopedRecord(
        id: 'expense_1',
        accountId: 'acct_1',
        vehicleId: 'vehicle_1',
        requiredPermission: 'read',
      );

      expect(probe.canAccess(subject, record), isTrue);
      expect(probe.deniedReasons(subject, record), isEmpty);
    },
  );

  test('scope policy denies cross-account and unassigned vehicle access', () {
    const probe = MaintainiacScopePolicyProbe();
    const subject = MaintainiacScopeSubject(
      userId: 'user_1',
      accountId: 'acct_1',
      vehicleIds: {'vehicle_1'},
      permissions: {'read'},
    );
    const record = MaintainiacScopedRecord(
      id: 'expense_2',
      accountId: 'acct_2',
      vehicleId: 'vehicle_2',
      requiredPermission: 'read',
    );

    expect(probe.canAccess(subject, record), isFalse);
    expect(probe.deniedReasons(subject, record), {
      'account_mismatch',
      'vehicle_not_assigned',
    });
  });

  test('scope policy requires company employee and permission match', () {
    const probe = MaintainiacScopePolicyProbe();
    const subject = MaintainiacScopeSubject(
      userId: 'employee_user',
      accountId: 'acct_1',
      companyId: 'company_1',
      employeeId: 'employee_1',
      vehicleIds: {'truck_1'},
      permissions: {'read'},
    );
    const record = MaintainiacScopedRecord(
      id: 'export_1',
      accountId: 'acct_1',
      companyId: 'company_1',
      employeeId: 'employee_1',
      vehicleId: 'truck_1',
      requiredPermission: 'export',
    );

    expect(probe.canAccess(subject, record), isFalse);
    expect(probe.deniedReasons(subject, record), ['permission_missing']);
  });

  test(
    'scope policy matrix covers fleet company employee and vehicle denials',
    () {
      const matrix = maintainiacScopePolicyMatrix;

      expect(matrix.validate(), isEmpty);
      expect(matrix.toJson()['caseCount'], greaterThanOrEqualTo(6));
      expect(matrix.toJson().toString(), contains('cross_account_denied'));
      expect(matrix.toJson().toString(), contains('employee_mismatch_denied'));
      expect(matrix.toJson().toString(), contains('vehicle_not_assigned'));
    },
  );

  test('scope policy matrix rejects missing denial explanations', () {
    const matrix = MaintainiacScopePolicyMatrix([
      MaintainiacScopePolicyCase(
        id: 'bad',
        subject: MaintainiacScopeSubject(
          userId: 'user_1',
          accountId: 'acct_1',
          permissions: {'read'},
        ),
        record: MaintainiacScopedRecord(
          id: 'expense_1',
          accountId: 'acct_2',
          requiredPermission: 'read',
        ),
        expectedAllowed: false,
        expectedDeniedReasons: {},
        reason: '',
      ),
    ]);

    final failures = matrix.validate().join('\n');

    expect(failures, contains('bad missing reason'));
    expect(failures, contains('bad denied reasons do not match expected'));
    expect(failures, contains('bad denied case must explain why'));
    expect(
      failures,
      contains('scope policy matrix missing denial company_mismatch'),
    );
  });
}
