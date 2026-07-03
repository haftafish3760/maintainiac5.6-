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
      },
    ),
    MaintainiacSurgicalCoverageExpectation(
      file: 'test/maintainiac_qa_backbone_test.dart',
      plainNames: {'main Maintainiac QA backbone covers whole app modules'},
    ),
  ],
);
