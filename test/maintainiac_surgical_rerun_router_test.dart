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

  test('surgical rerun router maps changed test files to their selectors', () {
    final commands = maintainiacSurgicalRerunRouter.commandsForChangedPaths([
      'test/maintainiac_payment_contract_test.dart',
    ]);
    final joined = commands.join('\n');

    expect(joined, contains('payment ledger policy proves'));
    expect(joined, contains('payment contract balances payments refunds'));
    expect(joined, contains('payment contract rejects sensitive'));
    expect(joined, isNot(contains('main Maintainiac QA backbone')));
    expect(
      commands.every((command) => command.contains('--plain-name')),
      isTrue,
    );
  });

  test('surgical rerun router maps source boundary changes to every guard', () {
    final selectorIds = maintainiacSurgicalRerunRouter
        .selectorIdsForChangedPaths([
          'test/support/qa_harness/maintainiac_source_boundary.dart',
        ]);

    expect(selectorIds, contains('source_boundary_catches_live_services'));
    expect(selectorIds, contains('source_boundary_allows_emulators'));
    expect(selectorIds, contains('source_boundary_catches_ocr_camera_imports'));
    expect(selectorIds, contains('source_boundary_skips_build_folders'));
    expect(selectorIds, contains('main_backbone_parser_visibility'));
  });

  test('surgical rerun router maps late added guard selectors', () {
    final selectorIds = maintainiacSurgicalRerunRouter
        .selectorIdsForChangedPaths([
          'test/support/qa_harness/maintainiac_qa_run_ledger.dart',
          'test/support/qa_harness/maintainiac_release_evidence_bundle.dart',
          'test/support/qa_harness/maintainiac_source_audit_policy.dart',
          'test/support/qa_harness/maintainiac_qa_artifact_policy.dart',
          'test/support/qa_harness/maintainiac_sensitive_field_registry.dart',
        ]);

    expect(selectorIds, contains('qa_run_ledger_rejects_broad_commands'));
    expect(
      selectorIds,
      contains('release_evidence_requires_targeted_analyzer'),
    );
    expect(selectorIds, contains('source_audit_rejects_unsafe_limits'));
    expect(selectorIds, contains('source_audit_rejects_non_production_debt'));
    expect(selectorIds, contains('qa_artifact_policy_rejects_duplicate_paths'));
    expect(
      selectorIds,
      contains('sensitive_field_registry_rejects_placeholders'),
    );
  });

  test(
    'surgical rerun router maps individual command tool reporting guards',
    () {
      final selectorIds = maintainiacSurgicalRerunRouter
          .selectorIdsForChangedPaths([
            'test/support/qa_harness/maintainiac_individual_qa_command.dart',
          ]);

      expect(selectorIds, contains('individual_command_tool_by_id'));
      expect(selectorIds, contains('individual_command_tool_by_risk'));
      expect(
        selectorIds,
        contains('individual_command_tool_changed_file_all_selectors'),
      );
      expect(selectorIds, contains('individual_command_tool_all_selector_ids'));
      expect(
        selectorIds,
        contains('individual_command_tool_changed_unique_surgical'),
      );
      expect(selectorIds, contains('main_backbone_parser_visibility'));
    },
  );

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

  test('surgical rerun router outputs only single behavior commands', () {
    const router = maintainiacSurgicalRerunRouter;
    const registry = maintainiacSurgicalTestSelectorRegistry;
    final commands = router.commandsForChangedPaths([
      'test/support/qa_harness/maintainiac_surgical_test_selector.dart',
      'test/support/qa_harness/maintainiac_qa_readiness.dart',
      'test/maintainiac_surgical_selector_coverage_test.dart',
    ]);

    expect(commands, isNotEmpty);
    for (final command in commands) {
      final selector = registry.selectors.singleWhere(
        (candidate) => candidate.command == command,
      );

      expect(selector.scope, MaintainiacSurgicalTestScope.singleBehavior);
      expect(command, startsWith('flutter test test/'));
      expect(command, contains(' --plain-name '));
      expect(command, isNot(contains('&&')));
      expect(command, isNot(contains(';')));
      expect(command.indexOf(' flutter test ', 1), -1);
    }
  });
}
