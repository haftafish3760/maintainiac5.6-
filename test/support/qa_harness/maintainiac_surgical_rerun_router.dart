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
      'maintainiac_individual_qa_command.dart',
      'maintainiac_individual_test_manifest.dart',
      'maintainiac_parser_consumer_gate.dart',
      'maintainiac_parser_release_command_plan.dart',
      'maintainiac_parser_regression_binding.dart',
      'maintainiac_surgical_selector_coverage.dart',
      'maintainiac_surgical_test_selector.dart',
      'maintainiac_surgical_granularity_contract.dart',
      'maintainiac_local_first_contract.dart',
      'maintainiac_mutation_guard.dart',
      'maintainiac_source_truth_gate.dart',
      'maintainiac_source_boundary.dart',
      'maintainiac_sensitive_field_registry.dart',
      'maintainiac_scope_policy.dart',
      'maintainiac_sync_lifecycle.dart',
      'maintainiac_sync_transport_policy.dart',
      'maintainiac_sync_conflict_contract.dart',
      'maintainiac_payment_contract.dart',
      'maintainiac_financial_ledger.dart',
      'maintainiac_financial_formula_registry.dart',
      'maintainiac_export_privacy.dart',
      'maintainiac_operating_directive_contract.dart',
      'maintainiac_qa_artifact_policy.dart',
      'maintainiac_qa_quality_gates.dart',
      'maintainiac_release_evidence_bundle.dart',
      'maintainiac_release_gate.dart',
      'maintainiac_source_audit_policy.dart',
      'maintainiac_audit_trail.dart',
      'maintainiac_qa_assertions.dart',
      'maintainiac_qa_environment.dart',
      'maintainiac_qa_builders.dart',
      'maintainiac_qa_fixtures.dart',
      'maintainiac_qa_scenario_runners.dart',
    }) {
      if (!rules.any((rule) => rule.changedPathContains == required)) {
        failures.add('missing rerun rule for $required');
      }
    }
    return failures;
  }

  List<String> commandsForChangedPaths(Iterable<String> changedPaths) {
    final selectorIds = selectorIdsForChangedPaths(changedPaths);
    return [
      for (final selector in registry.selectors)
        if (selectorIds.contains(selector.id)) selector.command,
    ];
  }

  Set<String> selectorIdsForChangedPaths(Iterable<String> changedPaths) {
    final selectorIds = <String>{};
    for (final path in changedPaths) {
      final normalizedPath = path.replaceAll('\\', '/');
      for (final selector in registry.selectors) {
        if (normalizedPath.endsWith(selector.file)) {
          selectorIds.add(selector.id);
        }
      }
      for (final rule in rules) {
        if (rule.matches(path)) selectorIds.addAll(rule.selectorIds);
      }
    }
    return selectorIds;
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
      id: 'individual_command_tool_changed',
      changedPathContains: 'maintainiac_individual_qa_command.dart',
      selectorIds: {
        'individual_command_tool_by_id',
        'individual_command_tool_changed_files',
        'individual_command_tool_all_selector_files',
        'individual_command_tool_rejects_unknown',
        'main_backbone_parser_visibility',
      },
      reason:
          'Individual command tool changes need exact lookup, changed-file, all-selector, negative, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'individual_test_manifest_changed',
      changedPathContains: 'maintainiac_individual_test_manifest.dart',
      selectorIds: {
        'individual_manifest_mirrors_selectors',
        'surgical_selector_registry_commands',
        'main_backbone_parser_visibility',
      },
      reason:
          'Individual manifest changes need selector parity and backbone checks.',
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
      id: 'surgical_selector_coverage_changed',
      changedPathContains: 'maintainiac_surgical_selector_coverage.dart',
      selectorIds: {
        'surgical_selector_coverage_required',
        'surgical_selector_coverage_rejects_missing',
        'surgical_selector_coverage_rejects_unlisted',
        'surgical_selector_coverage_all_declarations',
        'main_backbone_parser_visibility',
      },
      reason:
          'Selector coverage changes need positive, negative, declaration, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'surgical_selector_coverage_test_changed',
      changedPathContains: 'maintainiac_surgical_selector_coverage_test.dart',
      selectorIds: {
        'surgical_selector_coverage_required',
        'surgical_selector_coverage_rejects_missing',
        'surgical_selector_coverage_rejects_unlisted',
        'surgical_selector_coverage_all_declarations',
      },
      reason:
          'Selector coverage test edits need each individual coverage behavior rerun.',
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
        'surgical_granularity_real_declarations',
        'surgical_selector_registry_commands',
        'main_backbone_parser_visibility',
      },
      reason:
          'Granularity policy changes need positive, negative, selector, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'surgical_granularity_test_changed',
      changedPathContains:
          'maintainiac_surgical_granularity_contract_test.dart',
      selectorIds: {
        'surgical_granularity_individual',
        'surgical_granularity_rejects_batch',
        'surgical_granularity_real_declarations',
      },
      reason:
          'Granularity test edits need each individual granularity behavior rerun.',
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
      id: 'financial_ledger_changed',
      changedPathContains: 'maintainiac_financial_ledger.dart',
      selectorIds: {
        'financial_ledger_expense_totals',
        'financial_ledger_inventory_consumption',
        'financial_ledger_rejects_unsafe_money',
        'main_backbone_parser_visibility',
      },
      reason:
          'Financial ledger changes need deterministic totals, inventory cost, unsafe money, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'financial_formula_registry_changed',
      changedPathContains: 'maintainiac_financial_formula_registry.dart',
      selectorIds: {
        'financial_formula_registry_labels',
        'financial_formula_registry_rejects_unsafe',
        'main_backbone_parser_visibility',
      },
      reason:
          'Financial formula registry changes need deterministic formula and unsafe formula checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'export_privacy_changed',
      changedPathContains: 'maintainiac_export_privacy.dart',
      selectorIds: {
        'export_privacy_accepts_owned_records',
        'export_privacy_catches_cross_account',
        'export_privacy_sanitizes_private_fields',
        'export_privacy_matrix_blocks_leaks',
        'export_privacy_matrix_rejects_gaps',
        'main_backbone_parser_visibility',
      },
      reason:
          'Export privacy changes need owned export, cross-account, redaction, matrix, gap, and backbone checks.',
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
      id: 'release_gate_tool_changed',
      changedPathContains: 'maintainiac_release_gate.dart',
      selectorIds: {
        'release_gate_tool_commands',
        'release_gate_tool_json',
        'main_backbone_parser_visibility',
      },
      reason:
          'Release gate tool changes need command, JSON evidence, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'release_evidence_bundle_changed',
      changedPathContains: 'maintainiac_release_evidence_bundle.dart',
      selectorIds: {
        'release_evidence_required_proof',
        'release_evidence_rejects_bad_proof',
        'main_backbone_parser_visibility',
      },
      reason:
          'Release evidence changes need exact proof, negative proof, and backbone checks.',
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
      id: 'qa_artifact_policy_changed',
      changedPathContains: 'maintainiac_qa_artifact_policy.dart',
      selectorIds: {
        'qa_artifact_policy_accepts_redacted',
        'qa_artifact_policy_rejects_private_raw',
        'qa_artifact_policy_rejects_wrong_drives',
        'main_backbone_parser_visibility',
      },
      reason:
          'Artifact policy changes need redaction, privacy, wrong-drive, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'mutation_guard_changed',
      changedPathContains: 'maintainiac_mutation_guard.dart',
      selectorIds: {
        'mutation_guard_allows_derived_only',
        'mutation_guard_blocks_source_mutation',
        'mutation_guard_scoped_source_ops',
        'mutation_guard_matrix_side_effects',
        'mutation_guard_matrix_rejects_mismatch',
        'main_backbone_parser_visibility',
      },
      reason:
          'Mutation guard changes need derived-output, source-scope, matrix, negative, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'local_first_contract_changed',
      changedPathContains: 'maintainiac_local_first_contract.dart',
      selectorIds: {
        'local_first_accepts_hive_before_mirror',
        'local_first_rejects_mirror_first',
        'local_first_rejects_unsafe_writes',
        'main_backbone_parser_visibility',
      },
      reason:
          'Local-first contract changes need Hive-before-mirror, negative, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'source_truth_gate_changed',
      changedPathContains: 'maintainiac_source_truth_gate.dart',
      selectorIds: {
        'source_truth_gate_protects_roles',
        'source_truth_gate_rejects_mutations',
        'main_backbone_parser_visibility',
      },
      reason:
          'Source-truth gate changes need role coverage, negative mutation, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'source_boundary_changed',
      changedPathContains: 'maintainiac_source_boundary.dart',
      selectorIds: {
        'source_boundary_catches_live_services',
        'source_boundary_allows_emulators',
        'source_boundary_skips_build_folders',
        'main_backbone_parser_visibility',
      },
      reason:
          'Source boundary changes need live-service, emulator, build-folder, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'sensitive_field_registry_changed',
      changedPathContains: 'maintainiac_sensitive_field_registry.dart',
      selectorIds: {
        'sensitive_field_registry_covers_forbidden',
        'sensitive_field_registry_rejects_bad_classes',
        'main_backbone_parser_visibility',
      },
      reason:
          'Sensitive field registry changes need forbidden-class, duplicate/missing-class, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'scope_policy_changed',
      changedPathContains: 'maintainiac_scope_policy.dart',
      selectorIds: {
        'scope_policy_owner_vehicle_permission',
        'scope_policy_denies_cross_account_vehicle',
        'scope_policy_employee_permission_match',
        'scope_policy_matrix_denials',
        'scope_policy_matrix_rejects_missing_reasons',
        'main_backbone_parser_visibility',
      },
      reason:
          'Scope policy changes need owner, denial, employee, matrix, explanation, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'sync_lifecycle_changed',
      changedPathContains: 'maintainiac_sync_lifecycle.dart',
      selectorIds: {
        'sync_lifecycle_local_dirty_before_mirror',
        'sync_lifecycle_failed_retry_queue',
        'sync_lifecycle_rejects_unknown_transition',
        'main_backbone_parser_visibility',
      },
      reason:
          'Sync lifecycle changes need local-dirty, retry, transition, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'sync_transport_policy_changed',
      changedPathContains: 'maintainiac_sync_transport_policy.dart',
      selectorIds: {
        'sync_transport_covers_paths',
        'sync_transport_rejects_unsafe_networks',
        'main_backbone_parser_visibility',
      },
      reason:
          'Sync transport changes need allowed-path, blocked-network, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'sync_conflict_contract_changed',
      changedPathContains: 'maintainiac_sync_conflict_contract.dart',
      selectorIds: {
        'sync_conflict_allows_safe_merge',
        'sync_conflict_protects_confirmed_financial',
        'sync_conflict_requires_review_audit',
        'sync_conflict_rejects_unsafe_remote',
        'main_backbone_parser_visibility',
      },
      reason:
          'Sync conflict changes need safe-merge, local-financial, review-audit, unsafe-remote, and backbone checks.',
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
    MaintainiacSurgicalRerunRule(
      id: 'qa_fixtures_changed',
      changedPathContains: 'maintainiac_qa_fixtures.dart',
      selectorIds: {
        'qa_fixtures_accept_reviewed',
        'qa_fixtures_reject_weak',
        'main_backbone_parser_visibility',
      },
      reason:
          'Shared fixture changes need positive, negative, and backbone checks.',
    ),
    MaintainiacSurgicalRerunRule(
      id: 'qa_scenario_runners_changed',
      changedPathContains: 'maintainiac_qa_scenario_runners.dart',
      selectorIds: {
        'scenario_runner_sync',
        'scenario_runner_security',
        'scenario_runner_financial',
        'scenario_runner_performance',
        'scenario_runner_accessibility_localization',
        'scenario_runner_cost_quota',
      },
      reason:
          'Scenario runner changes need sync, security, financial, performance, accessibility/localization, and cost/quota checks.',
    ),
  ],
);
