import 'maintainiac_surgical_test_selector.dart';

class MaintainiacSurgicalCoverageExpectation {
  const MaintainiacSurgicalCoverageExpectation({
    required this.file,
    required this.plainNames,
  });

  final String file;
  final Set<String> plainNames;

  List<String> validate(MaintainiacSurgicalTestSelectorRegistry registry) {
    final failures = <String>[];
    if (!file.startsWith('test/') || !file.endsWith('.dart')) {
      failures.add('coverage expectation must target a Dart test file: $file');
    }
    if (plainNames.isEmpty) {
      failures.add('$file missing expected test names');
    }
    final selectorsForFile = {
      for (final selector in registry.selectors)
        if (selector.file == file) selector.plainName,
    };
    for (final plainName in plainNames) {
      if (!selectorsForFile.contains(plainName)) {
        failures.add('$file missing surgical selector for "$plainName"');
      }
      final matches = [
        for (final selector in registry.selectors)
          if (selector.file == file && selector.plainName == plainName)
            selector,
      ];
      if (matches.length > 1) {
        failures.add('$file has duplicate surgical selectors for "$plainName"');
      }
      if (matches.length == 1 &&
          !matches.single.command.contains('--plain-name "$plainName"')) {
        failures.add('$file selector command is not exact for "$plainName"');
      }
    }
    return failures;
  }
}

class MaintainiacSurgicalSelectorCoverage {
  const MaintainiacSurgicalSelectorCoverage({
    required this.registry,
    required this.expectations,
  });

  final MaintainiacSurgicalTestSelectorRegistry registry;
  final List<MaintainiacSurgicalCoverageExpectation> expectations;

  List<String> validate() {
    final failures = <String>[];
    final files = <String>{};
    for (final expectation in expectations) {
      if (!files.add(expectation.file)) {
        failures.add('duplicate surgical coverage file ${expectation.file}');
      }
      failures.addAll(expectation.validate(registry));
    }
    for (final selector in registry.selectors) {
      if (!files.contains(selector.file)) {
        failures.add('selector ${selector.id} is not covered by expectations');
      }
    }
    final expectedPairs = {
      for (final expectation in expectations)
        for (final plainName in expectation.plainNames)
          '${expectation.file}::$plainName',
    };
    final selectorPairs = {
      for (final selector in registry.selectors)
        '${selector.file}::${selector.plainName}',
    };
    for (final pair in selectorPairs) {
      if (!expectedPairs.contains(pair)) {
        failures.add('selector target is not expected: $pair');
      }
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'fileCount': expectations.length,
      'expectedBehaviorCount': expectations.fold<int>(
        0,
        (sum, expectation) => sum + expectation.plainNames.length,
      ),
      'selectorCount': registry.selectors.length,
      'individualCommandCount': registry.selectors
          .where((selector) => selector.command.contains(' --plain-name '))
          .length,
      'expectations': [
        for (final expectation in expectations)
          {
            'file': expectation.file,
            'plainNames': expectation.plainNames.toList()..sort(),
          },
      ],
    };
  }
}

const maintainiacSurgicalSelectorCoverage = MaintainiacSurgicalSelectorCoverage(
  registry: maintainiacSurgicalTestSelectorRegistry,
  expectations: [
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_inventory_parser_consumer_test.dart',
      plainNames: {
        'inventory parser consumer labels broad release-one QA families',
        'inventory parser consumer references existing QA support files',
        'inventory parser consumer keeps commands focused and offline',
        'inventory parser consumer rejects fake narrow coverage',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_expense_parser_consumer_test.dart',
      plainNames: {
        'expense parser consumer labels broad release-one QA families',
        'expense parser consumer references existing QA files',
        'expense parser consumer keeps commands focused and provider-free',
        'expense parser consumer rejects unsafe fake readiness',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_auth_policy_test.dart',
      plainNames: {
        'hosted account login allows only Google and Apple providers',
        'allowed provider set remains intentionally small',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_export_privacy_test.dart',
      plainNames: {
        'export privacy probe accepts owned non-private records',
        'export privacy probe catches cross-account and private fields',
        'export privacy probe sanitizes private fields before writing',
        'export privacy matrix blocks cross-account and identity leaks',
        'export privacy matrix rejects incomplete case coverage',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_scope_policy_test.dart',
      plainNames: {
        'scope policy allows account owner with assigned vehicle permission',
        'scope policy denies cross-account and unassigned vehicle access',
        'scope policy requires company employee and permission match',
        'scope policy matrix covers fleet company employee and vehicle denials',
        'scope policy matrix rejects missing denial explanations',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_sensitive_field_registry_test.dart',
      plainNames: {
        'sensitive field registry covers privacy forbidden data classes',
        'sensitive field registry rejects duplicates and missing classes',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_source_boundary_test.dart',
      plainNames: {
        'source boundary scanner catches forbidden live-service code',
        'source boundary scanner honors allowed emulator paths',
        'source boundary scanner skips generated build folders',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_parser_consumer_gate_test.dart',
      plainNames: {
        'parser consumer gate validates inventory and expense consumers together',
        'parser consumer gate rejects unsafe or narrow consumers',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_parser_candidate_contract_test.dart',
      plainNames: {
        'parser candidate contract preserves review-only inventory evidence',
        'parser candidate contract allows confirmed only after user action',
        'parser candidate contract rejects autosave and false confirmation',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_correction_learning_contract_test.dart',
      plainNames: {
        'correction learning contract creates reviewable parser proposals',
        'correction learning contract requires regression metadata',
        'correction learning contract blocks silent pack mutation',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_derived_output_contract_test.dart',
      plainNames: {
        'derived output contract keeps reports and invoices read-only',
        'derived output contract rejects source mutation ambiguity',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_device_capability_test.dart',
      plainNames: {
        'device capability probe allows full local packs on high-end devices',
        'device capability probe falls back for low-storage older phones',
        'device capability probe blocks unsafe or offline cloud-only cases',
        'device delivery matrix covers local compact cloud and blocked modes',
        'device delivery matrix rejects unsafe cloud and App Check cases',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_job_contract_test.dart',
      plainNames: {
        'job contract accepts confirmed estimate and inventory material lines',
        'job contract accepts receipt-backed time and material job',
        'job contract rejects unsafe material and summary behavior',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_pricing_contract_test.dart',
      plainNames: {
        'pricing contract balances estimate and invoice line totals in cents',
        'pricing contract allocates tax remainders deterministically per unit',
        'pricing contract rejects unsafe money and source mutation',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_fixture_governance_gate_test.dart',
      plainNames: {
        'fixture governance gate covers release fixture families',
        'fixture governance gate rejects private or weak fixture rules',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_parser_fixture_manifest_test.dart',
      plainNames: {
        'parser fixture manifest separates golden holdout regression and malformed roles',
        'parser fixture manifest rejects unsafe fixture governance gaps',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_regression_registry_test.dart',
      plainNames: {
        'regression registry records permanent bug fixtures by area',
        'regression registry rejects non-permanent or incomplete bug records',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_failure_taxonomy_test.dart',
      plainNames: {
        'failure taxonomy classifies common QA failure families',
        'failure taxonomy summarizes failure buckets',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_performance_budget_registry_test.dart',
      plainNames: {
        'performance budget registry labels harness performance budgets',
        'performance budget registry rejects missing or broad budgets',
        'performance budget registry rejects broad Flutter measurements',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_release_gate_plan_test.dart',
      plainNames: {
        'release gate plan exposes release blocker and core command plan',
        'release gate plan rejects missing name or priorities',
        'release gate plan requires commands for release blockers',
        'release gate plan requires surgical commands for core checks',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_module_boundary_gate_test.dart',
      plainNames: {
        'module boundary gate labels safe QA lanes',
        'module boundary gate rejects weak or missing lanes',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_module_suite_contract_test.dart',
      plainNames: {
        'module suite matrix labels release-one module QA coverage',
        'module suite matrix now makes release-one module suites executable',
        'module suite matrix rejects unsafe or unlabeled suites',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_schedule_contract_test.dart',
      plainNames: {
        'schedule contract accepts audited jobs and maintenance reminders',
        'schedule contract respects denied notification permission',
        'schedule contract rejects unsafe calendar and reminder records',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_restart_lifecycle_gate_test.dart',
      plainNames: {
        'restart lifecycle gate covers offline and partial-sync recovery',
        'restart lifecycle gate rejects unsafe recovery scenarios',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_qa_case_registry_test.dart',
      plainNames: {
        'QA case registry labels behavior evidence and priority',
        'QA case registry rejects duplicate and unlabeled cases',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_qa_telemetry_privacy_gate_test.dart',
      plainNames: {
        'QA telemetry privacy gate covers report and admin surfaces',
        'QA telemetry privacy gate rejects missing redaction and overlap',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_parser_release_command_plan_test.dart',
      plainNames: {
        'parser release command plan covers every parser consumer family',
        'parser release command plan rejects unsafe commands and missing tiers',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_parser_regression_binding_test.dart',
      plainNames: {
        'parser regression bindings cover required consumer risk families',
        'parser regression bindings reject duplicate or unowned regressions',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_surgical_test_selector_test.dart',
      plainNames: {
        'surgical selector registry exposes individual plain-name commands',
        'surgical selector registry rejects broad or unsafe selectors',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_surgical_selector_coverage_test.dart',
      plainNames: {
        'surgical selector coverage requires selectors for every focused behavior',
        'surgical selector coverage rejects missing behavior selectors',
        'surgical selector coverage rejects unlisted selector targets',
        'surgical selector coverage lists every test in registered files',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_individual_test_manifest_test.dart',
      plainNames: {
        'individual test manifest exposes surgical command metadata',
        'individual test manifest mirrors surgical selector commands exactly',
        'individual test manifest rejects unsafe or non-surgical commands',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_surgical_rerun_router_test.dart',
      plainNames: {
        'surgical rerun router maps changed files to individual commands',
        'surgical rerun router rejects unknown selector references',
        'surgical rerun router maps payment and granularity changes',
        'surgical rerun router maps changed test files to their selectors',
        'surgical rerun router dedupes overlapping changed paths',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_surgical_granularity_contract_test.dart',
      plainNames: {
        'surgical granularity contract keeps tests individually runnable',
        'surgical granularity contract rejects broad batch selectors',
        'surgical selectors point at real individual test declarations',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_payment_contract_test.dart',
      plainNames: {
        'payment ledger policy proves invoice balance without source mutation',
        'payment ledger policy rejects cross-account and overpay risks',
        'payment contract balances payments refunds and adjustments',
        'payment contract allows audited positive payment and refund ledger math',
        'payment contract rejects sensitive or source-mutating records',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_financial_ledger_test.dart',
      plainNames: {
        'financial ledger probe totals expenses deterministically',
        'financial ledger probe models inventory consumption cost',
        'financial ledger probe rejects unsafe money lines',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_financial_formula_registry_test.dart',
      plainNames: {
        'financial formula registry labels deterministic money formulas',
        'financial formula registry rejects mutable or broad formulas',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_operating_directive_contract_test.dart',
      plainNames: {
        'operating directive contract matches production docs',
        'operating directive contract rejects missing production rules',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_qa_quality_gates_test.dart',
      plainNames: {
        'quality gate matrix covers release required QA dimensions',
        'quality gate matrix rejects partial release dimensions',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_release_gate_tool_test.dart',
      plainNames: {
        'release gate tool emits surgical command plan',
        'release gate tool emits JSON evidence',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_individual_qa_command_tool_test.dart',
      plainNames: {
        'individual QA command tool returns one exact command by id',
        'individual QA command tool lists focused commands by risk',
        'individual QA command tool resolves changed files to focused commands',
        'individual QA command tool resolves every selector test file',
        'individual QA command tool rejects unknown selectors',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_release_evidence_bundle_test.dart',
      plainNames: {
        'release evidence bundle records required milestone proof',
        'release evidence bundle rejects broad or missing proof',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_source_audit_policy_test.dart',
      plainNames: {
        'source audit policy separates production and QA line caps',
        'source audit debt ledger tracks current oversized production files',
        'source audit policy rejects unsafe or incomplete limits',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_audit_trail_test.dart',
      plainNames: {
        'audit trail probe validates ordered complete audit events',
        'audit trail probe proves user confirmation outranks suggestions',
        'audit trail probe rejects duplicate incomplete or unordered events',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_qa_assertions_test.dart',
      plainNames: {
        'shared QA assertions accept safe source truth behavior',
        'shared QA assertions reject source truth and privacy failures',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_qa_artifact_policy_test.dart',
      plainNames: {
        'QA artifact policy accepts redacted reports fixtures and regressions',
        'QA artifact policy rejects private receipt and unredacted evidence',
        'QA artifact policy rejects Google Drive OneDrive and F drive paths',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_mutation_guard_test.dart',
      plainNames: {
        'mutation guard allows derived output collections only',
        'mutation guard blocks recaps exports and notifications mutating sources',
        'mutation guard allows only explicitly scoped source operations',
        'mutation guard matrix captures clean and failing side effects',
        'mutation guard matrix rejects mismatched expectations',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_local_first_contract_test.dart',
      plainNames: {
        'local-first contract accepts Hive before Firestore mirror',
        'local-first contract rejects mirror writes before local truth',
        'local-first contract rejects unsafe derived and mirror writes',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_source_truth_gate_test.dart',
      plainNames: {
        'source truth gate protects local truth and derived outputs',
        'source truth gate rejects mirror suggestion and derived mutations',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_sync_lifecycle_test.dart',
      plainNames: {
        'sync lifecycle writes local dirty record before mirror success',
        'sync lifecycle keeps failed records queued for retry',
        'sync lifecycle rejects unknown record transitions',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_sync_transport_policy_test.dart',
      plainNames: {
        'sync transport policy covers manual scheduled and automatic paths',
        'sync transport policy rejects unsafe network expectations',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_sync_conflict_contract_test.dart',
      plainNames: {
        'sync conflict contract allows different-field safe merge',
        'sync conflict contract protects confirmed financial local data',
        'sync conflict contract requires review audit for ambiguous conflicts',
        'sync conflict contract rejects unsafe remote wins and source mutation',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_qa_environment_test.dart',
      plainNames: {
        'QA environment fakes preserve local truth and mirror copies',
        'QA environment exposes permissions device and side-effect fakes',
        'QA builders create every shared record family',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_qa_fixtures_test.dart',
      plainNames: {
        'fixture catalog accepts reviewed behavior fixtures',
        'fixture catalog rejects duplicate or unreviewed weak evidence',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_qa_scenario_runners_test.dart',
      plainNames: {
        'sync scenario runner proves local-first mirror behavior',
        'security scenario runner proves privacy and scope behavior',
        'financial scenario runner proves deterministic money behavior',
        'performance scenario runner proves large-data budgets',
        'accessibility localization runner proves release UI language gates',
        'cost quota runner proves cloud usage stays budgeted and opt-in',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_qa_backbone_test.dart',
      plainNames: {
        'main Maintainiac QA backbone covers whole app modules',
        'shared builders cover app records without module-specific fakes',
        'shared assertions enforce source-of-truth and privacy rules',
        'fixture catalog and regression registry reject weak QA evidence',
        'quality gate matrix covers release-one sync security money and load',
        'scenario runners execute release-one QA behavior contracts',
      },
    ),
  ],
);
