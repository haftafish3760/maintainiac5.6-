import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_background_queue_status.dart '
    '[--root build/parser_qa_background_queue] [--queue-id pass160-live]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaBackgroundQueueStatus(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaBackgroundQueueStatus(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final root = _value(args, 'root', 'build/parser_qa_background_queue');
  final queueId = _value(args, 'queue-id', '');
  final statusFile = File(
    queueId.isEmpty
        ? '$root/latest_status.json'
        : '$root/$queueId/latest_status.json',
  );
  final summaryFile = File(
    queueId.isEmpty
        ? '$root/latest_summary.json'
        : '$root/$queueId/summary.json',
  );
  final source = statusFile.existsSync()
      ? statusFile
      : summaryFile.existsSync()
      ? summaryFile
      : null;
  if (source == null) {
    stderr.writeln('No background queue status found under $root.');
    return 66;
  }
  final json = jsonDecode(source.readAsStringSync()) as Map;
  final results = (json['results'] as List? ?? const []);
  final failed = json['failedCellCount'] ?? _failedCount(results);
  final completed = json['completedCellCount'] ?? results.length;
  final total = json['cellCount'] ?? results.length;
  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_background_queue_status_readout',
    'sourcePath': source.path,
    'queueId': json['queueId'] ?? queueId,
    'state': json['state'] ?? (failed == 0 ? 'complete' : 'failed'),
    'completedCellCount': completed,
    'cellCount': total,
    'failedCellCount': failed,
    if (json['activeCellId'] != null) 'activeCellId': json['activeCellId'],
    'dryRun': json['dryRun'] ?? false,
    'liveServicesAllowed': json['liveServicesAllowed'] ?? false,
    'writesProductionCatalog': json['writesProductionCatalog'] ?? false,
    'firebaseWritesAllowed': json['firebaseWritesAllowed'] ?? false,
    'ocrCameraExpensesTouched': json['ocrCameraExpensesTouched'] ?? false,
  };
  stdout.writeln(
    'QA_BACKGROUND_QUEUE_STATUS '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  return failed == 0 ? 0 : 1;
}

int _failedCount(List<Object?> results) {
  return results
      .where(
        (result) => result is Map && (result['exitCode'] as int? ?? 1) != 0,
      )
      .length;
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
