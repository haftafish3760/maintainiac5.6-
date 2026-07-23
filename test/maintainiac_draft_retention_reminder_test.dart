import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  test('every screen defaults to one in-app reminder after 90 days', () async {
    final drafts = MaintainiacRecordDraftStore.memory();
    final records = MaintainiacDurableRecordStore.memory();
    final coordinator = MaintainiacDraftReminderCoordinator(
      drafts: drafts,
      records: records,
    );
    final createdAt = DateTime.utc(2026, 1, 1);
    await drafts.save(
      module: 'expenseForms',
      id: 'expense-draft-1',
      payload: const {'amount': 25},
      now: createdAt,
    );

    expect(
      coordinator.dueForScope(
        scopeId: 'expenses',
        draftModules: const ['expenseForms'],
        nowUtc: createdAt.add(const Duration(days: 89)),
      ),
      isEmpty,
    );
    final due = coordinator.dueForScope(
      scopeId: 'expenses',
      draftModules: const ['expenseForms'],
      nowUtc: createdAt.add(const Duration(days: 90)),
    );
    expect(due, hasLength(1));
    expect(due.single.showInApp, isTrue);
    expect(due.single.sendPush, isFalse);
    expect(due.single.playAudio, isFalse);

    await coordinator.recordDelivery(due.single, inAppDelivered: true);

    expect(
      coordinator.dueForScope(
        scopeId: 'expenses',
        draftModules: const ['expenseForms'],
        nowUtc: createdAt.add(const Duration(days: 120)),
      ),
      isEmpty,
    );
    expect(drafts.draftFor('expenseForms', 'expense-draft-1'), isNotNull);
  });

  test('push and audio remain opt-in and isolated by screen scope', () async {
    final drafts = MaintainiacRecordDraftStore.memory();
    final records = MaintainiacDurableRecordStore.memory();
    final policies = MaintainiacDraftRetentionPolicyStore(records);
    final coordinator = MaintainiacDraftReminderCoordinator(
      drafts: drafts,
      records: records,
    );
    final createdAt = DateTime.utc(2026, 1, 1);
    await policies.save(
      const MaintainiacDraftRetentionPolicy(
        scopeId: 'expenses',
        pushReminderEnabled: true,
        audioReminderEnabled: true,
      ),
      now: createdAt,
    );
    await drafts.save(
      module: 'sharedFormDrafts',
      id: 'draft-1',
      payload: const {'field': 'value'},
      now: createdAt,
    );

    final expenseDecision = coordinator.dueForScope(
      scopeId: 'expenses',
      draftModules: const ['sharedFormDrafts'],
      nowUtc: createdAt.add(const Duration(days: 90)),
    );
    final invoiceDecision = coordinator.dueForScope(
      scopeId: 'invoices',
      draftModules: const ['sharedFormDrafts'],
      nowUtc: createdAt.add(const Duration(days: 90)),
    );

    expect(expenseDecision.single.sendPush, isTrue);
    expect(expenseDecision.single.playAudio, isTrue);
    expect(invoiceDecision.single.sendPush, isFalse);
    expect(invoiceDecision.single.playAudio, isFalse);
  });

  test('editing a reminded draft starts a fresh 90-day window', () async {
    final drafts = MaintainiacRecordDraftStore.memory();
    final records = MaintainiacDurableRecordStore.memory();
    final coordinator = MaintainiacDraftReminderCoordinator(
      drafts: drafts,
      records: records,
    );
    final createdAt = DateTime.utc(2026, 1, 1);
    await drafts.save(
      module: 'estimateForms',
      id: 'estimate-1',
      payload: const {'step': 1},
      now: createdAt,
    );
    final first = coordinator.dueForScope(
      scopeId: 'estimates',
      draftModules: const ['estimateForms'],
      nowUtc: createdAt.add(const Duration(days: 90)),
    );
    await coordinator.recordDelivery(first.single, inAppDelivered: true);

    final editedAt = createdAt.add(const Duration(days: 100));
    await drafts.save(
      module: 'estimateForms',
      id: 'estimate-1',
      payload: const {'step': 2},
      now: editedAt,
    );

    expect(
      coordinator.dueForScope(
        scopeId: 'estimates',
        draftModules: const ['estimateForms'],
        nowUtc: editedAt.add(const Duration(days: 89)),
      ),
      isEmpty,
    );
    expect(
      coordinator.dueForScope(
        scopeId: 'estimates',
        draftModules: const ['estimateForms'],
        nowUtc: editedAt.add(const Duration(days: 90)),
      ),
      hasLength(1),
    );
  });

  test('secondary screens can share their parent notification scope', () async {
    final records = MaintainiacDurableRecordStore.memory();
    final policies = MaintainiacDraftRetentionPolicyStore(records);
    final saved = await policies.save(
      const MaintainiacDraftRetentionPolicy(
        scopeId: 'expenses',
        retentionDays: 120,
        pushReminderEnabled: true,
      ),
    );

    expect(policies.policyFor('expenses').retentionDays, 120);
    expect(saved.localRevision, 1);
    expect(policies.policyFor('calendar').retentionDays, 90);
  });

  test('invalid screen scopes fail before reminder state can be stored', () {
    final policies = MaintainiacDraftRetentionPolicyStore(
      MaintainiacDurableRecordStore.memory(),
    );

    expect(() => policies.policyFor('../expenses'), throwsArgumentError);
  });
}
