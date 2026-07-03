import 'maintainiac_surgical_test_selector.dart';

class MaintainiacSurgicalRerunRule {
  const MaintainiacSurgicalRerunRule({
    required this.id,
    required this.changedPathContains,
    required this.selectorIds,
    required this.reason,
  });

  final String id;
  final String changedPathContains;
  final Set<String> selectorIds;
  final String reason;

  List<String> validate(Set<String> knownSelectorIds) {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('rerun rule missing id');
    if (changedPathContains.trim().isEmpty) {
      failures.add('$id missing changed path matcher');
    }
    if (selectorIds.isEmpty) failures.add('$id missing selector ids');
    if (reason.trim().isEmpty) failures.add('$id missing reason');
    for (final selectorId in selectorIds) {
      if (!knownSelectorIds.contains(selectorId)) {
        failures.add('$id references unknown selector $selectorId');
      }
    }
    return failures;
  }

  bool matches(String path) {
    return path.replaceAll('\\', '/').contains(changedPathContains);
  }
}

class MaintainiacSurgicalRerunRouter {
  const MaintainiacSurgicalRerunRouter({
    required this.registry,
    required this.rules,
  });

  final MaintainiacSurgicalTestSelectorRegistry registry;
  final List<MaintainiacSurgicalRerunRule> rules;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final knownSelectorIds = {
      for (final selector in registry.selectors) selector.id,
    };
    for (final rule in rules) {
      if (!ids.add(rule.id)) {
        failures.add('duplicate rerun rule ${rule.id}');
      }
      failures.addAll(rule.validate(knownSelectorIds));
    }
    for (final required in {
      'maintainiac_inventory_parser_consumer_contract.dart',
      'maintainiac_expense_parser_consumer_contract.dart',
      'maintainiac_parser_consumer_gate.dart',
      'maintainiac_parser_release_command_plan.dart',
      'maintainiac_parser_regression_binding.dart',
      'maintainiac_surgical_test_selector.dart',
      'maintainiac_surgical_granularity_contract.dart',
      'maintainiac_payment_contract.dart',
      'maintainiac_operating_directive_contract.dart',
      'maintainiac_qa_quality_gates.dart',
      'maintainiac_source_audit_policy.dart',
      'maintainiac_audit_trail.dart',
      'maintainiac_qa_assertions.dart',
      'maintainiac_qa_environment.dart',
      'maintainiac_qa_builders.dart',
    }) {
      if (!rules.any((rule) => rule.changedPathContains == required)) {
        failures.add('missing rerun rule for $required');
      }
    }
    return failures;
  }

  List<String> commandsForChangedPaths(Iterable<String> changedPaths) {
    final selectorIds = <String>{};
    for (final path in changedPaths) {
      for (final rule in rules) {
        if (rule.matches(path)) selectorIds.addAll(rule.selectorIds);
      }
    }
    return [
      for (final selector in registry.selectors)
        if (selectorIds.contains(selector.id)) selector.command,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'ruleCount': rules.length,
      'selectorCount': registry.selectors.length,
      'rules': [
        for (final rule in rules)
          {
            'id': rule.id,
            'changedPathContains': rule.changedPathContains,
            'selectorIds': rule.selectorIds.toList()..sort(),
            'reason': rule.reason,
          },
      ],
    };
  }
}

const maintainiacSurgicalRerunRouter = MaintainiacSurgicalRerunRouter(
  registry: maintainiacSurgicalTestSelectorRegistry,
  rules: [
    MaintainiacSurgicalRerunRule(
      id: 'inventory_consumer_contract_changed',
      changedPathContains:
          'maintainiac_inventory_parser_consumer_contract.dart',
      selectorIds: {
        'inventory_consumer_family_labels',
        'inventory_consumer_file_refs',
        'inventory_consumer_focused_offline',
        'inventory_consumer_fake_narrow',
        'parser_consumer_gate_combined',
        'main_backbone_parser_visibility',
      },
      reason:
          'Inventory consumer contract changes need inventory and backbone visibility checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'expense_consumer_contract_changed',
      changedPathContains: 'maintainiac_expense_parser_consumer_contract.dart',
      selectorIds: {
        'expense_consumer_family_labels',
        'expense_consumer_file_refs',
        'expense_consumer_focused_no_camera',
        'expense_consumer_unsafe_readiness',
        'parser_consumer_gate_combined',
        'main_backbone_parser_visibility',
      },
      reason:
          'Expense consumer contract changes need expense and backbone visibility checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'parser_consumer_gate_changed',
      changedPathContains: 'maintainiac_parser_consumer_gate.dart',
      selectorIds: {
        'parser_consumer_gate_combined',
        'parser_consumer_gate_rejects_unsafe',
        'main_backbone_parser_visibility',
      },
      reason:
          'Parser gate changes need positive, negative, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'parser_release_command_plan_changed',
      changedPathContains: 'maintainiac_parser_release_command_plan.dart',
      selectorIds: {
        'parser_release_command_covers_families',
        'parser_release_command_rejects_unsafe',
        'main_backbone_parser_visibility',
      },
      reason:
          'Command plan changes need coverage, negative safety, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'parser_regression_binding_changed',
      changedPathContains: 'maintainiac_parser_regression_binding.dart',
      selectorIds: {
        'parser_regression_bindings',
        'parser_regression_rejects_bad_bindings',
        'main_backbone_parser_visibility',
      },
      reason:
          'Regression binding changes need positive, negative, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'surgical_selector_changed',
      changedPathContains: 'maintainiac_surgical_test_selector.dart',
      selectorIds: {
        'surgical_selector_registry_commands',
        'surgical_selector_registry_rejects_bad',
        'parser_release_command_covers_families',
        'main_backbone_parser_visibility',
      },
      reason:
          'Selector changes need selector, command-plan, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'surgical_granularity_changed',
      changedPathContains: 'maintainiac_surgical_granularity_contract.dart',
      selectorIds: {
        'surgical_granularity_individual',
        'surgical_granularity_rejects_batch',
        'surgical_selector_registry_commands',
        'main_backbone_parser_visibility',
      },
      reason:
          'Granularity policy changes need positive, negative, selector, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'payment_contract_changed',
      changedPathContains: 'maintainiac_payment_contract.dart',
      selectorIds: {
        'payment_ledger_balance_policy',
        'payment_ledger_rejects_cross_account',
        'main_backbone_parser_visibility',
      },
      reason:
          'Payment contract changes need financial balance, cross-account safety, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'operating_directive_contract_changed',
      changedPathContains: 'maintainiac_operating_directive_contract.dart',
      selectorIds: {
        'operating_directive_matches_docs',
        'operating_directive_rejects_missing_rules',
        'main_backbone_parser_visibility',
      },
      reason:
          'Operating directive contract changes need doc, negative, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'quality_gates_changed',
      changedPathContains: 'maintainiac_qa_quality_gates.dart',
      selectorIds: {
        'quality_gate_release_dimensions',
        'quality_gate_rejects_partial',
        'main_backbone_parser_visibility',
      },
      reason:
          'Quality gate changes need release-dimension, negative, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'source_audit_policy_changed',
      changedPathContains: 'maintainiac_source_audit_policy.dart',
      selectorIds: {
        'source_audit_line_caps',
        'source_audit_debt_ledger',
        'main_backbone_parser_visibility',
      },
      reason:
          'Source audit changes need line-cap, known-debt, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'audit_trail_changed',
      changedPathContains: 'maintainiac_audit_trail.dart',
      selectorIds: {
        'audit_trail_ordered_complete',
        'audit_trail_user_confirmation',
        'audit_trail_rejects_bad_events',
        'main_backbone_parser_visibility',
      },
      reason:
          'Audit trail changes need ordered, confirmation, negative, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'qa_assertions_changed',
      changedPathContains: 'maintainiac_qa_assertions.dart',
      selectorIds: {
        'qa_assertions_accept_safe_behavior',
        'qa_assertions_reject_unsafe_behavior',
        'main_backbone_parser_visibility',
      },
      reason:
          'Shared assertion changes need positive, negative, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'qa_environment_changed',
      changedPathContains: 'maintainiac_qa_environment.dart',
      selectorIds: {
        'qa_environment_local_truth',
        'qa_environment_side_effect_fakes',
        'main_backbone_parser_visibility',
      },
      reason:
          'Shared environment changes need fake-store, side-effect, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'qa_builders_changed',
      changedPathContains: 'maintainiac_qa_builders.dart',
      selectorIds: {
        'qa_builders_record_families',
        'main_backbone_parser_visibility',
      },
      reason: 'Shared builder changes need record-family and backbone checks.',
    ),
  ],
);
