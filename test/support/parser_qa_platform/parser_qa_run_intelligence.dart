import 'dart:convert';
import 'dart:io';

class ParserQaRunIntelligenceOptions {
  const ParserQaRunIntelligenceOptions({
    required this.root,
    required this.waveId,
    required this.output,
    required this.reportName,
    required this.consolePrefix,
    required this.artifactPrefix,
  });

  final String root;
  final String waveId;
  final String output;
  final String reportName;
  final String consolePrefix;
  final String artifactPrefix;
}

class ParserQaRunIntelligenceResult {
  const ParserQaRunIntelligenceResult({
    required this.exitCode,
    required this.report,
    required this.outputPath,
    required this.textOutputPath,
  });

  final int exitCode;
  final Map<String, Object?> report;
  final String outputPath;
  final String textOutputPath;
}

ParserQaRunIntelligenceResult buildParserQaRunIntelligenceReport(
  ParserQaRunIntelligenceOptions options,
) {
  final waveDir = Directory('${options.root}/${options.waveId}');
  if (!waveDir.existsSync()) {
    throw FileSystemException('Wave directory not found', waveDir.path);
  }
  final wave = _readWave(waveDir);
  if (wave == null) {
    throw FileSystemException(
      'No wave_summary.json or wave_plan.json found',
      waveDir.path,
    );
  }
  final queue = _readQueue(waveDir, wave);
  final duration = _readOptionalMap('${waveDir.path}/duration_report.json');
  final advice = _readOptionalMap('${waveDir.path}/batch_size_advice.json');
  final watchdog = _readOptionalMap('${waveDir.path}/queue_watchdog.json');
  final failureDigest = _readOptionalMap('${waveDir.path}/failure_digest.json');

  final cellCount = _int(queue['cellCount']);
  final completed = _int(queue['completedCellCount']);
  final failed = _int(queue['failedCellCount']);
  final remaining = cellCount > completed ? cellCount - completed : 0;
  final unsafe =
      _bool(wave['liveServicesAllowed']) ||
      _bool(wave['writesProductionCatalog']) ||
      _bool(wave['firebaseWritesAllowed']) ||
      _bool(wave['ocrCameraExpensesTouched']) ||
      _bool(queue['liveServicesAllowed']) ||
      _bool(queue['writesProductionCatalog']);

  final report = <String, Object?>{
    'schemaVersion': 1,
    'report': options.reportName,
    'waveId': options.waveId,
    'qaLayer': wave['qaLayer'],
    'queueState': queue['state'] ?? _queueState(queue),
    'cellCount': cellCount,
    'completedCellCount': completed,
    'failedCellCount': failed,
    'remainingCellCount': remaining,
    if (queue['activeCellId'] != null) 'activeCellId': queue['activeCellId'],
    'progressPercent': cellCount == 0 ? 0 : (completed * 100 / cellCount),
    'averageDurationMs': duration['averageDurationMs'] ?? 0,
    'slowestDurationMs': _slowestMs(duration),
    'recommendedFixtureRunLimit': advice['recommendedFixtureRunLimit'],
    'advisorRecommendation': advice['recommendation'],
    'watchdogHealthy': watchdog['healthy'],
    'watchdogFindings': watchdog['findings'] ?? const [],
    'failureDigestFailedCellCount': failureDigest['failedCellCount'] ?? failed,
    'unsafe': unsafe,
    'liveServicesAllowed':
        _bool(wave['liveServicesAllowed']) ||
        _bool(queue['liveServicesAllowed']),
    'writesProductionCatalog':
        _bool(wave['writesProductionCatalog']) ||
        _bool(queue['writesProductionCatalog']),
    'firebaseWritesAllowed': _bool(wave['firebaseWritesAllowed']),
    'ocrCameraExpensesTouched': _bool(wave['ocrCameraExpensesTouched']),
    'nextActions': _nextActions(
      unsafe: unsafe,
      failed: failed,
      remaining: remaining,
      hasDuration: duration.isNotEmpty,
      hasAdvice: advice.isNotEmpty,
    ),
  };

  final textOutput = options.output.endsWith('run_intelligence_report.json')
      ? options.output.replaceFirst(
          'run_intelligence_report.json',
          'run_intelligence_report.txt',
        )
      : options.output.replaceFirst(RegExp(r'\.json$'), '.txt');
  File(options.output)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  File(textOutput).writeAsStringSync(_summary(report));
  return ParserQaRunIntelligenceResult(
    exitCode: unsafe || failed > 0 ? 1 : 0,
    report: report,
    outputPath: options.output,
    textOutputPath: textOutput,
  );
}

List<String> _nextActions({
  required bool unsafe,
  required int failed,
  required int remaining,
  required bool hasDuration,
  required bool hasAdvice,
}) {
  return [
    if (unsafe) 'Stop: unsafe live-service/write/OCR flag is present.',
    if (failed > 0) 'Stop: generate or inspect failure_digest.json.',
    if (!unsafe && failed == 0 && remaining > 0)
      'Continue queue; do not launch another heavy wave on top of it.',
    if (!unsafe && failed == 0 && remaining == 0)
      'Finalize duration, transcript audit, aggregate report, and evidence index.',
    if (!hasDuration) 'Generate duration_report.json for runtime evidence.',
    if (!hasAdvice) 'Generate batch_size_advice.json before next wave.',
  ];
}

Map<String, Object?>? _readWave(Directory waveDir) {
  for (final name in ['wave_summary.json', 'wave_plan.json']) {
    final file = File('${waveDir.path}/$name');
    if (file.existsSync()) {
      return (jsonDecode(file.readAsStringSync()) as Map).cast();
    }
  }
  return null;
}

Map<String, Object?> _readQueue(Directory waveDir, Map<String, Object?> wave) {
  final summaryPath = wave['queueSummaryPath']?.toString() ?? '';
  final paths = <String>[
    if (summaryPath.isNotEmpty)
      '${File(summaryPath).parent.path}/latest_status.json',
    if (summaryPath.isNotEmpty) summaryPath,
    '${waveDir.path}/queue/latest_status.json',
  ];
  for (final path in paths) {
    final file = File(path);
    if (file.existsSync()) {
      return (jsonDecode(file.readAsStringSync()) as Map).cast();
    }
  }
  return const {};
}

Map<String, Object?> _readOptionalMap(String path) {
  final file = File(path);
  if (!file.existsSync()) return const {};
  return (jsonDecode(file.readAsStringSync()) as Map).cast();
}

String _queueState(Map<String, Object?> queue) {
  if (_int(queue['failedCellCount']) > 0) return 'failed';
  if (_int(queue['cellCount']) > 0 &&
      _int(queue['completedCellCount']) == _int(queue['cellCount'])) {
    return 'complete';
  }
  return 'running';
}

int _slowestMs(Map<String, Object?> duration) {
  final cells = duration['slowestCells'];
  if (cells is! List || cells.isEmpty) return 0;
  return _int((cells.first as Map)['durationMs']);
}

String _summary(Map<String, Object?> report) {
  final lines = [
    'QA run intelligence: ${report['waveId']}',
    'State: ${report['queueState']} ${report['completedCellCount']}/${report['cellCount']} cells, failures=${report['failedCellCount']}',
    'Active: ${report['activeCellId'] ?? 'none'}',
    'Safety: unsafe=${report['unsafe']} live=${report['liveServicesAllowed']} writes=${report['writesProductionCatalog']} firebase=${report['firebaseWritesAllowed']} ocr=${report['ocrCameraExpensesTouched']}',
    'Timing: avg=${report['averageDurationMs']}ms slowest=${report['slowestDurationMs']}ms',
    'Advisor: ${report['advisorRecommendation'] ?? 'none'} nextLimit=${report['recommendedFixtureRunLimit'] ?? 'none'}',
    'Next actions:',
    for (final action in report['nextActions'] as List) '- $action',
  ];
  return '${lines.join('\n')}\n';
}

bool _bool(Object? value) => value == true || value.toString() == 'true';

int _int(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;
