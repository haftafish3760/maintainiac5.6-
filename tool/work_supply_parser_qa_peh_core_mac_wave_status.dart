import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_peh_core_mac_wave_status.dart '
    '[--mac-wave build/parser_qa_pipeline/peh_core_mac_wave_commands.json] '
    '[--output build/parser_qa_pipeline/peh_core_mac_wave_status.json]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaPehCoreMacWaveStatus(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaPehCoreMacWaveStatus(
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
  final output = _value(
    args,
    'output',
    'build/parser_qa_pipeline/peh_core_mac_wave_status.json',
  );

  final macWaveFile = File(macWavePath);
  if (!macWaveFile.existsSync()) {
    stderr.writeln('--mac-wave must exist.');
    return 66;
  }

  final macWave =
      jsonDecode(macWaveFile.readAsStringSync()) as Map<String, Object?>;
  final maxCases = (macWave['maxCases'] as int?) ?? 25;
  final minPassRate = (macWave['minPassRate'] as num?)?.toDouble() ?? 0.90;
  final measurementCommands =
      (macWave['measurementCommands'] as List<dynamic>? ?? const <dynamic>[]);
  final rollupCommands =
      (macWave['rollupCommands'] as List<dynamic>? ?? const <dynamic>[]);

  final tradeMeasurementCounts = <String, int>{};
  for (final command in measurementCommands) {
    if (command is! Map) continue;
    final trade = command['trade']?.toString() ?? 'unknown';
    tradeMeasurementCounts.update(trade, (value) => value + 1, ifAbsent: () => 1);
  }

  final tradeStatuses = <Map<String, Object?>>[];
  final blockingFindings = <String>[];
  final nextActions = <String>[];
  var completedRollupCount = 0;
  var missingRollupCount = 0;
  var readyTradeCount = 0;

  for (final rollup in rollupCommands) {
    if (rollup is! Map) continue;
    final trade = rollup['trade']?.toString() ?? 'unknown';
    final command = (rollup['command'] as List<dynamic>? ?? const <dynamic>[])
        .map((value) => value.toString())
        .toList();
    final statusPath = _outputPath(command);
    final expectedChecked = (tradeMeasurementCounts[trade] ?? 0) * maxCases;

    if (statusPath == null) {
      blockingFindings.add('missing_rollup_output_path:$trade');
      tradeStatuses.add({
        'trade': trade,
        'status': 'missing_output_path',
        'expectedChecked': expectedChecked,
        'readyToMerge': false,
      });
      continue;
    }

    final statusFile = File(statusPath);
    if (!statusFile.existsSync()) {
      missingRollupCount += 1;
      blockingFindings.add('missing_rollup_status:$trade');
      nextActions.add('Run or copy the $trade Mac rollup into $statusPath.');
      tradeStatuses.add({
        'trade': trade,
        'statusPath': statusPath,
        'status': 'missing',
        'expectedChecked': expectedChecked,
        'readyToMerge': false,
      });
      continue;
    }

    completedRollupCount += 1;
    final json = jsonDecode(statusFile.readAsStringSync()) as Map<String, Object?>;
    final checkedTotal = (json['checkedTotal'] as int?) ?? 0;
    final failureCount = (json['failureCount'] as int?) ?? 0;
    final passRate = (json['passRate'] as num?)?.toDouble() ?? 0.0;
    final unsafe =
        json['liveServicesAllowed'] == true ||
        json['writesProductionCatalog'] == true ||
        json['firebaseWritesAllowed'] == true ||
        json['ocrCameraExpensesTouched'] == true;
    final underMinCheckedCells = (json['underMinCheckedCells'] as int?) ?? 0;
    final underMinPassRateCells = (json['underMinPassRateCells'] as int?) ?? 0;
    final readyToMerge =
        checkedTotal >= expectedChecked &&
        failureCount == 0 &&
        passRate >= minPassRate &&
        underMinCheckedCells == 0 &&
        underMinPassRateCells == 0 &&
        !unsafe;

    if (readyToMerge) {
      readyTradeCount += 1;
    } else {
      blockingFindings.add('rollup_not_merge_ready:$trade');
      nextActions.add(
        'Keep expanding or repairing the $trade Mac measurement wave until checkedTotal reaches $expectedChecked with passRate >= ${minPassRate.toStringAsFixed(2)} and zero unsafe flags.',
      );
    }

    tradeStatuses.add({
      'trade': trade,
      'statusPath': statusPath,
      'status': readyToMerge ? 'ready' : 'needs_work',
      'expectedChecked': expectedChecked,
      'checkedTotal': checkedTotal,
      'failureCount': failureCount,
      'passRate': passRate,
      'underMinCheckedCells': underMinCheckedCells,
      'underMinPassRateCells': underMinPassRateCells,
      'localOnlySafe': !unsafe,
      'readyToMerge': readyToMerge,
    });
  }

  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_peh_core_mac_wave_status',
    'macWavePath': macWavePath,
    'measurementCommandCount': measurementCommands.length,
    'rollupCommandCount': rollupCommands.length,
    'completedRollupCount': completedRollupCount,
    'missingRollupCount': missingRollupCount,
    'readyTradeCount': readyTradeCount,
    'readyToMergeIntoClaim':
        rollupCommands.isNotEmpty && readyTradeCount == rollupCommands.length,
    'tradeStatuses': tradeStatuses,
    'blockingFindings': blockingFindings,
    'nextActions': nextActions,
    'generatedAtIso': DateTime.now().toUtc().toIso8601String(),
  };

  final outputFile = File(output)..parent.createSync(recursive: true);
  outputFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(summary),
    flush: true,
  );
  stdout.writeln(
    'QA_PEH_CORE_MAC_WAVE_STATUS '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln('QA_PEH_CORE_MAC_WAVE_STATUS_ARTIFACT json=${outputFile.path}');
  return summary['readyToMergeIntoClaim'] == true ? 0 : 1;
}

String? _outputPath(List<String> command) {
  for (var index = 0; index < command.length; index++) {
    final part = command[index];
    if (part == '--output' && index + 1 < command.length) {
      return command[index + 1];
    }
    if (part.startsWith('--output=')) {
      return part.substring('--output='.length);
    }
  }
  return null;
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
