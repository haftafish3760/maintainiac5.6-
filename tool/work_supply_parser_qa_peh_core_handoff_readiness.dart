import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_peh_core_handoff_readiness.dart '
    '[--windows-status build/parser_qa_pipeline/peh_core_windows_status_rollup.json] '
    '[--mac-wave build/parser_qa_pipeline/peh_core_mac_wave_commands.json] '
    '[--output build/parser_qa_pipeline/peh_core_handoff_readiness.json]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaPehCoreHandoffReadiness(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaPehCoreHandoffReadiness(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }

  final windowsStatusPath = _value(
    args,
    'windows-status',
    'build/parser_qa_pipeline/peh_core_windows_status_rollup.json',
  );
  final macWavePath = _value(
    args,
    'mac-wave',
    'build/parser_qa_pipeline/peh_core_mac_wave_commands.json',
  );
  final output = _value(
    args,
    'output',
    'build/parser_qa_pipeline/peh_core_handoff_readiness.json',
  );

  final windowsFile = File(windowsStatusPath);
  final macWaveFile = File(macWavePath);
  if (!windowsFile.existsSync() || !macWaveFile.existsSync()) {
    stderr.writeln('--windows-status and --mac-wave must both exist.');
    return 66;
  }

  final windows =
      jsonDecode(windowsFile.readAsStringSync()) as Map<String, Object?>;
  final macWave =
      jsonDecode(macWaveFile.readAsStringSync()) as Map<String, Object?>;

  final findings = <String>[];
  final nextActions = <String>[];

  final readyForMacMeasurementWave =
      windows['readyForMacMeasurementWave'] == true;
  if (!readyForMacMeasurementWave) {
    findings.add('windows_status_not_ready_for_mac_measurement_wave');
  }

  final readyToClaimNinetyPlus = windows['readyToClaimNinetyPlus'] == true;
  if (!readyToClaimNinetyPlus) {
    nextActions.add(
      'Keep the branch below a 90-95 percent claim until Electrical and HVAC clear their broader measured Mac wave.',
    );
  }

  final tradeCount = (windows['tradeCount'] as int?) ?? 0;
  if (tradeCount != 3) {
    findings.add('unexpected_trade_count');
  }

  final measurementCommandCount =
      (macWave['measurementCommandCount'] as int?) ?? 0;
  if (measurementCommandCount != 4) {
    findings.add('unexpected_measurement_command_count');
  }

  final rollupCommandCount = (macWave['rollupCommandCount'] as int?) ?? 0;
  if (rollupCommandCount != 2) {
    findings.add('unexpected_rollup_command_count');
  }

  final plumbingFocusedRuntimeCommand =
      macWave['plumbingFocusedRuntimeCommand'] as List<dynamic>?;
  if (plumbingFocusedRuntimeCommand == null ||
      plumbingFocusedRuntimeCommand.isEmpty) {
    findings.add('missing_plumbing_focused_runtime_command');
  }

  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_peh_core_handoff_readiness',
    'windowsStatusPath': windowsStatusPath,
    'macWavePath': macWavePath,
    'readyForMacMeasurementWave': readyForMacMeasurementWave,
    'readyToClaimNinetyPlus': readyToClaimNinetyPlus,
    'tradeCount': tradeCount,
    'measurementCommandCount': measurementCommandCount,
    'rollupCommandCount': rollupCommandCount,
    'handoffReady':
        readyForMacMeasurementWave &&
        tradeCount == 3 &&
        measurementCommandCount == 4 &&
        rollupCommandCount == 2 &&
        plumbingFocusedRuntimeCommand != null &&
        plumbingFocusedRuntimeCommand.isNotEmpty,
    'blockingFindings': findings,
    'nextActions': nextActions,
    'generatedAtIso': DateTime.now().toUtc().toIso8601String(),
  };

  final file = File(output)..parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(summary),
    flush: true,
  );
  stdout.writeln(
    'QA_PEH_CORE_HANDOFF_READINESS '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln('QA_PEH_CORE_HANDOFF_READINESS_ARTIFACT json=${file.path}');
  return summary['handoffReady'] == true ? 0 : 1;
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
