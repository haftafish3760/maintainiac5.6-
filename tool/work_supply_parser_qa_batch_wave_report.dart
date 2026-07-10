import 'dart:convert';
import 'dart:io';

import 'work_supply_parser_qa_batch_wave_status.dart';

const _usage =
    'dart run tool/work_supply_parser_qa_batch_wave_report.dart '
    '[--root build/parser_qa_batch_waves] '
    '[--wave-ids pass198-core,pass201-standard] '
    '[--output build/parser_qa_batch_waves/latest_batch_wave_report.json] '
    '[--require-complete]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaBatchWaveReport(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaBatchWaveReport(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final root = _value(args, 'root', 'build/parser_qa_batch_waves');
  final waveIds = _csv(_value(args, 'wave-ids', ''));
  final requireComplete = args.contains('--require-complete');
  final output = _value(args, 'output', '$root/latest_batch_wave_report.json');
  if (waveIds.isEmpty) {
    stderr.writeln('--wave-ids is required.');
    return 64;
  }

  final waves = <Map<String, Object?>>[];
  var failed = false;
  for (final waveId in waveIds) {
    final sink = _MemorySink();
    final exit = runWorkSupplyParserQaBatchWaveStatus(
      ['--root', root, '--wave-id', waveId],
      stdout: sink,
      stderr: _MemorySink(),
    );
    final status = _extractStatus(sink.content);
    waves.add({...status, 'statusExitCode': exit});
    if (exit != 0) failed = true;
  }

  final totalCells = _sum(waves, 'cellCount');
  final completedCells = _sum(waves, 'completedCellCount');
  final failedCells = _sum(waves, 'failedCellCount');
  final remainingCells = totalCells - completedCells;
  final completionPercent = totalCells == 0
      ? 0
      : ((completedCells / totalCells) * 100).round();
  final unsafe = waves.any(
    (wave) =>
        wave['liveServicesAllowed'] == true ||
        wave['writesProductionCatalog'] == true ||
        wave['firebaseWritesAllowed'] == true ||
        wave['ocrCameraExpensesTouched'] == true,
  );
  final report = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_batch_wave_report',
    'root': root,
    'waveCount': waves.length,
    'totalCellCount': totalCells,
    'completedCellCount': completedCells,
    'failedCellCount': failedCells,
    'remainingCellCount': remainingCells,
    'completionPercent': completionPercent,
    'allComplete': completedCells == totalCells && failedCells == 0,
    'requireComplete': requireComplete,
    'unsafe': unsafe,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
    'waves': waves,
  };
  final json = const JsonEncoder.withIndent('  ').convert(report);
  File(output)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(json, flush: true);
  stdout.writeln('QA_BATCH_WAVE_REPORT $json');
  stdout.writeln('QA_BATCH_WAVE_REPORT_ARTIFACT json=$output');
  final incomplete = requireComplete && completedCells != totalCells;
  return failed || unsafe || failedCells > 0 || incomplete ? 1 : 0;
}

Map<String, Object?> _extractStatus(String text) {
  const marker = 'QA_BATCH_WAVE_STATUS ';
  final index = text.indexOf(marker);
  if (index < 0) return const {};
  final json = text.substring(index + marker.length).trim();
  return (jsonDecode(json) as Map).cast();
}

int _sum(List<Map<String, Object?>> waves, String key) {
  return waves.fold<int>(
    0,
    (sum, wave) => sum + (int.tryParse(wave[key].toString()) ?? 0),
  );
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}

List<String> _csv(String value) {
  return value
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
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
