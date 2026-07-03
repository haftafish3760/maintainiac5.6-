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
      file: 'test/maintainiac_surgical_rerun_router_test.dart',
      plainNames: {
        'surgical rerun router maps changed files to individual commands',
        'surgical rerun router rejects unknown selector references',
        'surgical rerun router maps payment and granularity changes',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_surgical_granularity_contract_test.dart',
      plainNames: {
        'surgical granularity contract keeps tests individually runnable',
        'surgical granularity contract rejects broad batch selectors',
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_payment_contract_test.dart',
      plainNames: {
        'payment ledger policy proves invoice balance without source mutation',
        'payment ledger policy rejects cross-account and overpay risks',
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
      file: 'test/maintainiac_source_audit_policy_test.dart',
      plainNames: {
        'source audit policy separates production and QA line caps',
        'source audit debt ledger tracks current oversized production files',
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
      file: 'test/maintainiac_qa_backbone_test.dart',
      plainNames: {'main Maintainiac QA backbone covers whole app modules'},
    ),
  ],
);
