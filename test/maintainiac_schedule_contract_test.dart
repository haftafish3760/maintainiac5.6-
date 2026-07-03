import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('schedule contract accepts audited jobs and maintenance reminders', () {
    final contract = MaintainiacScheduleContract([
      MaintainiacScheduleEntry(
        id: 'job_schedule_1',
        kind: MaintainiacScheduleKind.job,
        accountId: 'acct_1',
        sourceId: 'job_1',
        startsAt: DateTime.utc(2026, 7, 3, 13),
        timeZone: 'America/New_York',
        vehicleId: 'vehicle_1',
        employeeId: 'employee_1',
        auditId: 'AUD-JOB-0001',
      ),
      MaintainiacScheduleEntry(
        id: 'maintenance_reminder_1',
        kind: MaintainiacScheduleKind.maintenance,
        accountId: 'acct_1',
        sourceId: 'maintenance_1',
        startsAt: DateTime.utc(2026, 7, 4, 13),
        timeZone: 'America/New_York',
        vehicleId: 'vehicle_1',
      ),
    ]);

    expect(contract.validate(), isEmpty);
    expect(contract.notificationQueue(), hasLength(2));
    expect(contract.toJson().toString(), contains('maintenance_reminder_1'));
  });

  test('schedule contract respects denied notification permission', () {
    final contract = MaintainiacScheduleContract([
      MaintainiacScheduleEntry(
        id: 'expense_reminder_1',
        kind: MaintainiacScheduleKind.expenseReminder,
        accountId: 'acct_1',
        sourceId: 'expense_day_2026_07_03',
        startsAt: DateTime.utc(2026, 7, 3, 23),
        timeZone: 'America/New_York',
        notificationPermissionGranted: false,
      ),
    ]);

    expect(contract.validate(), isEmpty);
    expect(contract.notificationQueue(), isEmpty);
  });

  test('schedule contract rejects unsafe calendar and reminder records', () {
    final contract = MaintainiacScheduleContract([
      MaintainiacScheduleEntry(
        id: 'bad_job',
        kind: MaintainiacScheduleKind.job,
        accountId: 'acct_1',
        sourceId: 'job_1',
        startsAt: DateTime(2026, 7, 3, 13),
        timeZone: '',
        vehicleId: 'vehicle_1',
        mutatesSource: true,
      ),
      MaintainiacScheduleEntry(
        id: 'bad_maintenance',
        kind: MaintainiacScheduleKind.maintenance,
        accountId: 'acct_1',
        sourceId: 'maintenance_1',
        startsAt: DateTime.utc(2026, 7, 3, 13),
        timeZone: 'America/New_York',
      ),
      MaintainiacScheduleEntry(
        id: 'overlap_1',
        kind: MaintainiacScheduleKind.job,
        accountId: 'acct_1',
        sourceId: 'job_2',
        startsAt: DateTime.utc(2026, 7, 5, 13),
        timeZone: 'America/New_York',
        vehicleId: 'vehicle_1',
        auditId: 'AUD-JOB-0002',
      ),
      MaintainiacScheduleEntry(
        id: 'overlap_2',
        kind: MaintainiacScheduleKind.job,
        accountId: 'acct_1',
        sourceId: 'job_3',
        startsAt: DateTime.utc(2026, 7, 5, 13),
        timeZone: 'America/New_York',
        vehicleId: 'vehicle_1',
        auditId: 'AUD-JOB-0003',
      ),
    ]);

    final failures = contract.validate().join('\n');

    expect(failures, contains('missing time zone'));
    expect(failures, contains('startsAt must be stored as UTC'));
    expect(failures, contains('schedule output must not mutate source'));
    expect(failures, contains('job schedule edit needs audit id'));
    expect(failures, contains('maintenance schedule needs vehicle id'));
    expect(failures, contains('vehicle schedule overlap overlap_1 overlap_2'));
  });
}
