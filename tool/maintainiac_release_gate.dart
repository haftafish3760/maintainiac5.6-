import 'dart:convert';
import 'dart:io';

import '../test/support/qa_harness/qa_harness.dart';

const _usage =
    'dart run tool/maintainiac_release_gate.dart [--json] [--commands-only]';

void main(List<String> args) {
  final exit = runMaintainiacReleaseGate(args, stdout: stdout, stderr: stderr);
  if (exit != 0) exitCode = exit;
}

int runMaintainiacReleaseGate(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final plan = MaintainiacReleaseGatePlan.releaseOne();
  final failures = plan.validate();
  if (failures.isNotEmpty) {
    stderr.writeln('Maintainiac release gate invalid: ${failures.join('; ')}');
    return 65;
  }
  if (args.contains('--json')) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(plan.toJson()));
    return 0;
  }
  if (args.contains('--commands-only')) {
    for (final command in plan.commands) {
      stdout.writeln(command);
    }
    return 0;
  }
  stdout.writeln('MAINTAINIAC_RELEASE_GATE ${plan.name}');
  stdout.writeln('requiredCases=${plan.requiredCases.length}');
  stdout.writeln('commands=${plan.commands.length}');
  for (final command in plan.commands) {
    stdout.writeln('  $command');
  }
  return 0;
}
