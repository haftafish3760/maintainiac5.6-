import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_peh_core_measurement_gap.dart '
    '[--windows-status build/parser_qa_pipeline/peh_core_windows_status_rollup.json] '
    '[--output build/parser_qa_pipeline/peh_core_measurement_gap.json]';
const _trackedTrades = ['plumbing', 'electrical', 'hvac'];

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaPehCoreMeasurementGap(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaPehCoreMeasurementGap(
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
  final output = _value(
    args,
    'output',
    'build/parser_qa_pipeline/peh_core_measurement_gap.json',
  );

  final file = File(windowsStatusPath);
  if (!file.existsSync()) {
    stderr.writeln('--windows-status must exist.');
    return 66;
  }

  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  final targetChecked =
      (json['targetChecked'] as Map?)?.cast<String, Object?>() ?? const {};
  final trades = (json['trades'] as List<dynamic>? ?? const <dynamic>[]);

  final tradeGapByName = <String, Map<String, Object?>>{};
  var totalRemainingChecked = 0;
  for (final entry in trades) {
    if (entry is! Map) continue;
    final trade = entry['trade']?.toString() ?? 'unknown';
    final checkedTotal = (entry['checkedTotal'] as int?) ?? 0;
    final target = (targetChecked[trade] as int?) ?? 0;
    final remaining = target > checkedTotal ? target - checkedTotal : 0;
    totalRemainingChecked += remaining;
    tradeGapByName[trade] = {
      'trade': trade,
      'checkedTotal': checkedTotal,
      'targetChecked': target,
      'remainingChecked': remaining,
      'sampleSizedEvidence': entry['sampleSizedEvidence'] == true,
      'readyToClaimNinetyPlus': entry['readyToClaimNinetyPlus'] == true,
    };
  }

  for (final trade in _trackedTrades) {
    tradeGapByName.putIfAbsent(
      trade,
      () => {
        'trade': trade,
        'checkedTotal': 0,
        'targetChecked': (targetChecked[trade] as int?) ?? 0,
        'remainingChecked': (targetChecked[trade] as int?) ?? 0,
        'sampleSizedEvidence': false,
        'readyToClaimNinetyPlus': false,
      },
    );
  }

  final tradeGaps = tradeGapByName.values.toList();

  tradeGaps.sort(
    (left, right) =>
        ((right['remainingChecked'] as int?) ?? 0).compareTo(
          (left['remainingChecked'] as int?) ?? 0,
        ),
  );

  final nextTrades = [
    for (final trade in tradeGaps)
      if ((trade['remainingChecked'] as int?) != 0) trade['trade'],
  ];

  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_peh_core_measurement_gap',
    'windowsStatusPath': windowsStatusPath,
    'readyToClaimNinetyPlus': json['readyToClaimNinetyPlus'] == true,
    'readyForMacMeasurementWave': json['readyForMacMeasurementWave'] == true,
    'tradeGapCount': tradeGaps.length,
    'totalRemainingChecked': totalRemainingChecked,
    'tradeGaps': tradeGaps,
    'nextTradesByRemainingGap': nextTrades,
    'generatedAtIso': DateTime.now().toUtc().toIso8601String(),
  };

  final outputFile = File(output)..parent.createSync(recursive: true);
  outputFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(summary),
    flush: true,
  );
  stdout.writeln(
    'QA_PEH_CORE_MEASUREMENT_GAP '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln('QA_PEH_CORE_MEASUREMENT_GAP_ARTIFACT json=${outputFile.path}');
  return totalRemainingChecked == 0 ? 0 : 1;
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
