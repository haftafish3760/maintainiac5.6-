import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('surgical rerun router maps changed files to individual commands', () {
    const router = maintainiacSurgicalRerunRouter;

    expect(router.validate(), isEmpty);
    final commands = router.commandsForChangedPaths([
      'test/support/qa_harness/maintainiac_inventory_parser_consumer_contract.dart',
    ]);
    final selectorIds = router.selectorIdsForChangedPaths([
      'test/support/qa_harness/maintainiac_inventory_parser_consumer_contract.dart',
    ]);

    expect(commands, isNotEmpty);
    expect(selectorIds, contains('inventory_consumer_family_labels'));
    expect(
      commands.every((command) => command.contains('--plain-name')),
      isTrue,
    );
    expect(commands.join('\n'), contains('inventory parser consumer labels'));
    expect(commands.join('\n'), contains('main Maintainiac QA backbone'));
  });

  test('surgical rerun router rejects unknown selector references', () {
    const router = MaintainiacSurgicalRerunRouter(
      registry: maintainiacSurgicalTestSelectorRegistry,
      rules: [
        MaintainiacSurgicalRerunRule(
          id: 'bad',
          changedPathContains:
              'maintainiac_inventory_parser_consumer_contract.dart',
          selectorIds: {'missing_selector'},
          reason: '',
        ),
      ],
    );

    final failures = router.validate().join('\n');

    expect(failures, contains('bad missing reason'));
    expect(
      failures,
      contains('bad references unknown selector missing_selector'),
    );
    expect(
      failures,
      contains(
        'missing rerun rule for maintainiac_expense_parser_consumer_contract.dart',
      ),
    );
  });

  test('surgical rerun router maps payment and granularity changes', () {
    final commands = maintainiacSurgicalRerunRouter.commandsForChangedPaths([
      'test/support/qa_harness/maintainiac_payment_contract.dart',
      'test/support/qa_harness/maintainiac_surgical_granularity_contract.dart',
    ]);
    final joined = commands.join('\n');

    expect(joined, contains('payment ledger policy proves'));
    expect(joined, contains('payment ledger policy rejects'));
    expect(joined, contains('surgical granularity contract keeps'));
    expect(joined, contains('surgical granularity contract rejects'));
    expect(
      commands.every((command) => command.contains('--plain-name')),
      isTrue,
    );
  });

  test('surgical rerun router dedupes overlapping changed paths', () {
    final commands = maintainiacSurgicalRerunRouter.commandsForChangedPaths([
      'test/support/qa_harness/maintainiac_surgical_granularity_contract.dart',
      'test/support/qa_harness/maintainiac_surgical_granularity_contract.dart',
    ]);
    final ids = maintainiacSurgicalRerunRouter.selectorIdsForChangedPaths([
      'test/support/qa_harness/maintainiac_surgical_granularity_contract.dart',
      'test/support/qa_harness/maintainiac_surgical_granularity_contract.dart',
    ]);

    expect(commands.length, ids.length);
    expect(commands.toSet(), hasLength(commands.length));
    expect(ids, contains('surgical_granularity_individual'));
    expect(ids, contains('surgical_granularity_rejects_batch'));
  });
}
