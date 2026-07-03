import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('local-first contract accepts Hive before Firestore mirror', () {
    const contract = MaintainiacLocalFirstContract([
      MaintainiacWriteStep(
        order: 0,
        target: MaintainiacWriteTarget.localHive,
        collection: 'expenses',
        recordId: 'expense_1',
        sourceOperation: 'confirm_expense',
        mutatesSource: true,
      ),
      MaintainiacWriteStep(
        order: 1,
        target: MaintainiacWriteTarget.firestoreMirror,
        collection: 'expenses',
        recordId: 'expense_1',
        sourceOperation: 'confirm_expense',
        mirrorOnly: true,
      ),
      MaintainiacWriteStep(
        order: 2,
        target: MaintainiacWriteTarget.derivedOutput,
        collection: 'recaps/daily',
        recordId: '2026-07-03',
        sourceOperation: 'confirm_expense',
      ),
    ]);

    expect(contract.validate(), isEmpty);
    expect(contract.toJson().toString(), contains('localHive'));
  });

  test('local-first contract rejects mirror writes before local truth', () {
    const contract = MaintainiacLocalFirstContract([
      MaintainiacWriteStep(
        order: 0,
        target: MaintainiacWriteTarget.firestoreMirror,
        collection: 'inventory',
        recordId: 'item_1',
        sourceOperation: 'confirm_inventory_item',
        mirrorOnly: true,
      ),
    ]);

    expect(
      contract.validate().join('\n'),
      contains('mirrored before local Hive'),
    );
  });

  test('local-first contract rejects unsafe derived and mirror writes', () {
    const contract = MaintainiacLocalFirstContract([
      MaintainiacWriteStep(
        order: 0,
        target: MaintainiacWriteTarget.localHive,
        collection: 'jobs',
        recordId: 'job_1',
        sourceOperation: 'create_job',
        mirrorOnly: true,
      ),
      MaintainiacWriteStep(
        order: 1,
        target: MaintainiacWriteTarget.firestoreMirror,
        collection: 'jobs',
        recordId: 'job_1',
        sourceOperation: 'create_job',
      ),
      MaintainiacWriteStep(
        order: 2,
        target: MaintainiacWriteTarget.derivedOutput,
        collection: 'source/jobs',
        recordId: 'job_1',
        sourceOperation: 'create_job',
        mutatesSource: true,
      ),
    ]);

    final failures = contract.validate().join('\n');

    expect(failures, contains('local Hive write cannot be mirror-only'));
    expect(failures, contains('Firestore write must be mirror-only'));
    expect(failures, contains('derived output must not mutate source'));
    expect(failures, contains('derived output points at source collection'));
  });
}
