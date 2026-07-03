enum MaintainiacPerformanceBudgetKind {
  coldStart,
  indexing,
  parserFixtureRun,
  reportWrite,
  rerunRouting,
  memory,
}

class MaintainiacPerformanceBudget {
  const MaintainiacPerformanceBudget({
    required this.id,
    required this.kind,
    required this.module,
    required this.maxDurationMs,
    required this.maxMemoryMb,
    required this.measurementCommand,
    required this.failureAction,
  });

  final String id;
  final MaintainiacPerformanceBudgetKind kind;
  final String module;
  final int maxDurationMs;
  final int maxMemoryMb;
  final String measurementCommand;
  final String failureAction;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) {
      failures.add('performance budget missing id');
    }
    if (module.trim().isEmpty) {
      failures.add('$id missing module');
    }
    if (maxDurationMs <= 0) {
      failures.add('$id needs positive duration budget');
    }
    if (maxMemoryMb <= 0) {
      failures.add('$id needs positive memory budget');
    }
    final isFlutterTest = measurementCommand.startsWith('flutter test ');
    if (!isFlutterTest && !measurementCommand.startsWith('dart run ')) {
      failures.add('$id needs focused measurement command');
    }
    if (isFlutterTest && !measurementCommand.contains(' --plain-name ')) {
      failures.add('$id needs individual plain-name measurement');
    }
    if (failureAction.trim().isEmpty) {
      failures.add('$id missing failure action');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'module': module,
      'maxDurationMs': maxDurationMs,
      'maxMemoryMb': maxMemoryMb,
      'measurementCommand': measurementCommand,
      'failureAction': failureAction,
    };
  }
}

class MaintainiacPerformanceBudgetRegistry {
  const MaintainiacPerformanceBudgetRegistry(this.budgets);

  final List<MaintainiacPerformanceBudget> budgets;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final kinds = <MaintainiacPerformanceBudgetKind>{};
    for (final budget in budgets) {
      if (!ids.add(budget.id)) {
        failures.add('duplicate performance budget ${budget.id}');
      }
      kinds.add(budget.kind);
      failures.addAll(budget.validate());
    }
    for (final required in MaintainiacPerformanceBudgetKind.values) {
      if (!kinds.contains(required)) {
        failures.add(
          'performance budget registry missing kind ${required.name}',
        );
      }
    }
    return failures;
  }

  List<MaintainiacPerformanceBudget> budgetsFor(String module) {
    return [
      for (final budget in budgets)
        if (budget.module == module) budget,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'budgetCount': budgets.length,
      'budgets': [for (final budget in budgets) budget.toJson()],
    };
  }
}

const maintainiacPerformanceBudgetRegistry = MaintainiacPerformanceBudgetRegistry([
  MaintainiacPerformanceBudget(
    id: 'qa_backbone_cold_start',
    kind: MaintainiacPerformanceBudgetKind.coldStart,
    module: 'qa_backbone',
    maxDurationMs: 120000,
    maxMemoryMb: 768,
    measurementCommand:
        'flutter test test/maintainiac_qa_backbone_test.dart --plain-name "main Maintainiac QA backbone covers whole app modules"',
    failureAction:
        'Profile backbone imports and split slow gates behind focused commands.',
  ),
  MaintainiacPerformanceBudget(
    id: 'inventory_catalog_indexing',
    kind: MaintainiacPerformanceBudgetKind.indexing,
    module: 'inventory',
    maxDurationMs: 180000,
    maxMemoryMb: 1536,
    measurementCommand:
        'flutter test test/work_supply_catalog_scale_test.dart --plain-name "materials catalog exposes measurable trade scale"',
    failureAction:
        'Profile catalog search/index setup and cache expensive tokenization.',
  ),
  MaintainiacPerformanceBudget(
    id: 'parser_generated_fixture_run',
    kind: MaintainiacPerformanceBudgetKind.parserFixtureRun,
    module: 'parser_qa',
    maxDurationMs: 300000,
    maxMemoryMb: 1536,
    measurementCommand:
        'flutter test test/work_supply_parser_generated_fixture_runner_test.dart --plain-name "generated parser fixture batch matches expected safety contracts"',
    failureAction:
        'Shard generated fixtures and inspect slowest case report before adding more catalog rows.',
  ),
  MaintainiacPerformanceBudget(
    id: 'qa_report_write_budget',
    kind: MaintainiacPerformanceBudgetKind.reportWrite,
    module: 'qa_reports',
    maxDurationMs: 30000,
    maxMemoryMb: 256,
    measurementCommand: 'dart run tool/parser_qa_runner.dart --help',
    failureAction:
        'Keep report writing append-only, redacted, and outside live services.',
  ),
  MaintainiacPerformanceBudget(
    id: 'surgical_rerun_router_budget',
    kind: MaintainiacPerformanceBudgetKind.rerunRouting,
    module: 'qa_rerun',
    maxDurationMs: 5000,
    maxMemoryMb: 128,
    measurementCommand:
        'flutter test test/maintainiac_surgical_rerun_router_test.dart --plain-name "surgical rerun router maps changed files to individual commands"',
    failureAction:
        'Keep rerun routing in deterministic maps instead of scanning full repo state.',
  ),
  MaintainiacPerformanceBudget(
    id: 'qa_memory_budget',
    kind: MaintainiacPerformanceBudgetKind.memory,
    module: 'qa_backbone',
    maxDurationMs: 120000,
    maxMemoryMb: 1024,
    measurementCommand:
        'flutter test test/maintainiac_qa_backbone_test.dart --plain-name "main Maintainiac QA backbone covers whole app modules"',
    failureAction:
        'Split heavy fixture catalogs from smoke backbone and load only focused suites.',
  ),
]);
