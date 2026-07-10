import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('performance budget registry labels harness performance budgets', () {
    const registry = maintainiacPerformanceBudgetRegistry;

    expect(registry.validate(), isEmpty);
    expect(registry.toJson()['budgetCount'], greaterThanOrEqualTo(6));
    expect(
      registry.budgetsFor('qa_backbone'),
      hasLength(greaterThanOrEqualTo(2)),
    );
    expect(
      registry.budgets
          .where(
            (budget) => budget.measurementCommand.startsWith('flutter test '),
          )
          .every(
            (budget) => budget.measurementCommand.contains(' --plain-name '),
          ),
      isTrue,
    );
    expect(
      registry.toJson().toString(),
      contains('surgical_rerun_router_budget'),
    );
    expect(
      registry.toJson().toString(),
      contains('parser_generated_fixture_run'),
    );
  });

  test('performance budget registry rejects missing or broad budgets', () {
    const registry = MaintainiacPerformanceBudgetRegistry([
      MaintainiacPerformanceBudget(
        id: 'bad',
        kind: MaintainiacPerformanceBudgetKind.coldStart,
        module: '',
        maxDurationMs: 0,
        maxMemoryMb: 0,
        measurementCommand: 'echo bad',
        failureAction: '',
      ),
    ]);

    final failures = registry.validate().join('\n');

    expect(failures, contains('bad missing module'));
    expect(failures, contains('bad needs positive duration budget'));
    expect(failures, contains('bad needs positive memory budget'));
    expect(failures, contains('bad needs focused measurement command'));
    expect(failures, contains('bad missing failure action'));
    expect(
      failures,
      contains('performance budget registry missing kind indexing'),
    );
  });

  test('performance budget registry rejects broad Flutter measurements', () {
    const registry = MaintainiacPerformanceBudgetRegistry([
      MaintainiacPerformanceBudget(
        id: 'broad',
        kind: MaintainiacPerformanceBudgetKind.coldStart,
        module: 'qa_backbone',
        maxDurationMs: 1000,
        maxMemoryMb: 128,
        measurementCommand:
            'flutter test test/maintainiac_qa_backbone_test.dart',
        failureAction: 'Use a named test instead of a broad file run.',
      ),
    ]);

    final failures = registry.validate().join('\n');

    expect(failures, contains('broad needs individual plain-name measurement'));
  });

  test('performance budget registry commands target real files', () {
    const registry = maintainiacPerformanceBudgetRegistry;
    final missingTargets = <String>[];

    for (final budget in registry.budgets) {
      final target = _measurementTarget(budget.measurementCommand);
      if (target == null || !File(target).existsSync()) {
        missingTargets.add('${budget.id}:${budget.measurementCommand}');
      }
    }

    expect(
      missingTargets,
      isEmpty,
      reason: 'Performance budgets must remain tied to runnable files.',
    );
  });
}

String? _measurementTarget(String command) {
  final parts = command.split(RegExp(r'\s+'));
  if (parts.length >= 3 && parts[0] == 'flutter' && parts[1] == 'test') {
    return parts[2];
  }
  if (parts.length >= 3 && parts[0] == 'dart' && parts[1] == 'run') {
    return parts[2];
  }
  return null;
}
