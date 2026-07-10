import 'dart:convert';
import 'dart:io';

import 'reusable_parsing_qa_handoff_summary.dart';
import 'work_supply_parser_qa_peh_core_mac_handoff_packet.dart';
import 'work_supply_parser_qa_peh_core_mac_handoff_script.dart';

const _usage =
    'dart run tool/work_supply_parser_qa_peh_core_restamp_handoff.dart '
    '[--root .] '
    '[--mac-wave build/parser_qa_pipeline/peh_core_mac_wave_commands.json] '
    '[--windows-status build/parser_qa_pipeline/peh_core_windows_status_rollup.json] '
    '[--packet-output build/parser_qa_pipeline/peh_core_mac_handoff_packet.json] '
    '[--script-output build/parser_qa_pipeline/peh_core_mac_handoff.sh]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaPehCoreRestampHandoff(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaPehCoreRestampHandoff(
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

  final previous = Directory.current;
  Directory.current = Directory(root);
  try {
    final packetStdout = _MemorySink();
    final packetExit = runWorkSupplyParserQaPehCoreMacHandoffPacket(
      [
        '--mac-wave',
        macWavePath,
        '--windows-status',
        windowsStatusPath,
        '--output',
        packetOutput,
      ],
      stdout: packetStdout,
      stderr: stderr,
    );

    final scriptStdout = _MemorySink();
    final scriptExit = packetExit == 0
        ? runWorkSupplyParserQaPehCoreMacHandoffScript(
            [
              '--packet',
              packetOutput,
              '--output',
              scriptOutput,
            ],
            stdout: scriptStdout,
            stderr: stderr,
          )
        : 1;

    final summaryStdout = _MemorySink();
    final summaryExit = packetExit == 0 && scriptExit == 0
        ? runReusableParsingQaHandoffSummary(
            ['--root', '.'],
            stdout: summaryStdout,
            stderr: stderr,
          )
        : 1;

    final summary = _extractSummary(summaryStdout.content);
    final packet = _readOptionalJson(packetOutput);
    final result = {
      'schemaVersion': 1,
      'report': 'work_supply_parser_qa_peh_core_restamp_handoff',
      'root': root,
      'macWavePath': macWavePath,
      'windowsStatusPath': windowsStatusPath,
      'packetOutput': packetOutput,
      'scriptOutput': scriptOutput,
      'packetExit': packetExit,
      'scriptExit': scriptExit,
      'summaryExit': summaryExit,
      'handoffClean': summary['handoffClean'] == true,
      'windowsExecutionCommit':
          summary['windowsExecutionCommit'] ?? packet['inventoryExecutionCommit'],
      'measurementCommandCount':
          summary['measurementCommandCount'] ?? packet['measurementCommandCount'],
      'rollupCommandCount':
          summary['rollupCommandCount'] ?? packet['rollupCommandCount'],
      'generatedAtIso': DateTime.now().toUtc().toIso8601String(),
    };

    stdout.writeln(
      'QA_PEH_CORE_RESTAMP_HANDOFF '
      '${const JsonEncoder.withIndent('  ').convert(result)}',
    );

    return [packetExit, scriptExit, summaryExit]
        .reduce((left, right) => left > right ? left : right);
  } finally {
    Directory.current = previous;
  }
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

Map<String, Object?> _readOptionalJson(String path) {
  final file = File(path);
  if (!file.existsSync()) return const {};
  final decoded = jsonDecode(file.readAsStringSync());
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
