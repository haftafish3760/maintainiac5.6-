import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_peh_core_merged_status_rollup.dart '
    '[--plumbing-status build/parser_qa_pipeline/plumbing_core_generated_run_status.json] '
    '[--electrical-status build/parser_qa_pipeline/mac_electrical_core_generated_run_status_25.json] '
    '[--hvac-status build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json] '
    '[--electrical-target-checked 50] [--hvac-target-checked 50] '
    '[--output build/parser_qa_pipeline/peh_core_merged_status_rollup.json]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaPehCoreMergedStatusRollup(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaPehCoreMergedStatusRollup(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }

  final plumbingStatus = _value(
    args,
    'plumbing-status',
    'build/parser_qa_pipeline/plumbing_core_generated_run_status.json',
  );
  final electricalStatus = _value(
    args,
    'electrical-status',
    'build/parser_qa_pipeline/mac_electrical_core_generated_run_status_25.json',
  );
  final hvacStatus = _value(
    args,
    'hvac-status',
    'build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json',
  );
  final electricalTargetChecked =
      int.tryParse(_value(args, 'electrical-target-checked', '50')) ?? 50;
  final hvacTargetChecked =
      int.tryParse(_value(args, 'hvac-target-checked', '50')) ?? 50;
  final output = _value(
    args,
    'output',
    'build/parser_qa_pipeline/peh_core_merged_status_rollup.json',
  );

  if (electricalTargetChecked <= 0 || hvacTargetChecked <= 0) {
    stderr.writeln(
      '--electrical-target-checked and --hvac-target-checked must be positive.',
    );
    return 64;
  }

  final trades = [
    _readTradeStatus(
      trade: 'plumbing',
      source: 'windows_rollup',
      path: plumbingStatus,
      targetChecked: 100,
      measuredClaimCheckedFloor: 100,
    ),
    _readTradeStatus(
      trade: 'electrical',
      source: 'mac_rollup',
      path: electricalStatus,
      targetChecked: electricalTargetChecked,
      measuredClaimCheckedFloor: electricalTargetChecked,
    ),
    _readTradeStatus(
      trade: 'hvac',
      source: 'mac_rollup',
      path: hvacStatus,
      targetChecked: hvacTargetChecked,
      measuredClaimCheckedFloor: hvacTargetChecked,
    ),
  ];

  final missingTrades = trades.where((trade) => trade['status'] == 'missing');
  final unsafeTrades = trades.where((trade) => trade['localOnlySafe'] == false);
  final failedTrades = trades.where(
    (trade) => ((trade['failureCount'] as int?) ?? 0) > 0,
  );
  final underTargetTrades = trades.where(
    (trade) => trade['underTargetChecked'] == true,
  );
  final sampleSizedTrades = trades.where(
    (trade) => trade['sampleSizedEvidence'] == true,
  );

  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_peh_core_merged_status_rollup',
    'targetChecked': {
      'plumbing': 100,
      'electrical': electricalTargetChecked,
      'hvac': hvacTargetChecked,
    },
    'tradeCount': trades.length,
    'missingTradeCount': missingTrades.length,
    'unsafeTradeCount': unsafeTrades.length,
    'failedTradeCount': failedTrades.length,
    'underTargetTradeCount': underTargetTrades.length,
    'sampleSizedTradeCount': sampleSizedTrades.length,
    'readyForMergedClaimWave':
        missingTrades.isEmpty &&
        unsafeTrades.isEmpty &&
        failedTrades.isEmpty,
    'readyToClaimNinetyPlus':
        missingTrades.isEmpty &&
        unsafeTrades.isEmpty &&
        failedTrades.isEmpty &&
        underTargetTrades.isEmpty,
    'trades': trades,
    'generatedAtIso': DateTime.now().toUtc().toIso8601String(),
  };

  final file = File(output)..parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(summary),
    flush: true,
  );
  stdout.writeln(
    'QA_PEH_CORE_MERGED_STATUS_ROLLUP '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln(
    'QA_PEH_CORE_MERGED_STATUS_ROLLUP_ARTIFACT json=${file.path}',
  );

  if (missingTrades.isNotEmpty || unsafeTrades.isNotEmpty || failedTrades.isNotEmpty) {
    return 2;
  }
  if (underTargetTrades.isNotEmpty) return 1;
  return 0;
}

Map<String, Object?> _readTradeStatus({
  required String trade,
  required String source,
  required String path,
  required int targetChecked,
  required int measuredClaimCheckedFloor,
}) {
  final file = File(path);
  if (!file.existsSync()) {
    return {
      'trade': trade,
      'source': source,
      'status': 'missing',
      'statusPath': path,
      'checkedTotal': 0,
      'failureCount': 0,
      'passRate': 0.0,
      'parserCalls': 0,
      'underTargetChecked': true,
      'sampleSizedEvidence': true,
      'localOnlySafe': false,
      'readyToClaimNinetyPlus': false,
    };
  }

  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  final checkedTotal = (json['checkedTotal'] as int?) ?? 0;
  final failureCount = (json['failureCount'] as int?) ?? 0;
  final passRate = (json['passRate'] as num?)?.toDouble() ?? 0.0;
  final parserCalls = (json['parserCalls'] as int?) ?? 0;
  final underTargetChecked = checkedTotal < targetChecked;
  final sampleSizedEvidence = checkedTotal < measuredClaimCheckedFloor;
  final localOnlySafe =
      json['liveServicesAllowed'] == false &&
      json['writesProductionCatalog'] == false &&
      json['firebaseWritesAllowed'] == false &&
      json['ocrCameraExpensesTouched'] == false &&
      ((json['unsafeCells'] as int?) ?? 0) == 0;

  return {
    'trade': trade,
    'source': source,
    'status': 'present',
    'statusPath': path,
    'checkedTotal': checkedTotal,
    'failureCount': failureCount,
    'passRate': passRate,
    'parserCalls': parserCalls,
    'underTargetChecked': underTargetChecked,
    'sampleSizedEvidence': sampleSizedEvidence,
    'localOnlySafe': localOnlySafe,
    'readyToClaimNinetyPlus':
        localOnlySafe && failureCount == 0 && !underTargetChecked,
  };
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
