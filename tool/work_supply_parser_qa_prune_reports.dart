import 'dart:convert';
import 'dart:io';

import '../test/support/qa_harness/qa_report_retention.dart';

const _usage =
    'dart run tool/work_supply_parser_qa_prune_reports.dart '
    '[--domain work_supply_inventory_parser] '
    '[--output-dir build/parser_qa_reports] [--keep 20] [--execute]';

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return;
  }

  final result = runQaReportPrune(args);
  if (result.stderr.isNotEmpty) stderr.writeln(result.stderr);
  if (result.stdout.isNotEmpty) stdout.writeln(result.stdout);
  if (result.exitCode != 0) exitCode = result.exitCode;
}

QaReportPruneCommandResult runQaReportPrune(List<String> args) {
  late final _PruneOptions? options;
  try {
    options = _PruneOptions.parse(args);
  } on FormatException catch (error) {
    return QaReportPruneCommandResult(
      exitCode: 64,
      stdout: '',
      stderr: error.message,
    );
  }
  if (options == null) {
    return const QaReportPruneCommandResult(
      exitCode: 64,
      stdout: '',
      stderr: 'Invalid QA report prune options.',
    );
  }

  final summary = pruneQaReportArtifacts(
    domain: options.domain,
    outputDirectory: options.outputDirectory,
    keepLatestTimestamped: options.keep,
    dryRun: !options.execute,
  );

  return QaReportPruneCommandResult(
    exitCode: 0,
    stdout:
        'QA_RETENTION_SUMMARY ${const JsonEncoder.withIndent('  ').convert({'domain': summary.domain, 'outputDirectory': options.outputDirectory, 'keepLatestTimestamped': options.keep, 'dryRun': !options.execute, 'keptTimestampedReports': summary.keptTimestampedReports, 'deletedTimestampedReports': summary.deletedTimestampedReports, 'keptPackHealthReports': summary.keptPackHealthReports, 'deletedPackHealthReports': summary.deletedPackHealthReports, 'preservedAliases': summary.preservedAliases, 'deletedCount': summary.deletedCount})}',
    stderr: '',
  );
}

class QaReportPruneCommandResult {
  const QaReportPruneCommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

class _PruneOptions {
  const _PruneOptions({
    required this.domain,
    required this.outputDirectory,
    required this.keep,
    required this.execute,
  });

  final String domain;
  final String outputDirectory;
  final int keep;
  final bool execute;

  static _PruneOptions? parse(List<String> args) {
    var domain = 'work_supply_inventory_parser';
    var outputDirectory = 'build/parser_qa_reports';
    var keep = 20;
    var execute = false;

    for (var index = 0; index < args.length; index += 1) {
      final arg = args[index];
      switch (arg) {
        case '--domain':
          domain = _requireValue(args, index, arg);
          index += 1;
          break;
        case '--output-dir':
          outputDirectory = _requireValue(args, index, arg);
          index += 1;
          break;
        case '--keep':
          keep = int.parse(_requireValue(args, index, arg));
          index += 1;
          break;
        case '--execute':
          execute = true;
          break;
        default:
          stderr.writeln('Unknown option: $arg\n$_usage');
          return null;
      }
    }

    return _PruneOptions(
      domain: domain,
      outputDirectory: outputDirectory,
      keep: keep,
      execute: execute,
    );
  }

  static String _requireValue(List<String> args, int index, String option) {
    if (index + 1 >= args.length || args[index + 1].startsWith('--')) {
      throw FormatException('Missing value for $option\n$_usage');
    }
    return args[index + 1];
  }
}
