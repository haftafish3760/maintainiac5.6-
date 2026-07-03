import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('QA readiness ledger tracks completed backbone and remaining gaps', () {
    final ledger = MaintainiacQaReadinessLedger.currentBackbone();

    expect(ledger.validate(), isEmpty);
    expect(ledger.releaseReady, isTrue);
    expect(ledger.countsByStatus['ready'], greaterThanOrEqualTo(5));
    expect(ledger.countsByStatus['partial'], 0);
    expect(ledger.countsByStatus['missing'], 0);
    expect(ledger.toJson().toString(), contains('inventory_parser_consumer'));
    expect(ledger.toJson().toString(), contains('expense_parser_consumer'));
    expect(ledger.toJson().toString(), contains('device_capability_probe'));
    expect(ledger.toJson().toString(), contains('scope_policy_probe'));
    expect(ledger.toJson().toString(), contains('audit_trail_probe'));
    expect(ledger.toJson().toString(), contains('export_privacy_probe'));
    expect(ledger.toJson().toString(), contains('mutation_guard_probe'));
    expect(ledger.toJson().toString(), contains('failure_taxonomy_probe'));
  });

  test('QA readiness ledger rejects fake ready claims without evidence', () {
    const ledger = MaintainiacQaReadinessLedger([
      MaintainiacQaReadinessItem(
        id: 'fake_ready',
        module: MaintainiacQaModule.expenses,
        description: 'This should fail because there is no evidence.',
        status: MaintainiacQaReadinessStatus.ready,
      ),
      MaintainiacQaReadinessItem(
        id: 'fake_gap',
        module: MaintainiacQaModule.inventory,
        description: 'This should fail because partial needs named gaps.',
        status: MaintainiacQaReadinessStatus.partial,
      ),
    ]);

    expect(
      ledger.validate(),
      contains('fake_ready marked ready without evidence'),
    );
    expect(ledger.validate(), contains('fake_gap marked partial without gaps'));
  });
}
