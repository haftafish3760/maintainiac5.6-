class MaintainiacRegressionCase {
  const MaintainiacRegressionCase({
    required this.bugId,
    required this.description,
    required this.rootCause,
    required this.inputFixture,
    required this.expectedBehavior,
    required this.fixedVersion,
    required this.area,
    required this.moduleTags,
    required this.permanentTest,
  });

  final String bugId;
  final String description;
  final String rootCause;
  final String inputFixture;
  final String expectedBehavior;
  final String fixedVersion;
  final String area;
  final Set<String> moduleTags;
  final String permanentTest;

  List<String> validate() {
    final failures = <String>[];
    if (!RegExp(r'^[A-Z]+-\d{4,}$').hasMatch(bugId)) {
      failures.add('bug id must look like AREA-0001');
    }
    if (description.trim().isEmpty) {
      failures.add('missing description');
    }
    if (rootCause.trim().isEmpty) {
      failures.add('missing root cause');
    }
    if (inputFixture.trim().isEmpty) {
      failures.add('missing input fixture');
    }
    if (expectedBehavior.trim().isEmpty) {
      failures.add('missing expected behavior');
    }
    if (fixedVersion.trim().isEmpty) {
      failures.add('missing fixed version');
    }
    if (area.trim().isEmpty) {
      failures.add('missing area');
    }
    if (moduleTags.isEmpty) {
      failures.add('missing module tags');
    }
    if (permanentTest.trim().isEmpty) {
      failures.add('missing permanent test');
    }
    if (permanentTest.trim().isNotEmpty && !permanentTest.startsWith('test/')) {
      failures.add('permanent test must be a test/ path');
    }
    if (!moduleTags.contains('regression')) {
      failures.add('module tags must include regression');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'bugId': bugId,
      'description': description,
      'rootCause': rootCause,
      'inputFixture': inputFixture,
      'expectedBehavior': expectedBehavior,
      'fixedVersion': fixedVersion,
      'area': area,
      'moduleTags': moduleTags.toList()..sort(),
      'permanentTest': permanentTest,
    };
  }
}

class MaintainiacRegressionRegistry {
  const MaintainiacRegressionRegistry(this.cases);

  final List<MaintainiacRegressionCase> cases;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final areas = <String>{};
    for (final entry in cases) {
      if (!ids.add(entry.bugId)) {
        failures.add('duplicate bug id ${entry.bugId}');
      }
      areas.add(entry.area);
      for (final issue in entry.validate()) {
        failures.add('${entry.bugId}: $issue');
      }
    }
    for (final required in {'inventory_parser', 'expense_parser', 'sync'}) {
      if (!areas.contains(required)) {
        failures.add('regression registry missing area $required');
      }
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'caseCount': cases.length,
      'areas': ({for (final entry in cases) entry.area}.toList()..sort()),
      'cases': [for (final entry in cases) entry.toJson()],
    };
  }
}

const maintainiacRegressionRegistry = MaintainiacRegressionRegistry([
  MaintainiacRegressionCase(
    bugId: 'INV-0001',
    description: 'Generic PVC elbow line was accepted too confidently.',
    rootCause: 'Dangerous generic material and shape terms lacked review lock.',
    inputFixture: 'fixtures/inventory/pvc_el_ambiguous.json',
    expectedBehavior: 'Return ranked candidates and require review.',
    fixedVersion: '2026.07.03',
    area: 'inventory_parser',
    moduleTags: {'inventory', 'parser', 'regression'},
    permanentTest: 'test/work_supply_parser_generated_fixture_runner_test.dart',
  ),
  MaintainiacRegressionCase(
    bugId: 'EXP-0001',
    description: 'Expense parser suggestion overwrote confirmed total.',
    rootCause:
        'Suggestion output was not separated from confirmed source data.',
    inputFixture: 'fixtures/expenses/confirmed_total_protection.json',
    expectedBehavior: 'Confirmed financial fields remain unchanged.',
    fixedVersion: '2026.07.03',
    area: 'expense_parser',
    moduleTags: {'expenses', 'parser', 'regression'},
    permanentTest: 'test/maintainiac_expense_parser_consumer_test.dart',
  ),
  MaintainiacRegressionCase(
    bugId: 'SYN-0001',
    description: 'Remote mirror attempted to win over local financial source.',
    rootCause: 'Sync conflict handling did not force local-wins/review.',
    inputFixture: 'fixtures/sync/local_financial_conflict.json',
    expectedBehavior: 'User-confirmed local financial values win or review.',
    fixedVersion: '2026.07.03',
    area: 'sync',
    moduleTags: {'sync', 'financial', 'regression'},
    permanentTest: 'test/maintainiac_sync_conflict_contract_test.dart',
  ),
]);
