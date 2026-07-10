import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_background_queue_status.dart '
    '[--root build/parser_qa_background_queue] [--queue-id pass160-live] '
    '[--max-active-cell-ms 900000] [--max-status-age-ms 900000]';

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
  DateTime? now,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final root = _value(args, 'root', 'build/parser_qa_background_queue');
  final queueId = _value(args, 'queue-id', '');
  final maxActiveCellMs =
      int.tryParse(_value(args, 'max-active-cell-ms', '0')) ?? 0;
  final maxStatusAgeMs =
      int.tryParse(_value(args, 'max-status-age-ms', '0')) ?? 0;
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
  final unsafeFailures = _unsafeFailures(json, results);
  final completed = json['completedCellCount'] ?? results.length;
  final total = json['cellCount'] ?? results.length;
  final activeCellStartedAtIso = json['activeCellStartedAtIso'] as String?;
  final activeCellElapsedMs = _activeCellElapsedMs(
    activeCellStartedAtIso,
    now ?? DateTime.now().toUtc(),
    json['activeCellElapsedMs'],
  );
  final statusAgeMs = _elapsedSinceIso(
    json['updatedAtIso'] as String?,
    now ?? DateTime.now().toUtc(),
  );
  final activeCellStale =
      maxActiveCellMs > 0 &&
      activeCellElapsedMs != null &&
      activeCellElapsedMs > maxActiveCellMs;
  final statusStale =
      maxStatusAgeMs > 0 && statusAgeMs != null && statusAgeMs > maxStatusAgeMs;
  final summary = <String, Object?>{
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
    'unsafeFlagCount': unsafeFailures.length,
    if (maxActiveCellMs > 0) 'maxActiveCellMs': maxActiveCellMs,
    if (maxActiveCellMs > 0) 'activeCellStale': activeCellStale,
    if (maxStatusAgeMs > 0) 'maxStatusAgeMs': maxStatusAgeMs,
    if (maxStatusAgeMs > 0) 'statusStale': statusStale,
    if (unsafeFailures.isNotEmpty) 'unsafeFlags': unsafeFailures,
  };
  if (json['updatedAtIso'] != null) {
    summary['updatedAtIso'] = json['updatedAtIso'];
  }
  if (statusAgeMs != null) {
    summary['statusAgeMs'] = statusAgeMs;
  }
  if (activeCellStartedAtIso != null) {
    summary['activeCellStartedAtIso'] = activeCellStartedAtIso;
  }
  if (activeCellElapsedMs != null) {
    summary['activeCellElapsedMs'] = activeCellElapsedMs;
  }
  stdout.writeln(
    'QA_BACKGROUND_QUEUE_STATUS '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  for (final failure in unsafeFailures) {
    stderr.writeln('Unsafe background queue evidence: $failure');
  }
  if (activeCellStale) {
    stderr.writeln(
      'Stale active background queue cell: '
      '${json['activeCellId'] ?? 'unknown_cell'} elapsed '
      '${activeCellElapsedMs}ms exceeds ${maxActiveCellMs}ms.',
    );
  }
  if (statusStale) {
    stderr.writeln(
      'Stale background queue status: updated ${statusAgeMs}ms ago exceeds '
      '${maxStatusAgeMs}ms.',
    );
  }
  return failed == 0 &&
          unsafeFailures.isEmpty &&
          !activeCellStale &&
          !statusStale
      ? 0
      : 1;
}

List<String> _unsafeFailures(Map json, List<Object?> results) {
  final failures = <String>[];
  for (final field in _safetyFields) {
    if (json[field] == true) failures.add('top_level:$field');
  }
  for (final result in results) {
    if (result is! Map) continue;
    final cellId = result['cellId']?.toString() ?? 'unknown_cell';
    for (final field in _safetyFields) {
      if (result[field] == true) failures.add('$cellId:$field');
    }
  }
  return failures;
}

const _safetyFields = {
  'liveServicesAllowed',
  'writesProductionCatalog',
  'firebaseWritesAllowed',
  'ocrCameraExpensesTouched',
};

int? _activeCellElapsedMs(
  String? activeCellStartedAtIso,
  DateTime now,
  Object? storedElapsedMs,
) {
  if (activeCellStartedAtIso == null || activeCellStartedAtIso.isEmpty) {
    return storedElapsedMs is int ? storedElapsedMs : null;
  }
  final startedAt = DateTime.tryParse(activeCellStartedAtIso);
  if (startedAt == null) return storedElapsedMs is int ? storedElapsedMs : null;
  final elapsedMs = now.toUtc().difference(startedAt.toUtc()).inMilliseconds;
  if (elapsedMs < 0) return 0;
  return elapsedMs;
}

int? _elapsedSinceIso(String? iso, DateTime now) {
  if (iso == null || iso.isEmpty) return null;
  final instant = DateTime.tryParse(iso);
  if (instant == null) return null;
  final elapsedMs = now.toUtc().difference(instant.toUtc()).inMilliseconds;
  if (elapsedMs < 0) return 0;
  return elapsedMs;
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
