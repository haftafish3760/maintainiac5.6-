import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_batch_wave_status.dart '
    '[--root build/parser_qa_batch_waves] [--wave-id pass197-core-wave]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaBatchWaveStatus(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaBatchWaveStatus(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final root = _value(args, 'root', 'build/parser_qa_batch_waves');
  final waveId = _value(args, 'wave-id', '');
  if (waveId.isEmpty) {
    stderr.writeln('--wave-id is required.');
    return 64;
  }
  final waveDir = Directory('$root/$waveId');
  if (!waveDir.existsSync()) {
    stderr.writeln('Batch wave directory not found: ${waveDir.path}');
    return 66;
  }
  final waveSummaryFile = File('${waveDir.path}/wave_summary.json');
  final wavePlanFile = File('${waveDir.path}/wave_plan.json');
  final waveSource = waveSummaryFile.existsSync()
      ? waveSummaryFile
      : wavePlanFile.existsSync()
      ? wavePlanFile
      : null;
  if (waveSource == null) {
    stderr.writeln('No wave_summary.json or wave_plan.json found.');
    return 66;
  }
  final wave = jsonDecode(waveSource.readAsStringSync()) as Map;
  final queueSummaryPath = wave['queueSummaryPath']?.toString() ?? '';
  final queueStatus = _readQueueStatus(root: root, wave: wave);
  final status = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_batch_wave_status',
    'waveId': waveId,
    'waveSourcePath': waveSource.path,
    'qaLayer': wave['qaLayer'],
    'accumulatedWaveIds': wave['accumulatedWaveIds'] ?? const [],
    'dryRun': wave['dryRun'] ?? true,
    'queueSummaryPath': queueSummaryPath,
    'queueState': queueStatus['state'] ?? _queueStateFromSummary(queueStatus),
    'cellCount': queueStatus['cellCount'] ?? 0,
    'completedCellCount': queueStatus['completedCellCount'] ?? 0,
    'failedCellCount': queueStatus['failedCellCount'] ?? 0,
    if (queueStatus['activeCellId'] != null)
      'activeCellId': queueStatus['activeCellId'],
    'liveServicesAllowed': _bool(wave['liveServicesAllowed']) ||
        _bool(queueStatus['liveServicesAllowed']),
    'writesProductionCatalog': _bool(wave['writesProductionCatalog']) ||
        _bool(queueStatus['writesProductionCatalog']),
    'firebaseWritesAllowed': _bool(wave['firebaseWritesAllowed']),
    'ocrCameraExpensesTouched': _bool(wave['ocrCameraExpensesTouched']),
  };
  stdout.writeln(
    'QA_BATCH_WAVE_STATUS ${const JsonEncoder.withIndent('  ').convert(status)}',
  );
  final unsafe = status['liveServicesAllowed'] == true ||
      status['writesProductionCatalog'] == true ||
      status['firebaseWritesAllowed'] == true ||
      status['ocrCameraExpensesTouched'] == true;
  if (unsafe || (status['failedCellCount'] as int) > 0) return 1;
  return 0;
}

Map<String, Object?> _readQueueStatus({
  required String root,
  required Map wave,
}) {
  final queueSummaryPath = wave['queueSummaryPath']?.toString() ?? '';
  if (queueSummaryPath.isNotEmpty) {
    final summary = File(queueSummaryPath);
    final status = File('${summary.parent.path}/latest_status.json');
    if (status.existsSync()) {
      return (jsonDecode(status.readAsStringSync()) as Map).cast();
    }
    if (summary.existsSync()) {
      return (jsonDecode(summary.readAsStringSync()) as Map).cast();
    }
  }
  final waveId = wave['waveId']?.toString() ?? '';
  final status = File('$root/$waveId/queue/latest_status.json');
  if (status.existsSync()) {
    return (jsonDecode(status.readAsStringSync()) as Map).cast();
  }
  return const {};
}

String _queueStateFromSummary(Map<String, Object?> queue) {
  final failed = queue['failedCellCount'] == null
      ? 0
      : int.tryParse(queue['failedCellCount'].toString()) ?? 0;
  final completed = queue['completedCellCount']?.toString();
  final total = queue['cellCount']?.toString();
  if (failed > 0) return 'failed';
  if (completed != null && completed == total) return 'complete';
  return 'unknown';
}

bool _bool(Object? value) => value == true || value.toString() == 'true';

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
