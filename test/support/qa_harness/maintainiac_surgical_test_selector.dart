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
    id: 'main_backbone_parser_visibility',
    scope: MaintainiacSurgicalTestScope.releaseGate,
    file: 'test/maintainiac_qa_backbone_test.dart',
    plainName: 'main Maintainiac QA backbone covers whole app modules',
    reason:
        'Run only the main backbone visibility check when shared QA wiring changes.',
    tags: {'inventory', 'expenses', 'parser-consumer', 'release-gate'},
  ),
]);
