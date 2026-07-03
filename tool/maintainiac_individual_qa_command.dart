import 'dart:convert';
import 'dart:io';

import '../test/support/qa_harness/qa_harness.dart';

const _usage =
    'dart run tool/maintainiac_individual_qa_command.dart '
    '[--id selector_id | --tag tag | --module module | --risk riskFamily | --changed path] '
    '[--json]';

void main(List<String> args) {
  final result = resolveMaintainiacIndividualQaCommand(args);
  if (result.stderr.isNotEmpty) stderr.writeln(result.stderr);
  if (result.stdout.isNotEmpty) stdout.writeln(result.stdout);
  if (result.exitCode != 0) exitCode = result.exitCode;
}

MaintainiacIndividualQaCommandResult resolveMaintainiacIndividualQaCommand(
  List<String> args,
) {
  if (args.contains('--help') || args.contains('-h')) {
    return const MaintainiacIndividualQaCommandResult(
      exitCode: 0,
      stdout: _usage,
    );
  }

  final manifest = maintainiacIndividualTestManifest;
  const registry = maintainiacSurgicalTestSelectorRegistry;
  final failures = [...registry.validate(), ...manifest.validate()];
  if (failures.isNotEmpty) {
    return MaintainiacIndividualQaCommandResult(
      exitCode: 65,
      stderr: 'Individual QA command registry invalid: ${failures.join('; ')}',
    );
  }

  final id = _value(args, 'id');
  final tag = _value(args, 'tag');
  final module = _value(args, 'module');
  final risk = _value(args, 'risk');
  final changedPaths = _values(args, 'changed');
  final asJson = args.contains('--json');
  final selected = _selectEntries(
    manifest: manifest,
    registry: registry,
    id: id,
    tag: tag,
    module: module,
    risk: risk,
    changedPaths: changedPaths,
  );
  if (selected.isEmpty) {
    return MaintainiacIndividualQaCommandResult(
      exitCode: 66,
      stderr: 'No individual QA command matched. $_usage',
    );
  }
  if (asJson) {
    return MaintainiacIndividualQaCommandResult(
      exitCode: 0,
      stdout: const JsonEncoder.withIndent('  ').convert({
        'commandCount': selected.length,
        'commands': [for (final entry in selected) entry.toJson()],
      }),
    );
  }
  return MaintainiacIndividualQaCommandResult(
    exitCode: 0,
    stdout: selected.map((entry) => entry.command).join('\n'),
  );
}

class MaintainiacIndividualQaCommandResult {
  const MaintainiacIndividualQaCommandResult({
    required this.exitCode,
    this.stdout = '',
    this.stderr = '',
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

List<MaintainiacIndividualTestEntry> _selectEntries({
  required MaintainiacIndividualTestManifest manifest,
  required MaintainiacSurgicalTestSelectorRegistry registry,
  required String id,
  required String tag,
  required String module,
  required String risk,
  required List<String> changedPaths,
}) {
  if (id.isNotEmpty) {
    try {
      return [manifest.entryForId(id)];
    } on ArgumentError {
      return const [];
    }
  }
  if (changedPaths.isNotEmpty) {
    final ids = maintainiacSurgicalRerunRouter.selectorIdsForChangedPaths(
      changedPaths,
    );
    return [
      for (final entry in manifest.entries)
        if (ids.contains(entry.id)) entry,
    ];
  }
  if (module.isNotEmpty) {
    return [
      for (final entry in manifest.entries)
        if (entry.module == module) entry,
    ];
  }
  if (risk.isNotEmpty) {
    return [
      for (final entry in manifest.entries)
        if (entry.riskFamily == risk) entry,
    ];
  }
  if (tag.isNotEmpty) {
    final ids = {
      for (final selector in registry.selectors)
        if (selector.tags.contains(tag)) selector.id,
    };
    return [
      for (final entry in manifest.entries)
        if (ids.contains(entry.id)) entry,
    ];
  }
  return manifest.entries;
}

String _value(List<String> args, String key) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return '';
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
