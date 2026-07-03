enum MaintainiacSurgicalTestScope { singleBehavior, moduleSmoke, releaseGate }

class MaintainiacSurgicalTestSelector {
  const MaintainiacSurgicalTestSelector({
    required this.id,
    required this.scope,
    required this.file,
    required this.plainName,
    required this.reason,
    required this.tags,
  });

  final String id;
  final MaintainiacSurgicalTestScope scope;
  final String file;
  final String plainName;
  final String reason;
  final Set<String> tags;

  String get command => 'flutter test $file --plain-name "$plainName"';

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) {
      failures.add('surgical selector missing id');
    }
    if (!file.startsWith('test/') || !file.endsWith('.dart')) {
      failures.add('$id must target one Dart test file');
    }
    if (plainName.trim().isEmpty) {
      failures.add('$id missing plain-name selector');
    }
    if (reason.trim().isEmpty) {
      failures.add('$id missing reason');
    }
    if (tags.length < 2) {
      failures.add('$id needs searchable tags');
    }
    final lower = command.toLowerCase();
    if (lower.contains('camera') ||
        lower.contains('ocr') ||
        lower.contains('mlkit') ||
        lower.contains('googlevision') ||
        lower.contains('firebase') ||
        lower.contains('firestore')) {
      failures.add(
        '$id selector must stay offline and outside OCR/camera/live Firebase',
      );
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'scope': scope.name,
      'file': file,
      'plainName': plainName,
      'command': command,
      'reason': reason,
      'tags': tags.toList()..sort(),
    };
  }
}

class MaintainiacSurgicalTestSelectorRegistry {
  const MaintainiacSurgicalTestSelectorRegistry(this.selectors);

  final List<MaintainiacSurgicalTestSelector> selectors;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final commandSet = <String>{};
    final tags = <String>{};
    for (final selector in selectors) {
      if (!ids.add(selector.id)) {
        failures.add('duplicate surgical selector ${selector.id}');
      }
      if (!commandSet.add(selector.command)) {
        failures.add('duplicate surgical command ${selector.command}');
      }
      tags.addAll(selector.tags);
      failures.addAll(selector.validate());
    }
    if (!selectors.any(
      (selector) =>
          selector.scope == MaintainiacSurgicalTestScope.singleBehavior,
    )) {
      failures.add('surgical registry missing single-behavior selectors');
    }
    for (final required in {
      'inventory',
      'expenses',
      'parser-consumer',
      'privacy',
      'source-of-truth',
      'regression',
    }) {
      if (!tags.contains(required)) {
        failures.add('surgical registry missing tag $required');
      }
    }
    return failures;
  }

  List<String> commandsForTag(String tag) {
    return [
      for (final selector in selectors)
        if (selector.tags.contains(tag)) selector.command,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'selectorCount': selectors.length,
      'singleBehaviorCount': selectors
          .where(
            (selector) =>
                selector.scope == MaintainiacSurgicalTestScope.singleBehavior,
          )
          .length,
      'selectors': [for (final selector in selectors) selector.toJson()],
    };
  }
}

const maintainiacSurgicalTestSelectorRegistry = MaintainiacSurgicalTestSelectorRegistry([
  MaintainiacSurgicalTestSelector(
    id: 'inventory_consumer_family_labels',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_inventory_parser_consumer_test.dart',
    plainName: 'inventory parser consumer labels broad release-one QA families',
    reason:
        'Run only the inventory parser consumer breadth contract after family edits.',
    tags: {'inventory', 'parser-consumer', 'release-one'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'inventory_consumer_file_refs',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_inventory_parser_consumer_test.dart',
    plainName: 'inventory parser consumer references existing QA support files',
    reason:
        'Run only the inventory parser file-reference check after moving QA files.',
    tags: {'inventory', 'parser-consumer', 'source-of-truth'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'inventory_consumer_focused_offline',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_inventory_parser_consumer_test.dart',
    plainName: 'inventory parser consumer keeps commands focused and offline',
    reason:
        'Run only the inventory parser command safety check after command edits.',
    tags: {'inventory', 'parser-consumer', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'inventory_consumer_fake_narrow',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_inventory_parser_consumer_test.dart',
    plainName: 'inventory parser consumer rejects fake narrow coverage',
    reason:
        'Run only the inventory parser negative coverage check after readiness edits.',
    tags: {'inventory', 'parser-consumer', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'expense_consumer_family_labels',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_expense_parser_consumer_test.dart',
    plainName: 'expense parser consumer labels broad release-one QA families',
    reason:
        'Run only the expense parser consumer breadth contract after family edits.',
    tags: {'expenses', 'parser-consumer', 'release-one'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'expense_consumer_file_refs',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_expense_parser_consumer_test.dart',
    plainName: 'expense parser consumer references existing QA files',
    reason:
        'Run only the expense parser file-reference check after moving QA files.',
    tags: {'expenses', 'parser-consumer', 'source-of-truth'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'expense_consumer_focused_no_camera',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_expense_parser_consumer_test.dart',
    plainName:
        'expense parser consumer keeps commands focused and provider-free',
    reason:
        'Run only the expense parser command boundary check after command edits.',
    tags: {'expenses', 'parser-consumer', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'expense_consumer_unsafe_readiness',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_expense_parser_consumer_test.dart',
    plainName: 'expense parser consumer rejects unsafe fake readiness',
    reason:
        'Run only the expense parser negative safety contract after policy edits.',
    tags: {'expenses', 'parser-consumer', 'privacy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'parser_consumer_gate_combined',
    scope: MaintainiacSurgicalTestScope.moduleSmoke,
    file: 'test/maintainiac_parser_consumer_gate_test.dart',
    plainName:
        'parser consumer gate validates inventory and expense consumers together',
    reason:
        'Run only the combined parser consumer gate after inventory or expense consumer changes.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'parser_consumer_gate_rejects_unsafe',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_parser_consumer_gate_test.dart',
    plainName: 'parser consumer gate rejects unsafe or narrow consumers',
    reason:
        'Run only the parser consumer gate negative safety check after policy edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'parser_regression_bindings',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_parser_regression_binding_test.dart',
    plainName:
        'parser regression bindings cover required consumer risk families',
    reason:
        'Run only parser regression binding coverage after bug fixture changes.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'parser_regression_rejects_bad_bindings',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_parser_regression_binding_test.dart',
    plainName:
        'parser regression bindings reject duplicate or unowned regressions',
    reason:
        'Run only the parser regression negative contract after registry edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'parser_release_command_covers_families',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_parser_release_command_plan_test.dart',
    plainName:
        'parser release command plan covers every parser consumer family',
    reason:
        'Run only the command-plan coverage check after release command edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'parser_release_command_rejects_unsafe',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_parser_release_command_plan_test.dart',
    plainName:
        'parser release command plan rejects unsafe commands and missing tiers',
    reason:
        'Run only the command-plan negative check after command policy edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_selector_registry_commands',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_test_selector_test.dart',
    plainName:
        'surgical selector registry exposes individual plain-name commands',
    reason:
        'Run only the selector registry positive check after adding selectors.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_selector_registry_rejects_bad',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_test_selector_test.dart',
    plainName: 'surgical selector registry rejects broad or unsafe selectors',
    reason:
        'Run only the selector registry negative check after selector policy edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'individual_manifest_mirrors_selectors',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_individual_test_manifest_test.dart',
    plainName:
        'individual test manifest mirrors surgical selector commands exactly',
    reason:
        'Run only the manifest/selector exact-match check after command metadata edits.',
    tags: {'parser-consumer', 'tooling', 'regression', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_rerun_router_maps_changes',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_rerun_router_test.dart',
    plainName:
        'surgical rerun router maps changed files to individual commands',
    reason:
        'Run only the rerun-router positive mapping check after router rule edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'source-of-truth'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_rerun_router_rejects_bad',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_rerun_router_test.dart',
    plainName: 'surgical rerun router rejects unknown selector references',
    reason:
        'Run only the rerun-router negative reference check after router policy edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_rerun_router_payment_granularity',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_rerun_router_test.dart',
    plainName: 'surgical rerun router maps payment and granularity changes',
    reason:
        'Run only the payment/granularity rerun mapping check after router edits.',
    tags: {'payments', 'parser-consumer', 'source-of-truth', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_granularity_individual',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_granularity_contract_test.dart',
    plainName:
        'surgical granularity contract keeps tests individually runnable',
    reason:
        'Run only the surgical granularity positive guard after selector policy edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_granularity_rejects_batch',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_granularity_contract_test.dart',
    plainName: 'surgical granularity contract rejects broad batch selectors',
    reason:
        'Run only the surgical granularity negative guard after selector policy edits.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'surgical_granularity_real_declarations',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_surgical_granularity_contract_test.dart',
    plainName: 'surgical selectors point at real individual test declarations',
    reason:
        'Run only the real-test-declaration audit after selector or test renames.',
    tags: {'parser-consumer', 'release-gate', 'regression', 'tooling'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'payment_ledger_balance_policy',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_payment_contract_test.dart',
    plainName:
        'payment ledger policy proves invoice balance without source mutation',
    reason:
        'Run only the payment ledger balance policy after payment contract edits.',
    tags: {'payments', 'financial', 'source-of-truth', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'payment_ledger_rejects_cross_account',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_payment_contract_test.dart',
    plainName: 'payment ledger policy rejects cross-account and overpay risks',
    reason:
        'Run only the payment ledger negative safety check after payment contract edits.',
    tags: {'payments', 'financial', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'operating_directive_matches_docs',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_operating_directive_contract_test.dart',
    plainName: 'operating directive contract matches production docs',
    reason:
        'Run only the operating directive doc contract after directive edits.',
    tags: {'docs', 'quality-gate', 'source-of-truth', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'operating_directive_rejects_missing_rules',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_operating_directive_contract_test.dart',
    plainName: 'operating directive contract rejects missing production rules',
    reason:
        'Run only the operating directive negative rule check after directive edits.',
    tags: {'docs', 'quality-gate', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'quality_gate_release_dimensions',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_quality_gates_test.dart',
    plainName: 'quality gate matrix covers release required QA dimensions',
    reason:
        'Run only the quality-gate release dimension check after gate edits.',
    tags: {'quality-gate', 'release-gate', 'regression', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'quality_gate_rejects_partial',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_quality_gates_test.dart',
    plainName: 'quality gate matrix rejects partial release dimensions',
    reason: 'Run only the quality-gate negative check after gate edits.',
    tags: {'quality-gate', 'release-gate', 'regression', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'release_gate_tool_commands',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_release_gate_tool_test.dart',
    plainName: 'release gate tool emits surgical command plan',
    reason: 'Run only the release gate command output check after tool edits.',
    tags: {'release-gate', 'tooling', 'command-plan'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'release_gate_tool_json',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_release_gate_tool_test.dart',
    plainName: 'release gate tool emits JSON evidence',
    reason: 'Run only the release gate JSON evidence check after tool edits.',
    tags: {'release-gate', 'tooling', 'evidence'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'release_evidence_required_proof',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_release_evidence_bundle_test.dart',
    plainName: 'release evidence bundle records required milestone proof',
    reason:
        'Run only the release evidence positive proof check after evidence edits.',
    tags: {'release-gate', 'tooling', 'evidence'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'release_evidence_rejects_bad_proof',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_release_evidence_bundle_test.dart',
    plainName: 'release evidence bundle rejects broad or missing proof',
    reason:
        'Run only the release evidence negative proof check after evidence edits.',
    tags: {'release-gate', 'tooling', 'regression', 'security'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'source_audit_line_caps',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_source_audit_policy_test.dart',
    plainName: 'source audit policy separates production and QA line caps',
    reason: 'Run only the source-audit line-cap policy after audit edits.',
    tags: {'source-audit', 'quality-gate', 'modularity', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'source_audit_debt_ledger',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_source_audit_policy_test.dart',
    plainName:
        'source audit debt ledger tracks current oversized production files',
    reason:
        'Run only the source-audit debt scan after line-count debt changes.',
    tags: {'source-audit', 'quality-gate', 'modularity', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'audit_trail_ordered_complete',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_audit_trail_test.dart',
    plainName: 'audit trail probe validates ordered complete audit events',
    reason:
        'Run only the audit event ordering check after audit support edits.',
    tags: {'audit', 'source-of-truth', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'audit_trail_user_confirmation',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_audit_trail_test.dart',
    plainName:
        'audit trail probe proves user confirmation outranks suggestions',
    reason:
        'Run only the user-confirmation audit check after parser/review audit edits.',
    tags: {'audit', 'review-safety', 'source-of-truth', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'audit_trail_rejects_bad_events',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_audit_trail_test.dart',
    plainName:
        'audit trail probe rejects duplicate incomplete or unordered events',
    reason:
        'Run only the audit negative contract after audit validation edits.',
    tags: {'audit', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_assertions_accept_safe_behavior',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_assertions_test.dart',
    plainName: 'shared QA assertions accept safe source truth behavior',
    reason:
        'Run only the positive shared assertion contract after assertion edits.',
    tags: {'assertions', 'source-of-truth', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_assertions_reject_unsafe_behavior',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_assertions_test.dart',
    plainName: 'shared QA assertions reject source truth and privacy failures',
    reason:
        'Run only the negative shared assertion contract after assertion edits.',
    tags: {'assertions', 'security', 'privacy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_environment_local_truth',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_environment_test.dart',
    plainName: 'QA environment fakes preserve local truth and mirror copies',
    reason:
        'Run only the fake local/mirror store check after environment edits.',
    tags: {'environment', 'source-of-truth', 'sync', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_environment_side_effect_fakes',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_environment_test.dart',
    plainName:
        'QA environment exposes permissions device and side-effect fakes',
    reason:
        'Run only the fake permissions/device/side-effect check after environment edits.',
    tags: {'environment', 'security', 'privacy', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_builders_record_families',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_environment_test.dart',
    plainName: 'QA builders create every shared record family',
    reason: 'Run only the shared builder family check after builder edits.',
    tags: {'builders', 'environment', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_fixtures_accept_reviewed',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_fixtures_test.dart',
    plainName: 'fixture catalog accepts reviewed behavior fixtures',
    reason: 'Run only the positive fixture catalog check after fixture edits.',
    tags: {'fixtures', 'regression', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'qa_fixtures_reject_weak',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_fixtures_test.dart',
    plainName: 'fixture catalog rejects duplicate or unreviewed weak evidence',
    reason: 'Run only the negative fixture catalog check after fixture edits.',
    tags: {'fixtures', 'security', 'regression'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'scenario_runner_sync',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_scenario_runners_test.dart',
    plainName: 'sync scenario runner proves local-first mirror behavior',
    reason: 'Run only the sync scenario runner after scenario edits.',
    tags: {'scenario-runner', 'sync', 'source-of-truth', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'scenario_runner_security',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_scenario_runners_test.dart',
    plainName: 'security scenario runner proves privacy and scope behavior',
    reason: 'Run only the security scenario runner after scenario edits.',
    tags: {'scenario-runner', 'security', 'privacy', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'scenario_runner_financial',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_scenario_runners_test.dart',
    plainName: 'financial scenario runner proves deterministic money behavior',
    reason: 'Run only the financial scenario runner after scenario edits.',
    tags: {'scenario-runner', 'financial', 'regression', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'scenario_runner_performance',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_scenario_runners_test.dart',
    plainName: 'performance scenario runner proves large-data budgets',
    reason: 'Run only the performance scenario runner after scenario edits.',
    tags: {'scenario-runner', 'performance', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'scenario_runner_accessibility_localization',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_scenario_runners_test.dart',
    plainName:
        'accessibility localization runner proves release UI language gates',
    reason:
        'Run only the accessibility/localization scenario runner after gate edits.',
    tags: {'scenario-runner', 'accessibility', 'localization', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'scenario_runner_cost_quota',
    scope: MaintainiacSurgicalTestScope.singleBehavior,
    file: 'test/maintainiac_qa_scenario_runners_test.dart',
    plainName: 'cost quota runner proves cloud usage stays budgeted and opt-in',
    reason: 'Run only the cost/quota scenario runner after cloud policy edits.',
    tags: {'scenario-runner', 'cost-quota', 'security', 'release-gate'},
  ),
  MaintainiacSurgicalTestSelector(
    id: 'main_backbone_parser_visibility',
    scope: MaintainiacSurgicalTestScope.releaseGate,
    file: 'test/maintainiac_qa_backbone_test.dart',
    plainName: 'main Maintainiac QA backbone covers whole app modules',
    reason:
        'Run only the main backbone visibility check when shared QA wiring changes.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'release-gate'},
  ),
]);
