import 'dart:convert';
import 'dart:io';

import 'work_supply_parser_qa_peh_core_claim_readiness.dart';
import 'work_supply_parser_qa_peh_core_mac_wave_status.dart';
import 'work_supply_parser_qa_peh_core_merged_status_rollup.dart';

const _usage =
    'dart run tool/work_supply_parser_qa_peh_core_refresh.dart '
    '[--mac-wave build/parser_qa_pipeline/peh_core_mac_wave_commands.json] '
    '[--windows-status build/parser_qa_pipeline/peh_core_windows_status_rollup.json] '
    '[--plumbing-status build/parser_qa_pipeline/plumbing_core_generated_run_status.json] '
    '[--electrical-status build/parser_qa_pipeline/mac_electrical_core_generated_run_status_25.json] '
    '[--hvac-status build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json] '
    '[--mac-wave-status-output build/parser_qa_pipeline/peh_core_mac_wave_status.json] '
    '[--merged-status-output build/parser_qa_pipeline/peh_core_merged_status_rollup.json] '
    '[--claim-output build/parser_qa_pipeline/peh_core_claim_readiness.json]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaPehCoreRefresh(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaPehCoreRefresh(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }

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
    'build/parser_qa_pipeline/mac_electrical_core_generated_run_status_25.json',
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

  final macWaveExit = runWorkSupplyParserQaPehCoreMacWaveStatus(
    ['--mac-wave', macWavePath, '--output', macWaveStatusOutput],
    stdout: stdout,
    stderr: stderr,
  );

  final mergedExit = runWorkSupplyParserQaPehCoreMergedStatusRollup(
    [
      '--plumbing-status',
      plumbingStatusPath,
      '--electrical-status',
      electricalStatusPath,
      '--hvac-status',
      hvacStatusPath,
      '--output',
      mergedStatusOutput,
    ],
    stdout: stdout,
    stderr: stderr,
  );

  final claimExit = runWorkSupplyParserQaPehCoreClaimReadiness(
    [
      '--windows-status',
      windowsStatusPath,
      '--mac-wave-status',
      macWaveStatusOutput,
      '--output',
      claimOutput,
    ],
    stdout: stdout,
    stderr: stderr,
  );

  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_peh_core_refresh',
    'macWavePath': macWavePath,
    'windowsStatusPath': windowsStatusPath,
    'plumbingStatusPath': plumbingStatusPath,
    'electricalStatusPath': electricalStatusPath,
    'hvacStatusPath': hvacStatusPath,
    'macWaveStatusOutput': macWaveStatusOutput,
    'mergedStatusOutput': mergedStatusOutput,
    'claimOutput': claimOutput,
    'macWaveExit': macWaveExit,
    'mergedExit': mergedExit,
    'claimExit': claimExit,
    'generatedAtIso': DateTime.now().toUtc().toIso8601String(),
  };

  stdout.writeln(
    'QA_PEH_CORE_REFRESH '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln(
    'QA_PEH_CORE_REFRESH_ARTIFACT '
    'macWaveStatus=$macWaveStatusOutput mergedStatus=$mergedStatusOutput claim=$claimOutput',
  );

  return [macWaveExit, mergedExit, claimExit]
      .reduce((left, right) => left > right ? left : right);
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
