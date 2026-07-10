import 'dart:convert';
import 'dart:io';

class ParserQaDurationReportOptions {
  const ParserQaDurationReportOptions({
    required this.summaryPath,
    required this.outputPath,
    required this.reportName,
  });

  final String summaryPath;
  final String outputPath;
  final String reportName;
}

Map<String, Object?> buildParserQaDurationReport(
  ParserQaDurationReportOptions options,
) {
  final summaryFile = File(options.summaryPath);
  if (!summaryFile.existsSync()) {
    throw FileSystemException('Summary not found', options.summaryPath);
  }
  final summary = jsonDecode(summaryFile.readAsStringSync()) as Map;
  final rows = [
    for (final result in summary['results'] as List? ?? const [])
      {
        'cellId': (result as Map)['cellId'],
        'trade': result['trade'],
        'tier': result['tier'],
        'localePackId': result['localePackId'],
        'durationMs': int.tryParse(result['durationMs'].toString()) ?? 0,
        'exitCode': result['exitCode'],
      },
  ]..sort((a, b) => (b['durationMs'] as int).compareTo(a['durationMs'] as int));
  final totalMs = rows.fold<int>(
    0,
    (sum, row) => sum + (row['durationMs'] as int),
  );
  final report = <String, Object?>{
    'schemaVersion': 1,
    'report': options.reportName,
    'summaryPath': options.summaryPath,
    'cellCount': rows.length,
    'totalDurationMs': totalMs,
    'averageDurationMs': rows.isEmpty ? 0 : totalMs ~/ rows.length,
    'slowestCells': rows.take(10).toList(growable: false),
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
  };
  File(options.outputPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  return report;
}
