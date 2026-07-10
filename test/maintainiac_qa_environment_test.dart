import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('QA environment fakes preserve local truth and mirror copies', () {
    final env = MaintainiacQaEnvironment.standard();
    final localPayload = {'id': 'expense_1', 'amountCents': 1299};
    final mirrorPayload = {'id': 'expense_1', 'amountCents': 1299};

    env.hive.put('expenses', 'expense_1', localPayload);
    env.firestoreMirror.mirror(
      'accounts/acct_1/expenses/expense_1',
      mirrorPayload,
    );
    localPayload['amountCents'] = 1;
    mirrorPayload['amountCents'] = 2;
    final storedLocal = env.hive.get('expenses', 'expense_1')!;
    storedLocal['amountCents'] = 3;

    expect(env.hive.get('expenses', 'expense_1')!['amountCents'], 1299);
    expect(
      env
          .firestoreMirror
          .documents['accounts/acct_1/expenses/expense_1']!['amountCents'],
      1299,
    );
    expect(env.hive.writes.single.kind, 'local');
    expect(env.firestoreMirror.writes.single.kind, 'firestore_mirror');
  });

  test('QA environment exposes permissions device and side-effect fakes', () {
    final env = MaintainiacQaEnvironment.standard();

    env.notifications.schedule({'id': 'note_1', 'sourceMutation': false});
    env.exports.write({'id': 'export_1', 'ownerAccountId': 'acct_1'});
    env.cloudStorage.write('exports/export_1.csv', [1, 2, 3]);
    env.files.put('local/report.txt', 'safe report');

    expect(env.permissions.allows('fleet.manage'), isTrue);
    expect(env.permissions.allows('delete.everything'), isFalse);
    expect(env.device.model, contains('Galaxy'));
    expect(env.device.appCheckValid, isTrue);
    expect(env.notifications.scheduled.single['sourceMutation'], isFalse);
    expect(env.exports.exports.single['ownerAccountId'], 'acct_1');
    expect(env.cloudStorage.objects['exports/export_1.csv'], [1, 2, 3]);
    expect(env.files.files['local/report.txt'], 'safe report');
  });

  test('QA builders create every shared record family', () {
    final records = [
      MaintainiacQaBuilders.user(),
      MaintainiacQaBuilders.account(),
      MaintainiacQaBuilders.profile(),
      MaintainiacQaBuilders.vehicle(),
      MaintainiacQaBuilders.odometerSnapshot(),
      MaintainiacQaBuilders.dayLog(),
      MaintainiacQaBuilders.trip(),
      MaintainiacQaBuilders.tripEvent(),
      MaintainiacQaBuilders.expense(),
      MaintainiacQaBuilders.receipt(),
      MaintainiacQaBuilders.receiptSegment(),
      MaintainiacQaBuilders.ocrResult(),
      MaintainiacQaBuilders.inventoryItem(),
      MaintainiacQaBuilders.catalogItem(),
      MaintainiacQaBuilders.inventoryMovement(),
      MaintainiacQaBuilders.job(),
      MaintainiacQaBuilders.estimate(),
      MaintainiacQaBuilders.invoice(),
      MaintainiacQaBuilders.maintenanceEntry(),
      MaintainiacQaBuilders.calendarEdit(),
      MaintainiacQaBuilders.auditEntry(),
      MaintainiacQaBuilders.syncConflict(),
      MaintainiacQaBuilders.exportRequest(),
      MaintainiacQaBuilders.notificationEvent(),
      MaintainiacQaBuilders.company(),
      MaintainiacQaBuilders.employee(),
      MaintainiacQaBuilders.fleetVehicle(),
    ];

    expect(records, hasLength(27));
    for (final record in records) {
      expect(record['id'], isNotNull);
    }
    expect(MaintainiacQaBuilders.environment().account.id, 'acct_1');
  });
}
