import 'dart:convert';
import 'dart:io';

class ParserQaReleaseReadinessOptions {
  const ParserQaReleaseReadinessOptions({
    required this.waveReportPath,
    required this.pipelineStatusPath,
    required this.outputPath,
    required this.reportName,
    this.fixtureReadinessPath = '',
  });

  final String waveReportPath;
  final String pipelineStatusPath;
  final String outputPath;
  final String reportName;
  final String fixtureReadinessPath;
}

Map<String, Object?> buildParserQaReleaseReadiness(
  ParserQaReleaseReadinessOptions options,
) {
  final waveFile = File(options.waveReportPath);
  final statusFile = File(options.pipelineStatusPath);
  if (!waveFile.existsSync()) {
    throw FileSystemException('Wave report not found', options.waveReportPath);
  }
  if (!statusFile.existsSync()) {
    throw FileSystemException(
      'Pipeline status not found',
      options.pipelineStatusPath,
    );
  }
  final wave = jsonDecode(waveFile.readAsStringSync()) as Map;
  final pipeline = jsonDecode(statusFile.readAsStringSync()) as Map;
  final fixtureReadiness = _readOptionalMap(options.fixtureReadinessPath);
  final waveCells = _intValue(wave['totalCellCount']);
  final waveCompleted = _intValue(wave['completedCellCount']);
  final waveFailed = _intValue(wave['failedCellCount']);
  final pipelineExpected = _intValue(pipeline['expectedCells']);
  final pipelinePresent = _intValue(pipeline['presentCells']);
  final pipelineMissing = _intValue(pipeline['missingCells']);
  final fixtureTotal = _intValue(fixtureReadiness['totalCells']);
  final fixtureGenerated = _intValue(fixtureReadiness['generatedFixtureCount']);
  final fixtureMissing = _intValue(fixtureReadiness['missingFixtureCount']);
  final hasFixtureReadiness = options.fixtureReadinessPath.isNotEmpty;
  final unsafe =
      wave['unsafe'] == true ||
      pipeline['unsafeCells'].toString() != '0' ||
      (hasFixtureReadiness &&
          fixtureReadiness['unsafeFindings'].toString() != '[]') ||
      wave['liveServicesAllowed'] == true ||
      wave['writesProductionCatalog'] == true ||
      pipeline['liveServicesAllowed'] == true ||
      pipeline['writesProductionCatalog'] == true ||
      (hasFixtureReadiness &&
          (fixtureReadiness['liveServicesAllowed'] == true ||
              fixtureReadiness['writesProductionCatalog'] == true ||
              fixtureReadiness['firebaseWritesAllowed'] == true ||
              fixtureReadiness['ocrCameraExpensesTouched'] == true));
  final waveReady =
      waveCells > 0 && waveCompleted == waveCells && waveFailed == 0;
  final pipelineComplete =
      pipelineExpected > 0 && pipelinePresent == pipelineExpected;
  final fixtureReady =
      !hasFixtureReadiness ||
      (fixtureReadiness['readyForParserExecution'] == true &&
          fixtureTotal > 0 &&
          fixtureGenerated == fixtureTotal &&
          fixtureMissing == 0);
  final readiness = <String, Object?>{
    'schemaVersion': 1,
    'report': options.reportName,
    'waveReportPath': options.waveReportPath,
    'pipelineStatusPath': options.pipelineStatusPath,
    'waveReady': waveReady,
    'waveCellCount': waveCells,
    'waveCompletedCellCount': waveCompleted,
    'waveFailedCellCount': waveFailed,
    'pipelineComplete': pipelineComplete,
    'pipelineExpectedCells': pipelineExpected,
    'pipelinePresentCells': pipelinePresent,
    'pipelineMissingCells': pipelineMissing,
    if (options.fixtureReadinessPath.isNotEmpty)
      'fixtureReadinessPath': options.fixtureReadinessPath,
    'fixtureReadinessReady': fixtureReady,
    'fixtureTotalCells': fixtureTotal,
    'fixtureGeneratedCells': fixtureGenerated,
    'fixtureMissingCells': fixtureMissing,
    'unsafe': unsafe,
    'releaseOneParserEvidenceReady': waveReady && !unsafe,
    'releaseOnePipelineArtifactsReady': pipelineComplete && !unsafe,
    'releaseOneFixtureEvidenceReady': fixtureReady && !unsafe,
    'nextActions': [
      if (!waveReady) 'Finish or repair batch-wave parser evidence.',
      if (!fixtureReady)
        'Generate or repair fixture readiness rollup before parser execution claims.',
      if (pipelineMissing > 0)
        'Generate missing economical pipeline artifacts or document why batch-wave evidence is authoritative for this checkpoint.',
      if (unsafe) 'Stop: unsafe live-service/write flag is present.',
      if (waveReady && !pipelineComplete && !unsafe)
        'Parser evidence is ready; pipeline artifact root is incomplete.',
      if (waveReady && pipelineComplete && !unsafe)
        'Release-one parser evidence and pipeline artifacts are ready.',
    ],
  };
  File(options.outputPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(readiness));
  return readiness;
}

int _intValue(Object? value) => int.tryParse('$value') ?? 0;

Map<String, Object?> _readOptionalMap(String path) {
  if (path.isEmpty) return const {};
  final file = File(path);
  if (!file.existsSync()) return const {};
  final decoded = jsonDecode(file.readAsStringSync());
  return decoded is Map<String, Object?>
      ? decoded
      : decoded is Map
      ? decoded.cast<String, Object?>()
      : const {};
}
