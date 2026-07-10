import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_report_digest.dart '
    '[--report build/parser_qa_reports/latest_work_supply_inventory_parser.json] '
    '[--output build/parser_qa_reports/latest_work_supply_inventory_parser_digest.json]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaReportDigest(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaReportDigest(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final reportPath = _value(
    args,
    'report',
    'build/parser_qa_reports/latest_work_supply_inventory_parser.json',
  );
  final reportFile = File(reportPath);
  if (!reportFile.existsSync()) {
    stderr.writeln('Report not found: $reportPath');
    return 66;
  }
  final outputPath = _value(
    args,
    'output',
    '${reportFile.parent.path}/latest_work_supply_inventory_parser_digest.json',
  );

  final report = jsonDecode(reportFile.readAsStringSync());
  if (report is! Map<String, Object?>) {
    stderr.writeln('Report JSON root must be an object.');
    return 65;
  }
  final digest = _buildDigest(report, reportPath);
  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(digest));
  stdout.writeln(
    'QA_REPORT_DIGEST ${const JsonEncoder.withIndent('  ').convert(digest)}',
  );
  stdout.writeln('QA_REPORT_DIGEST_ARTIFACT json=$outputPath');
  return 0;
}

Map<String, Object?> _buildDigest(
  Map<String, Object?> report,
  String reportPath,
) {
  final results = _objects(report['results']);
  final suites = <Map<String, Object?>>[];
  for (final result in results) {
    final metrics = _map(result['metrics']);
    suites.add({
      'name': result['name'],
      'checked': result['checked'],
      'actualFailureCount': result['actualFailureCount'],
      'durationMs': result['durationMs'],
      if (metrics.containsKey('scoreBuckets'))
        'scoreBuckets': metrics['scoreBuckets'],
      if (metrics.containsKey('warningsByPriorityScope'))
        'warningsByPriorityScope': metrics['warningsByPriorityScope'],
      if (metrics.containsKey('checkedByPriorityScope'))
        'checkedByPriorityScope': metrics['checkedByPriorityScope'],
      if (metrics.containsKey('warningsByTrade'))
        'warningsByTrade': metrics['warningsByTrade'],
      if (metrics.containsKey('warningsByTier'))
        'warningsByTier': metrics['warningsByTier'],
      if (metrics.containsKey('topMissingSignals'))
        'topMissingSignals': metrics['topMissingSignals'],
      if (metrics.containsKey('topRiskTerms'))
        'topRiskTerms': metrics['topRiskTerms'],
    });
  }
  return {
    'sourceReport': reportPath,
    'domain': report['domain'],
    'strict': report['strict'],
    'checked': report['checked'],
    'actualFailureCount': report['actualFailureCount'],
    'severityCounts': report['severityCounts'],
    'adminHealth': report['adminHealth'],
    'suites': suites,
  };
}

List<Map<String, Object?>> _objects(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map) item.cast<String, Object?>(),
  ];
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) return const {};
  return value.cast<String, Object?>();
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
