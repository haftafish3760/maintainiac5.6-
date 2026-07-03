import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('sync lifecycle writes local dirty record before mirror success', () {
    final env = MaintainiacQaEnvironment.standard();
    final probe = MaintainiacSyncLifecycleProbe(env);

    final dirty = probe.localWrite(
      box: 'expenses',
      id: 'expense_1',
      payload: MaintainiacQaBuilders.expense(),
    );
    final syncing = probe.markSyncing('expenses', 'expense_1');
    final synced = probe.mirrorSuccess(
      box: 'expenses',
      id: 'expense_1',
      path: 'accounts/acct_1/expenses/expense_1',
    );

    expect(dirty.state, MaintainiacSyncRecordState.dirty);
    expect(syncing.state, MaintainiacSyncRecordState.syncing);
    expect(synced.state, MaintainiacSyncRecordState.synced);
    expect(synced.payload['dirty'], isFalse);
    expect(env.hive.writes, hasLength(1));
    expect(env.firestoreMirror.writes, hasLength(1));
  });

  test('sync lifecycle keeps failed records queued for retry', () {
    final env = MaintainiacQaEnvironment.standard();
    final probe = MaintainiacSyncLifecycleProbe(env);

    probe.localWrite(
      box: 'inventory',
      id: 'inv_1',
      payload: MaintainiacQaBuilders.inventoryItem(),
    );
    final failed = probe.markFailed('inventory', 'inv_1', 'offline');

    expect(failed.state, MaintainiacSyncRecordState.failed);
    expect(failed.retryCount, 1);
    expect(failed.lastError, 'offline');
    expect(probe.pendingRetryQueue().single.id, 'inv_1');
    probe.assertLocalIsAuthority('inventory', 'inv_1');
  });

  test('sync lifecycle rejects unknown record transitions', () {
    final probe = MaintainiacSyncLifecycleProbe(
      MaintainiacQaEnvironment.standard(),
    );

    expect(() => probe.markSyncing('expenses', 'missing'), throwsStateError);
  });
}
