import 'dart:convert';
import 'dart:io';

import '../test/support/qa_harness/qa_harness.dart';

const _usage =
    'dart run tool/maintainiac_qa_runner.dart '
    '[--group all|inventory|expenses|parser|security|sync|financial|release|performance] '
    '[--changed path/to/file.dart] [--json] [--list-groups] '
    '[--commands-only] [--include-metrics] [--strict]';

void main(List<String> args) {
  final result = runMaintainiacQaRunner(args);
  if (result.stderr.isNotEmpty) stderr.writeln(result.stderr);
  if (result.stdout.isNotEmpty) stdout.writeln(result.stdout);
  if (result.exitCode != 0) exitCode = result.exitCode;
}

MaintainiacQaRunnerResult runMaintainiacQaRunner(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    return const MaintainiacQaRunnerResult(exitCode: 0, stdout: _usage);
  }

  final group = _value(args, 'group', 'all');
  final changedPaths = _values(args, 'changed');
  final asJson = args.contains('--json');
  final listGroups = args.contains('--list-groups');
  final commandsOnly = args.contains('--commands-only');
  final includeMetrics = args.contains('--include-metrics');
  final strict = args.contains('--strict');
  final groups = _groups();

  if (listGroups) {
    final names = groups.map((group) => group.id).toList()..sort();
    return MaintainiacQaRunnerResult(exitCode: 0, stdout: names.join('\n'));
  }

  final selectedGroups = group == 'all'
      ? groups
      : groups.where((entry) => entry.id == group).toList(growable: false);
  if (selectedGroups.isEmpty) {
    return MaintainiacQaRunnerResult(
      exitCode: 64,
      stderr: 'Unknown QA runner group "$group". Use --list-groups.',
    );
  }

  final checks = [
    for (final selectedGroup in selectedGroups) ...selectedGroup.checks,
  ];
  final results = [for (final check in checks) check.run()];
  final selectedCommands = _selectedCommands(
    changedPaths: changedPaths,
    groupIds: selectedGroups.map((group) => group.id).toSet(),
    includeGroupDefaults: commandsOnly,
  );
  final failureCount = results.fold<int>(
    0,
    (sum, result) => sum + result.failures.length,
  );
  final report = _RunnerReport(
    requestedGroup: group,
    strict: strict,
    changedPaths: changedPaths,
    results: results,
    selectedCommands: selectedCommands,
    includeMetrics: includeMetrics,
  );

  if (commandsOnly) {
    return MaintainiacQaRunnerResult(
      exitCode: strict && failureCount > 0 ? 1 : 0,
      stdout: selectedCommands.join('\n'),
    );
  }

  return MaintainiacQaRunnerResult(
    exitCode: strict && failureCount > 0 ? 1 : 0,
    stdout: asJson
        ? const JsonEncoder.withIndent('  ').convert(report.toJson())
        : report.toSummary(),
  );
}

class MaintainiacQaRunnerResult {
  const MaintainiacQaRunnerResult({
    required this.exitCode,
    this.stdout = '',
    this.stderr = '',
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

class _RunnerGroup {
  const _RunnerGroup({
    required this.id,
    required this.checks,
  });

  final String id;
  final List<_RunnerCheck> checks;
}

class _RunnerCheck {
  const _RunnerCheck({
    required this.id,
    required this.group,
    required this.description,
    required this.validate,
    this.metrics = const {},
  });

  final String id;
  final String group;
  final String description;
  final List<String> Function() validate;
  final Map<String, Object?> metrics;

  _RunnerCheckResult run() {
    final stopwatch = Stopwatch()..start();
    final failures = validate();
    stopwatch.stop();
    return _RunnerCheckResult(
      id: id,
      group: group,
      description: description,
      duration: stopwatch.elapsed,
      failures: failures,
      metrics: metrics,
    );
  }
}

class _RunnerCheckResult {
  const _RunnerCheckResult({
    required this.id,
    required this.group,
    required this.description,
    required this.duration,
    required this.failures,
    required this.metrics,
  });

  final String id;
  final String group;
  final String description;
  final Duration duration;
  final List<String> failures;
  final Map<String, Object?> metrics;

  Map<String, Object?> toJson({required bool includeMetrics}) {
    return {
      'id': id,
      'group': group,
      'description': description,
      'durationMs': duration.inMilliseconds,
      'status': failures.isEmpty ? 'pass' : 'fail',
      'failureCount': failures.length,
      if (includeMetrics && metrics.isNotEmpty) 'metrics': metrics,
      if (failures.isNotEmpty) 'failures': failures,
    };
  }
}

class _RunnerReport {
  const _RunnerReport({
    required this.requestedGroup,
    required this.strict,
    required this.changedPaths,
    required this.results,
    required this.selectedCommands,
    required this.includeMetrics,
  });

  final String requestedGroup;
  final bool strict;
  final List<String> changedPaths;
  final List<_RunnerCheckResult> results;
  final List<String> selectedCommands;
  final bool includeMetrics;

  int get failureCount {
    return results.fold(0, (sum, result) => sum + result.failures.length);
  }

  int get checked => results.length;

  Map<String, Object?> toJson() {
    return {
      'runner': 'maintainiac_qa_runner',
      'requestedGroup': requestedGroup,
      'strict': strict,
      'checked': checked,
      'failureCount': failureCount,
      'changedPaths': changedPaths,
      'selectedCommandCount': selectedCommands.length,
      'selectedCommandSample': selectedCommands.take(25).toList(),
      'results': [
        for (final result in results)
          result.toJson(includeMetrics: includeMetrics),
      ],
    };
  }

  String toSummary() {
    final buffer = StringBuffer()
      ..writeln(
        'MAINTAINIAC_QA_RUNNER group=$requestedGroup strict=$strict '
        'checked=$checked failures=$failureCount '
        'selectedCommands=${selectedCommands.length}',
      );
    for (final result in results) {
      buffer.writeln(
        'QA_RUNNER_CHECK id=${result.id} group=${result.group} '
        'status=${result.failures.isEmpty ? 'pass' : 'fail'} '
        'failures=${result.failures.length} '
        'durationMs=${result.duration.inMilliseconds}',
      );
      for (final failure in result.failures.take(20)) {
        buffer.writeln('QA_RUNNER_FAILURE id=${result.id} detail=$failure');
      }
    }
    for (final command in selectedCommands.take(25)) {
      buffer.writeln('QA_RUNNER_COMMAND $command');
    }
    if (selectedCommands.length > 25) {
      buffer.writeln(
        'QA_RUNNER_COMMANDS_TRUNCATED remaining=${selectedCommands.length - 25}',
      );
    }
    return buffer.toString();
  }
}

List<_RunnerGroup> _groups() {
  return [
    _RunnerGroup(
      id: 'parser',
      checks: [
        _check(
          id: 'parser_consumer_gate',
          group: 'parser',
          description: 'Inventory and expense parser consumers are safe.',
          validate: maintainiacParserConsumerGate.validate,
        ),
        _check(
          id: 'parser_release_command_plan',
          group: 'parser',
          description: 'Parser release commands are scoped and complete.',
          validate: maintainiacParserReleaseCommandPlan.validate,
        ),
        _check(
          id: 'parser_regression_bindings',
          group: 'parser',
          description: 'Parser regressions bind to permanent evidence.',
          validate: maintainiacParserRegressionBindingRegistry.validate,
        ),
      ],
    ),
    _RunnerGroup(
      id: 'inventory',
      checks: [
        _check(
          id: 'inventory_parser_consumer',
          group: 'inventory',
          description: 'Inventory parser consumer covers release-one risks.',
          validate: maintainiacInventoryParserConsumerContract.validate,
        ),
      ],
    ),
    _RunnerGroup(
      id: 'expenses',
      checks: [
        _check(
          id: 'expense_parser_consumer',
          group: 'expenses',
          description: 'Expense parser consumer stays review-only/offline.',
          validate: maintainiacExpenseParserConsumerContract.validate,
        ),
      ],
    ),
    _RunnerGroup(
      id: 'release',
      checks: [
        _check(
          id: 'qa_case_registry',
          group: 'release',
          description: 'QA cases have evidence and surgical commands.',
          validate: MaintainiacQaCaseRegistry.backboneSeed().validate,
        ),
        _check(
          id: 'release_gate_plan',
          group: 'release',
          description: 'Release-one blocker/core command plan is complete.',
          validate: MaintainiacReleaseGatePlan.releaseOne().validate,
        ),
        _check(
          id: 'execution_manifest',
          group: 'release',
          description: 'Execution manifest labels cadence and failure action.',
          validate: MaintainiacQaExecutionManifest.releaseOneCore().validate,
        ),
        _check(
          id: 'release_evidence_bundle',
          group: 'release',
          description: 'Milestone evidence bundle is scoped and redacted.',
          validate: maintainiacReleaseEvidenceBundle.validate,
        ),
      ],
    ),
    _RunnerGroup(
      id: 'security',
      checks: [
        _check(
          id: 'sensitive_field_registry',
          group: 'security',
          description: 'Forbidden private data classes are tracked.',
          validate: maintainiacSensitiveFieldRegistry.validate,
        ),
        _check(
          id: 'scope_policy_matrix',
          group: 'security',
          description: 'Account/company/employee/vehicle scope matrix exists.',
          validate: maintainiacScopePolicyMatrix.validate,
        ),
        _check(
          id: 'export_privacy_matrix',
          group: 'security',
          description: 'Exports reject cross-account and private leakage.',
          validate: maintainiacExportPrivacyMatrix.validate,
        ),
        _check(
          id: 'artifact_policy',
          group: 'security',
          description: 'QA artifacts stay redacted and out of wrong folders.',
          validate: () => const MaintainiacQaArtifactPolicy([
            MaintainiacQaArtifact(
              id: 'runner_contract_report',
              kind: MaintainiacQaArtifactKind.report,
              path: 'build/qa/maintainiac_qa_runner/latest.json',
              owner: 'maintainiac-qa',
              summary: 'Fast QA runner report with redacted metadata only.',
              tags: {'qa-runner', 'privacy', 'report'},
            ),
          ]).validate(),
        ),
      ],
    ),
    _RunnerGroup(
      id: 'sync',
      checks: [
        _check(
          id: 'source_truth_gate',
          group: 'sync',
          description: 'Hive/local truth, mirror, suggestion, and output rules.',
          validate: maintainiacSourceTruthGate.validate,
        ),
        _check(
          id: 'sync_transport_policy',
          group: 'sync',
          description: 'Manual/scheduled/automatic sync network rules exist.',
          validate: maintainiacSyncTransportPolicy.validate,
        ),
      ],
    ),
    _RunnerGroup(
      id: 'financial',
      checks: [
        _check(
          id: 'financial_formula_registry',
          group: 'financial',
          description: 'Money formulas are deterministic and source-safe.',
          validate: maintainiacFinancialFormulaRegistry.validate,
        ),
      ],
    ),
    _RunnerGroup(
      id: 'performance',
      checks: [
        _check(
          id: 'performance_budget_registry',
          group: 'performance',
          description: 'Named QA and parser performance budgets exist.',
          validate: maintainiacPerformanceBudgetRegistry.validate,
        ),
        _check(
          id: 'surgical_selector_registry',
          group: 'performance',
          description: 'Every selector is focused and individually runnable.',
          validate: maintainiacSurgicalTestSelectorRegistry.validate,
        ),
        _check(
          id: 'surgical_selector_coverage',
          group: 'performance',
          description: 'Registered tests have selector coverage.',
          validate: maintainiacSurgicalSelectorCoverage.validate,
        ),
        _check(
          id: 'surgical_rerun_router',
          group: 'performance',
          description: 'Changed files route to exact surgical commands.',
          validate: maintainiacSurgicalRerunRouter.validate,
        ),
        _check(
          id: 'individual_test_manifest',
          group: 'performance',
          description: 'Individual command manifest mirrors selectors.',
          validate: maintainiacIndividualTestManifest.validate,
        ),
      ],
    ),
  ];
}

_RunnerCheck _check({
  required String id,
  required String group,
  required String description,
  required List<String> Function() validate,
  Map<String, Object?> metrics = const {},
}) {
  return _RunnerCheck(
    id: id,
    group: group,
    description: description,
    validate: validate,
    metrics: metrics,
  );
}

List<String> _selectedCommands({
  required List<String> changedPaths,
  required Set<String> groupIds,
  required bool includeGroupDefaults,
}) {
  final commands = changedPaths.isEmpty
      ? const <String>[]
      : maintainiacSurgicalRerunRouter.commandsForChangedPaths(changedPaths);
  if (commands.isNotEmpty) return commands;
  if (!includeGroupDefaults) return const [];

  final manifest = maintainiacIndividualTestManifest;
  final selectorTags = groupIds.expand(_tagsForGroup).toSet();
  return [
    for (final entry in manifest.entries)
      if (selectorTags.contains(entry.module) ||
          selectorTags.contains(entry.riskFamily))
        entry.command,
  ];
}

Set<String> _tagsForGroup(String group) {
  return switch (group) {
    'inventory' => {'inventory', 'parser'},
    'expenses' => {'expenses', 'parser'},
    'parser' => {'parser', 'inventory', 'expenses'},
    'security' => {'security', 'privacy'},
    'sync' => {'sync', 'source-of-truth'},
    'financial' => {'financial'},
    'release' => {'release', 'regression'},
    'performance' => {'performance', 'qa-backbone'},
    _ => {'inventory', 'expenses', 'parser', 'security', 'sync', 'financial'},
  };
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}

List<String> _values(List<String> args, String key) {
  final values = <String>[];
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) {
      values.add(args[index + 1]);
    } else if (arg.startsWith('--$key=')) {
      values.add(arg.substring(key.length + 3));
    }
  }
  return values;
}
