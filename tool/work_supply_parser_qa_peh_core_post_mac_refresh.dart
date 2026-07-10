import 'dart:convert';
import 'dart:io';

import 'reusable_parsing_qa_handoff_checkpoint.dart';
import 'reusable_parsing_qa_handoff_refresh.dart';
import 'reusable_parsing_qa_handoff_status.dart';
import 'reusable_parsing_qa_handoff_summary.dart';
import 'work_supply_parser_qa_peh_core_refresh.dart';

const _usage =
    'dart run tool/work_supply_parser_qa_peh_core_post_mac_refresh.dart '
    '[--root .] '
    '[--mac-wave build/parser_qa_pipeline/peh_core_mac_wave_commands.json] '
    '[--windows-status build/parser_qa_pipeline/peh_core_windows_status_rollup.json] '
    '[--plumbing-status build/parser_qa_pipeline/plumbing_core_generated_run_status.json] '
    '[--electrical-status build/parser_qa_pipeline/windows_electrical_core_generated_run_status_50.json] '
    '[--hvac-status build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json] '
    '[--mac-wave-status-output build/parser_qa_pipeline/peh_core_mac_wave_status.json] '
    '[--merged-status-output build/parser_qa_pipeline/peh_core_merged_status_rollup.json] '
    '[--claim-output build/parser_qa_pipeline/peh_core_claim_readiness.json]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaPehCorePostMacRefresh(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaPehCorePostMacRefresh(
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
  final plumbingStatusPath = _value(
    args,
    'plumbing-status',
    'build/parser_qa_pipeline/plumbing_core_generated_run_status.json',
  );
  final electricalStatusPath = _value(
    args,
    'electrical-status',
    'build/parser_qa_pipeline/windows_electrical_core_generated_run_status_50.json',
  );
  final hvacStatusPath = _value(
    args,
    'hvac-status',
    'build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json',
  );
  final macWaveStatusOutput = _value(
    args,
    'mac-wave-status-output',
    'build/parser_qa_pipeline/peh_core_mac_wave_status.json',
  );
  final mergedStatusOutput = _value(
    args,
    'merged-status-output',
    'build/parser_qa_pipeline/peh_core_merged_status_rollup.json',
  );
  final claimOutput = _value(
    args,
    'claim-output',
    'build/parser_qa_pipeline/peh_core_claim_readiness.json',
  );

  final previous = Directory.current;
  Directory.current = Directory(root);
  try {
    final existingDocsPacket = _readOptionalJson(
      'docs/reusable_parsing_qa_mac_handoff_packet.json',
    );

    final pehRefreshStdout = _MemorySink();
    final pehRefreshExit = runWorkSupplyParserQaPehCoreRefresh(
      [
        '--mac-wave',
        macWavePath,
        '--windows-status',
        windowsStatusPath,
        '--plumbing-status',
        plumbingStatusPath,
        '--electrical-status',
        electricalStatusPath,
        '--hvac-status',
        hvacStatusPath,
        '--mac-wave-status-output',
        macWaveStatusOutput,
        '--merged-status-output',
        mergedStatusOutput,
        '--claim-output',
        claimOutput,
      ],
      stdout: pehRefreshStdout,
      stderr: stderr,
    );

    final handoffRefreshStdout = _MemorySink();
    final handoffRefreshArgs = <String>['--root', '.'];
    final branch = existingDocsPacket['primaryBranch']?.toString();
    final commit = existingDocsPacket['baselineCommit']?.toString();
    final commitFull = existingDocsPacket['baselineCommitFull']?.toString();
    final label = existingDocsPacket['baselineCommitLabel']?.toString();
    final updatedAt = existingDocsPacket['generatedAtEdt']?.toString();
    if (branch != null && branch.isNotEmpty) {
      handoffRefreshArgs.addAll(['--branch', branch]);
    }
    if (commit != null && commit.isNotEmpty) {
      handoffRefreshArgs.addAll(['--commit', commit]);
    }
    if (commitFull != null && commitFull.isNotEmpty) {
      handoffRefreshArgs.addAll(['--commit-full', commitFull]);
    }
    if (label != null && label.isNotEmpty) {
      handoffRefreshArgs.addAll(['--label', label]);
    }
    if (updatedAt != null && updatedAt.isNotEmpty) {
      handoffRefreshArgs.addAll(['--updated-at', updatedAt]);
    }
    final handoffRefreshExit = runReusableParsingQaHandoffRefresh(
      handoffRefreshArgs,
      stdout: handoffRefreshStdout,
      stderr: stderr,
    );

    final checkpointStdout = _MemorySink();
    final checkpointExit = runReusableParsingQaHandoffCheckpoint(
      const ['--root', '.'],
      stdout: checkpointStdout,
      stderr: stderr,
    );

    final statusStdout = _MemorySink();
    final statusExit = runReusableParsingQaHandoffStatus(
      const ['--root', '.'],
      stdout: statusStdout,
      stderr: stderr,
    );

    final summaryStdout = _MemorySink();
    final summaryExit = runReusableParsingQaHandoffSummary(
      const ['--root', '.'],
      stdout: summaryStdout,
      stderr: stderr,
    );

    final statusSummary = _extractPrefixedJson(
      statusStdout.content,
      'QA_REUSABLE_PARSING_HANDOFF_STATUS ',
    );
    final handoffSummary = _extractPrefixedJson(
      summaryStdout.content,
      'QA_REUSABLE_PARSING_HANDOFF_SUMMARY ',
    );

    final result = {
      'schemaVersion': 1,
      'report': 'work_supply_parser_qa_peh_core_post_mac_refresh',
      'root': root,
      'macWavePath': macWavePath,
      'windowsStatusPath': windowsStatusPath,
      'plumbingStatusPath': plumbingStatusPath,
      'electricalStatusPath': electricalStatusPath,
      'hvacStatusPath': hvacStatusPath,
      'macWaveStatusOutput': macWaveStatusOutput,
      'mergedStatusOutput': mergedStatusOutput,
      'claimOutput': claimOutput,
      'pehRefreshExit': pehRefreshExit,
      'handoffRefreshExit': handoffRefreshExit,
      'checkpointExit': checkpointExit,
      'statusExit': statusExit,
      'summaryExit': summaryExit,
      'handoffClean': handoffSummary['handoffClean'] == true,
      'docsAligned': statusSummary['docsAligned'],
      'parityApplicable': statusSummary['parityApplicable'],
      'parityOk': statusSummary['parityOk'],
      'packetExecutionHeadAligned': statusSummary['packetExecutionHeadAligned'],
      'scriptExecutionHeadAligned': statusSummary['scriptExecutionHeadAligned'],
      'readyForMacMeasurementWave': handoffSummary['readyForMacMeasurementWave'],
      'readyToClaimNinetyPlus': handoffSummary['readyToClaimNinetyPlus'],
      'totalRemainingChecked': handoffSummary['totalRemainingChecked'],
      'nextTradesByRemainingGap': handoffSummary['nextTradesByRemainingGap'],
      'claimBlockingFindings': handoffSummary['claimBlockingFindings'],
      'claimNextActions': handoffSummary['claimNextActions'],
      'generatedAtIso': DateTime.now().toUtc().toIso8601String(),
    };

    stdout.writeln(
      'QA_PEH_CORE_POST_MAC_REFRESH '
      '${const JsonEncoder.withIndent('  ').convert(result)}',
    );

    return [
      pehRefreshExit,
      handoffRefreshExit,
      checkpointExit,
      statusExit,
      summaryExit,
    ].reduce((left, right) => left > right ? left : right);
  } finally {
    Directory.current = previous;
  }
}

Map<String, Object?> _extractPrefixedJson(String output, String prefix) {
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

Map<String, Object?> _readOptionalJson(String path) {
  final file = File(path);
  if (!file.existsSync()) return const {};
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is Map<String, Object?>) return decoded;
  if (decoded is Map) return decoded.cast<String, Object?>();
  return const {};
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
