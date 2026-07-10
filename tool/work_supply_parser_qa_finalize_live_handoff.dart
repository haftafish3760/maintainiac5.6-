import 'dart:convert';
import 'dart:io';

import 'reusable_parsing_qa_handoff_summary.dart';
import 'reusable_parsing_qa_handoff_sync.dart';
import 'work_supply_parser_qa_peh_core_restamp_handoff.dart';

const _usage =
    'dart run tool/work_supply_parser_qa_finalize_live_handoff.dart '
    '[--root .] '
    '[--branch codex/reusable-parsing-qa-foundation] '
    '[--commit 8e9771d] '
    '[--commit-full <full sha>] '
    '[--label <validated floor label>] '
    '[--updated-at "YYYY-MM-DD HH:MM EDT"] '
    '[--mac-wave build/parser_qa_pipeline/peh_core_mac_wave_commands.json] '
    '[--windows-status build/parser_qa_pipeline/peh_core_windows_status_rollup.json] '
    '[--packet-output build/parser_qa_pipeline/peh_core_mac_handoff_packet.json] '
    '[--script-output build/parser_qa_pipeline/peh_core_mac_handoff.sh]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaFinalizeLiveHandoff(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaFinalizeLiveHandoff(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }

  final root = _value(args, 'root', '.');
  final macWavePath = _value(
    args,
    'mac-wave',
    'build/parser_qa_pipeline/peh_core_mac_wave_commands.json',
  );
  final windowsStatusPath = _value(
    args,
    'windows-status',
    'build/parser_qa_pipeline/peh_core_windows_status_rollup.json',
  );
  final packetOutput = _value(
    args,
    'packet-output',
    'build/parser_qa_pipeline/peh_core_mac_handoff_packet.json',
  );
  final scriptOutput = _value(
    args,
    'script-output',
    'build/parser_qa_pipeline/peh_core_mac_handoff.sh',
  );

  final restampStdout = _MemorySink();
  final restampExit = runWorkSupplyParserQaPehCoreRestampHandoff(
    [
      '--root',
      root,
      '--mac-wave',
      macWavePath,
      '--windows-status',
      windowsStatusPath,
      '--packet-output',
      packetOutput,
      '--script-output',
      scriptOutput,
    ],
    stdout: restampStdout,
    stderr: stderr,
  );

  final syncStdout = _MemorySink();
  final syncExit = restampExit == 0
      ? runReusableParsingQaHandoffSync(
          args,
          stdout: syncStdout,
          stderr: stderr,
        )
      : 1;

  final summaryStdout = _MemorySink();
  final summaryExit = restampExit == 0 && syncExit == 0
      ? runReusableParsingQaHandoffSummary(
          ['--root', root],
          stdout: summaryStdout,
          stderr: stderr,
        )
      : 1;

  final summary = _extractSummary(summaryStdout.content);
  final result = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_finalize_live_handoff',
    'root': root,
    'macWavePath': macWavePath,
    'windowsStatusPath': windowsStatusPath,
    'packetOutput': packetOutput,
    'scriptOutput': scriptOutput,
    'restampExit': restampExit,
    'syncExit': syncExit,
    'summaryExit': summaryExit,
    'handoffClean': summary['handoffClean'] == true,
    'windowsExecutionCommit': summary['windowsExecutionCommit'],
    'packetExecutionHeadAligned': summary['packetExecutionHeadAligned'],
    'scriptExecutionHeadAligned': summary['scriptExecutionHeadAligned'],
    'expectedLocalDocsRefreshDirty': summary['expectedLocalDocsRefreshDirty'],
    'localModifiedFiles': summary['localModifiedFiles'] ?? const <Object>[],
    'measurementCommandCount': summary['measurementCommandCount'] ?? 0,
    'rollupCommandCount': summary['rollupCommandCount'] ?? 0,
    'generatedAtIso': DateTime.now().toUtc().toIso8601String(),
  };

  stdout.writeln(
    'QA_PARSER_LIVE_HANDOFF_FINALIZE '
    '${const JsonEncoder.withIndent('  ').convert(result)}',
  );

  return [restampExit, syncExit, summaryExit]
      .reduce((left, right) => left > right ? left : right);
}

Map<String, Object?> _extractSummary(String output) {
  const prefix = 'QA_REUSABLE_PARSING_HANDOFF_SUMMARY ';
  final start = output.indexOf(prefix);
  if (start < 0) return const {};
  final jsonText = output.substring(start + prefix.length).trim();
  final decoded = jsonDecode(jsonText);
  if (decoded is Map<String, Object?>) return decoded;
  if (decoded is Map) return decoded.cast<String, Object?>();
  return const {};
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}

class _MemorySink implements IOSink {
  final _buffer = StringBuffer();

  String get content => _buffer.toString();

  @override
  void write(Object? object) => _buffer.write(object);

  @override
  void writeln([Object? object = '']) => _buffer.writeln(object);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
