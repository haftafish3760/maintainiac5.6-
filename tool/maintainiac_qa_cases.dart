import 'dart:convert';
import 'dart:io';

import '../test/support/qa_harness/qa_harness.dart';

const _usage =
    'dart run tool/maintainiac_qa_cases.dart '
    '[--priority releaseBlocker|core|standard|hardening] [--json]';

void main(List<String> args) {
  final exit = runMaintainiacQaCases(args, stdout: stdout, stderr: stderr);
  if (exit != 0) exitCode = exit;
}

int runMaintainiacQaCases(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final priority = _value(args, 'priority', '');
  final asJson = args.contains('--json');
  final registry = MaintainiacQaCaseRegistry.backboneSeed();
  final failures = registry.validate();
  if (failures.isNotEmpty) {
    stderr.writeln('QA case registry invalid: ${failures.join('; ')}');
    return 65;
  }
  final cases = priority.isEmpty
      ? registry.cases
      : registry.cases
            .where((qaCase) => qaCase.priority.name == priority)
            .toList(growable: false);
  if (priority.isNotEmpty && cases.isEmpty) {
    stderr.writeln('No QA cases found for priority $priority.');
    return 66;
  }
  if (asJson) {
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert({
        'caseCount': cases.length,
        'cases': [for (final qaCase in cases) qaCase.toJson()],
      }),
    );
    return 0;
  }
  for (final qaCase in cases) {
    stdout.writeln(
      '${qaCase.id} [${qaCase.priority.name}] ${qaCase.title} '
      '=> ${qaCase.evidenceTarget}',
    );
    if (qaCase.testCommand.isNotEmpty) {
      stdout.writeln('  command: ${qaCase.testCommand}');
    }
  }
  return 0;
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
