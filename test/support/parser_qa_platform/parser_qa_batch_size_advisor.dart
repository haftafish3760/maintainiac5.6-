import 'dart:convert';
import 'dart:io';

class ParserQaBatchSizeAdvisorOptions {
  const ParserQaBatchSizeAdvisorOptions({
    required this.durationReportPath,
    required this.outputPath,
    required this.reportName,
    required this.currentLimit,
    required this.targetCellMs,
    required this.minCompletedCells,
  });

  final String durationReportPath;
  final String outputPath;
  final String reportName;
  final int currentLimit;
  final int targetCellMs;
  final int minCompletedCells;
}

Map<String, Object?> buildParserQaBatchSizeAdvice(
  ParserQaBatchSizeAdvisorOptions options,
) {
  final reportFile = File(options.durationReportPath);
  if (!reportFile.existsSync()) {
    throw FileSystemException(
      'Duration report not found',
      options.durationReportPath,
    );
  }
  final report = jsonDecode(reportFile.readAsStringSync()) as Map;
  final completedCellCount = int.tryParse('${report['cellCount'] ?? 0}') ?? 0;
  final averageDurationMs =
      int.tryParse(report['averageDurationMs'].toString()) ?? 0;
  final slowestCells = [
    for (final cell in report['slowestCells'] as List? ?? const [])
      Map<String, Object?>.from(cell as Map),
  ];
  final slowestMs = slowestCells.isEmpty
      ? 0
      : int.tryParse(slowestCells.first['durationMs'].toString()) ?? 0;
  final recommended = _recommendLimit(
    currentLimit: options.currentLimit,
    completedCellCount: completedCellCount,
    minCompletedCells: options.minCompletedCells,
    averageDurationMs: averageDurationMs,
    slowestDurationMs: slowestMs,
    targetCellMs: options.targetCellMs,
  );
  final advice = <String, Object?>{
    'schemaVersion': 1,
    'report': options.reportName,
    'durationReportPath': options.durationReportPath,
    'currentFixtureRunLimit': options.currentLimit,
    'completedCellCount': completedCellCount,
    'minCompletedCells': options.minCompletedCells,
    'targetCellMs': options.targetCellMs,
    'averageDurationMs': averageDurationMs,
    'slowestDurationMs': slowestMs,
    'recommendedFixtureRunLimit': recommended,
    'recommendation': _recommendationLabel(options.currentLimit, recommended),
    'reason': _reason(
      completedCellCount: completedCellCount,
      minCompletedCells: options.minCompletedCells,
      averageDurationMs: averageDurationMs,
      slowestDurationMs: slowestMs,
      targetCellMs: options.targetCellMs,
    ),
    'slowestCells': slowestCells.take(5).toList(growable: false),
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
  };
  File(options.outputPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(advice));
  return advice;
}

int _recommendLimit({
  required int currentLimit,
  required int completedCellCount,
  required int minCompletedCells,
  required int averageDurationMs,
  required int slowestDurationMs,
  required int targetCellMs,
}) {
  if (completedCellCount < minCompletedCells) return currentLimit;
  if (averageDurationMs == 0) return currentLimit;
  final conservativeMs = slowestDurationMs > 0
      ? slowestDurationMs
      : averageDurationMs;
  final ratio = targetCellMs / conservativeMs;
  final raw = (currentLimit * ratio).floor();
  final bounded = raw.clamp(10, currentLimit * 4);
  return bounded < currentLimit ~/ 2 ? currentLimit ~/ 2 : bounded;
}

String _recommendationLabel(int currentLimit, int recommended) {
  if (recommended > currentLimit) return 'increase';
  if (recommended < currentLimit) return 'decrease';
  return 'hold';
}

String _reason({
  required int completedCellCount,
  required int minCompletedCells,
  required int averageDurationMs,
  required int slowestDurationMs,
  required int targetCellMs,
}) {
  if (completedCellCount < minCompletedCells) {
    return 'Hold until at least $minCompletedCells completed cells exist.';
  }
  if (averageDurationMs == 0) return 'No completed cell duration evidence yet.';
  if (slowestDurationMs > targetCellMs) {
    return 'Slowest completed cell is above the target budget; avoid increasing yet.';
  }
  if (averageDurationMs < targetCellMs ~/ 2) {
    return 'Average completed cell is comfortably below target; a larger fixture batch is reasonable.';
  }
  return 'Completed cell runtime is near target; hold or increase cautiously.';
}
