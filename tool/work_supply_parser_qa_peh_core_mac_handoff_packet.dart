import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_peh_core_mac_handoff_packet.dart '
    '[--branch <auto-from-git>] '
    '[--commit <auto-from-git>] '
    '[--mac-wave build/parser_qa_pipeline/peh_core_mac_wave_commands.json] '
    '[--windows-status build/parser_qa_pipeline/peh_core_windows_status_rollup.json] '
    '[--output build/parser_qa_pipeline/peh_core_mac_handoff_packet.json]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaPehCoreMacHandoffPacket(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaPehCoreMacHandoffPacket(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }

  final branchOverride = _optionalValue(args, 'branch');
  final commitOverride = _optionalValue(args, 'commit');
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
  final output = _value(
    args,
    'output',
    'build/parser_qa_pipeline/peh_core_mac_handoff_packet.json',
  );

  final macWaveFile = File(macWavePath);
  final windowsStatusFile = File(windowsStatusPath);
  if (!macWaveFile.existsSync() || !windowsStatusFile.existsSync()) {
    stderr.writeln('--mac-wave and --windows-status must both exist.');
    return 66;
  }

  final branch =
      branchOverride ??
      _gitValue(['rev-parse', '--abbrev-ref', 'HEAD']) ??
      'unknown-branch';
  final commit =
      commitOverride ??
      _gitValue(['rev-parse', '--short', 'HEAD']) ??
      'unknown-commit';

  final macWave =
      jsonDecode(macWaveFile.readAsStringSync()) as Map<String, Object?>;
  final windows =
      jsonDecode(windowsStatusFile.readAsStringSync()) as Map<String, Object?>;
  final measurementGap = _readOptionalJson(
    'build/parser_qa_pipeline/peh_core_measurement_gap.json',
  );
  final claimReadiness = _readOptionalJson(
    'build/parser_qa_pipeline/peh_core_claim_readiness.json',
  );
  final reusableCheckpoint = _readReusableCheckpoint();

  final measurementCommands =
      (macWave['measurementCommands'] as List<dynamic>? ?? const <dynamic>[]);
  final rollupCommands =
      (macWave['rollupCommands'] as List<dynamic>? ?? const <dynamic>[]);
  final selectedTrades =
      (macWave['selectedTrades'] as List<dynamic>? ?? const <dynamic>[])
          .map((trade) => trade.toString())
          .where((trade) => trade.isNotEmpty)
          .toList(growable: false);

  final expectedOutputs = [
    for (final trade in selectedTrades)
      'build/parser_qa_pipeline/mac_${trade}_core_generated_run_status_25.json',
    'build/parser_qa_pipeline/peh_core_mac_wave_status.json',
    'build/parser_qa_pipeline/peh_core_merged_status_rollup.json',
    'build/parser_qa_pipeline/peh_core_claim_readiness.json',
  ];

  final electricalRefreshStatus = selectedTrades.contains('electrical')
      ? 'build/parser_qa_pipeline/mac_electrical_core_generated_run_status_25.json'
      : 'build/parser_qa_pipeline/windows_electrical_core_generated_run_status_50.json';
  final hvacRefreshStatus = selectedTrades.contains('hvac')
      ? 'build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json'
      : 'build/parser_qa_pipeline/hvac_core_generated_run_status_samples.json';

  final refreshCommand = [
    'dart',
    'run',
    'tool/work_supply_parser_qa_peh_core_refresh.dart',
    '--mac-wave',
    macWavePath,
    '--windows-status',
    windowsStatusPath,
    '--plumbing-status',
    'build/parser_qa_pipeline/plumbing_core_generated_run_status.json',
    '--electrical-status',
    electricalRefreshStatus,
    '--hvac-status',
    hvacRefreshStatus,
  ];

  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_peh_core_mac_handoff_packet',
    'branch': branch,
    'commit': commit,
    'reusableBaselineBranch':
        reusableCheckpoint['primaryBranch'] ??
        'codex/reusable-parsing-qa-foundation',
    'reusableValidatedFloorCommit':
        reusableCheckpoint['validatedFloorCommit'] ?? 'unknown',
    'reusableValidatedFloorLabel':
        reusableCheckpoint['validatedFloorLabel'] ?? 'unknown',
    'reusableCheckpointJsonPath': 'docs/reusable_parsing_qa_checkpoint.json',
    'reusableCheckpointMarkdownPath': 'docs/reusable_parsing_qa_checkpoint.md',
    'reusableHandoffMarkerPath': 'docs/reusable_parsing_qa_handoff_marker.md',
    'reusableRunbookPath': 'docs/reusable_parsing_qa_mac_runbook.md',
    'inventoryExecutionBranch': branch,
    'inventoryExecutionCommit': commit,
    'executionOrder': [
      'Read the reusable parser QA marker and checkpoint first.',
      'Start reusable parser-domain work from the reusable baseline branch.',
      'Use the inventory execution branch/commit for the current PEH measurement wave commands.',
      'Run measurement commands, then rollups, then the PEH refresh command.',
    ],
    'macWavePath': macWavePath,
    'windowsStatusPath': windowsStatusPath,
    'measurementGapPath': 'build/parser_qa_pipeline/peh_core_measurement_gap.json',
    'claimReadinessPath': 'build/parser_qa_pipeline/peh_core_claim_readiness.json',
    'readyForMacMeasurementWave': windows['readyForMacMeasurementWave'] == true,
    'readyToClaimNinetyPlus': false,
    'totalRemainingChecked':
        measurementGap['totalRemainingChecked'] ??
        reusableCheckpoint['totalRemainingChecked'] ??
        0,
    'nextTradesByRemainingGap':
        measurementGap['nextTradesByRemainingGap'] ??
        reusableCheckpoint['nextTradesByRemainingGap'] ??
        const <Object>[],
    'tradeGaps': measurementGap['tradeGaps'] ?? const <Object>[],
    'claimBlockingFindings':
        claimReadiness['blockingFindings'] ?? const <Object>[],
    'claimNextActions': claimReadiness['nextActions'] ?? const <Object>[],
    'measurementCommandCount': measurementCommands.length,
    'rollupCommandCount': rollupCommands.length,
    'selectedTrades': selectedTrades,
    'measurementCommands': measurementCommands,
    'rollupCommands': rollupCommands,
    'expectedOutputs': expectedOutputs,
    'refreshCommand': refreshCommand,
    'generatedAtIso': DateTime.now().toUtc().toIso8601String(),
  };

  final outputFile = File(output)..parent.createSync(recursive: true);
  outputFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(summary),
    flush: true,
  );
  stdout.writeln(
    'QA_PEH_CORE_MAC_HANDOFF_PACKET '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln(
    'QA_PEH_CORE_MAC_HANDOFF_PACKET_ARTIFACT json=${outputFile.path}',
  );
  return summary['readyForMacMeasurementWave'] == true ? 0 : 1;
}

String _value(List<String> args, String key, String fallback) {
  return _optionalValue(args, key) ?? fallback;
}

String? _optionalValue(List<String> args, String key) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return null;
}

String? _gitValue(List<String> command) {
  final result = Process.runSync('git', command);
  if (result.exitCode != 0) {
    return null;
  }
  return result.stdout.toString().trim();
}

Map<String, Object?> _readReusableCheckpoint() {
  final file = File('docs/reusable_parsing_qa_checkpoint.json');
  return _readOptionalJson(file.path);
}

Map<String, Object?> _readOptionalJson(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return const {};
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is Map<String, Object?>) {
    return decoded;
  }
  if (decoded is Map) {
    return decoded.cast<String, Object?>();
  }
  return const {};
}
