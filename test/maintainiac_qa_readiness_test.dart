import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('QA readiness ledger tracks completed backbone and remaining gaps', () {
    final ledger = MaintainiacQaReadinessLedger.currentBackbone();

    expect(ledger.validate(), isEmpty);
    expect(ledger.releaseReady, isFalse);
    expect(ledger.countsByStatus['ready'], greaterThanOrEqualTo(5));
    expect(ledger.countsByStatus['partial'], greaterThanOrEqualTo(2));
    expect(ledger.countsByStatus['missing'], greaterThanOrEqualTo(1));
    expect(ledger.toJson().toString(), contains('expense_parser_consumer'));
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
