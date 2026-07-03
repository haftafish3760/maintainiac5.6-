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
      file: 'test/maintainiac_parser_consumer_gate_test.dart',
      plainNames: {
        'parser consumer gate validates inventory and expense consumers together',
        'parser consumer gate rejects unsafe or narrow consumers',
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
