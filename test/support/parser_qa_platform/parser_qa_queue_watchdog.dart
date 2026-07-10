import 'dart:convert';
import 'dart:io';

class ParserQaQueueWatchdogOptions {
  const ParserQaQueueWatchdogOptions({
    required this.statusPath,
    required this.outputPath,
    required this.reportName,
    required this.maxStatusAgeMs,
    required this.maxActiveCellMs,
  });

  final String statusPath;
  final String outputPath;
  final String reportName;
  final int maxStatusAgeMs;
  final int maxActiveCellMs;
}

Map<String, Object?> buildParserQaQueueWatchdog(
  ParserQaQueueWatchdogOptions options,
) {
  final statusFile = File(options.statusPath);
  if (!statusFile.existsSync()) {
    throw FileSystemException('Status not found', options.statusPath);
  }
  final status = jsonDecode(statusFile.readAsStringSync()) as Map;
  final findings = <String>[];
  final updatedAt = DateTime.tryParse('${status['updatedAtIso']}');
  final now = DateTime.now().toUtc();
  final statusAgeMs = updatedAt == null
      ? null
      : now.difference(updatedAt.toUtc()).inMilliseconds;
  final activeCellStartedAt = DateTime.tryParse(
    '${status['activeCellStartedAtIso'] ?? ''}',
  );
  final storedActiveCellElapsedMs =
      int.tryParse('${status['activeCellElapsedMs'] ?? 0}') ?? 0;
  final activeCellElapsedMs = storedActiveCellElapsedMs > 0
      ? storedActiveCellElapsedMs
      : activeCellStartedAt == null
      ? 0
      : now.difference(activeCellStartedAt.toUtc()).inMilliseconds;
  final failedCellCount =
      int.tryParse('${status['failedCellCount'] ?? 0}') ?? 0;
  if (updatedAt == null) findings.add('missing_updated_at');
  if (statusAgeMs != null && statusAgeMs > options.maxStatusAgeMs) {
    findings.add('status_stale');
  }
  if (activeCellElapsedMs > options.maxActiveCellMs) {
    findings.add('active_cell_stale');
  }
  if (failedCellCount > 0) findings.add('failed_cells_present');
  for (final flag in [
    'liveServicesAllowed',
    'writesProductionCatalog',
    'firebaseWritesAllowed',
    'ocrCameraExpensesTouched',
  ]) {
    if (status[flag] == true) findings.add('unsafe_$flag');
  }
  final report = <String, Object?>{
    'schemaVersion': 1,
    'report': options.reportName,
    'statusPath': options.statusPath,
    'queueState': '${status['state'] ?? 'unknown'}',
    'statusAgeMs': statusAgeMs,
    'activeCellId': status['activeCellId'],
    'activeCellStartedAtIso': status['activeCellStartedAtIso'],
    'activeCellElapsedMs': activeCellElapsedMs,
    'completedCellCount': status['completedCellCount'] ?? 0,
    'failedCellCount': failedCellCount,
    'findings': findings,
    'healthy': findings.isEmpty,
    'liveServicesAllowed': status['liveServicesAllowed'] == true,
    'writesProductionCatalog': status['writesProductionCatalog'] == true,
    'firebaseWritesAllowed': status['firebaseWritesAllowed'] == true,
    'ocrCameraExpensesTouched': status['ocrCameraExpensesTouched'] == true,
  };
  File(options.outputPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  return report;
}
