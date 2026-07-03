import 'dart:convert';
import 'dart:io';

class ParserQaFailureDigestOptions {
  const ParserQaFailureDigestOptions({
    required this.summaryPath,
    required this.outputPath,
    required this.reportName,
  });

  final String summaryPath;
  final String outputPath;
  final String reportName;
}

Map<String, Object?> buildParserQaFailureDigest(
  ParserQaFailureDigestOptions options,
) {
  final summaryFile = File(options.summaryPath);
  if (!summaryFile.existsSync()) {
    throw FileSystemException('Summary not found', options.summaryPath);
  }
  final summary = jsonDecode(summaryFile.readAsStringSync()) as Map;
  final failures = <Map<String, Object?>>[];
  for (final result in summary['results'] as List? ?? const []) {
    final row = result as Map;
    final exitCode = int.tryParse(row['exitCode'].toString()) ?? 0;
    if (exitCode == 0) continue;
    final transcript = File(row['transcriptPath'].toString());
    final text = transcript.existsSync() ? transcript.readAsStringSync() : '';
    failures.add({
      'cellId': row['cellId'],
      'trade': row['trade'],
      'marketScope': row['marketScope'],
      'tier': row['tier'],
      'localePackId': row['localePackId'],
      'exitCode': exitCode,
      'transcriptPath': row['transcriptPath'],
      'failurePreview': _failurePreview(text),
      'suggestedFixCategory': _suggestedFixCategory(text),
    });
  }
  final digest = <String, Object?>{
    'schemaVersion': 1,
    'report': options.reportName,
    'summaryPath': options.summaryPath,
    'failedCellCount': failures.length,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'failures': failures,
  };
  File(options.outputPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(digest));
  return digest;
}

List<String> _failurePreview(String text) {
  final lines = text
      .split('\n')
      .map((line) => line.trim())
      .where(
        (line) =>
            line.contains('Expected:') ||
            line.contains('Actual:') ||
            line.contains('Which:') ||
            line.contains('QA_FAILURE') ||
            line.contains('Some tests failed') ||
            line.contains('Exception') ||
            line.contains('Error:'),
      )
      .take(20)
      .toList(growable: false);
  if (lines.isNotEmpty) return lines;
  return text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .take(20)
      .toList(growable: false);
}

String _suggestedFixCategory(String text) {
  final lower = text.toLowerCase();
  if (lower.contains('expected:') && lower.contains('actual: null')) {
    return 'missing_match_or_alias';
  }
  if (lower.contains('expected:') && lower.contains('actual:')) {
    return 'wrong_match_or_expectation';
  }
  if (lower.contains('timeout') || lower.contains('duration')) {
    return 'performance_or_timeout';
  }
  if (lower.contains('exception') || lower.contains('error:')) {
    return 'runtime_error';
  }
  return 'needs_triage';
}
