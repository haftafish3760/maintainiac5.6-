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
    final category = _suggestedFixCategory(text);
    final routing = _surgicalRerunRoute(row, text, category);
    failures.add({
      'cellId': row['cellId'],
      'trade': row['trade'],
      'marketScope': row['marketScope'],
      'tier': row['tier'],
      'localePackId': row['localePackId'],
      'exitCode': exitCode,
      'transcriptPath': row['transcriptPath'],
      'failurePreview': _failurePreview(text),
      'suggestedFixCategory': category,
      'surgicalRerun': routing,
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

Map<String, Object?> _surgicalRerunRoute(
  Map row,
  String text,
  String category,
) {
  final fixturePath = _extractFixturePath(text);
  final fixtureIds = _extractFixtureIds(text);
  final cellId = row['cellId']?.toString() ?? '';
  final family = _familyHint(text, cellId);
  final command = _generatedFixtureCommand(
    fixturePath: fixturePath,
    fixtureIds: fixtureIds,
  );
  return {
    'strategy': fixturePath.isEmpty
        ? 'inspect_transcript_before_broad_rerun'
        : fixtureIds.isEmpty
        ? 'rerun_failed_generated_fixture_cell'
        : 'rerun_failed_generated_fixture_ids',
    'category': category,
    'familyHint': family,
    'cellId': cellId,
    if (fixturePath.isNotEmpty) 'fixturePath': fixturePath,
    if (fixtureIds.isNotEmpty) 'fixtureIds': fixtureIds,
    if (command.isNotEmpty) 'command': command,
    'avoidBroadRerun': true,
  };
}

String _extractFixturePath(String text) {
  final patterns = [
    RegExp(r'PARSER_QA_GENERATED_FIXTURE_PATH=([^\s]+)'),
    RegExp(r'path=([^\s]+generated_fixtures\.json)'),
    RegExp(r'fixture=([^\s]+generated_fixtures\.json)'),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) return match.group(1) ?? '';
  }
  return '';
}

List<String> _extractFixtureIds(String text) {
  final ids = <String>{};
  final patterns = [
    RegExp(
      r'^([a-z]+_residential_[a-z]+_[a-z]{2}_[A-Z]{2}_[a-z0-9_]+_\d+):',
      multiLine: true,
    ),
    RegExp(r'PARSER_QA_GENERATED_FIXTURE_IDS=([a-zA-Z0-9_,\-]+)'),
  ];
  for (final match in patterns.first.allMatches(text)) {
    final id = match.group(1);
    if (id != null) ids.add(id);
  }
  for (final match in patterns.last.allMatches(text)) {
    final csv = match.group(1) ?? '';
    ids.addAll(
      csv
          .split(',')
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty),
    );
  }
  return ids.toList()..sort();
}

String _familyHint(String text, String cellId) {
  final lower = '$text\n$cellId'.toLowerCase();
  const hints = {
    'pvc': 'pvc_cross_trade',
    'conduit': 'electrical_conduit',
    'condensate': 'hvac_condensate_drain',
    'pex': 'plumbing_pex',
    'valve': 'plumbing_valves_supply',
    'filter': 'hvac_filters_airflow',
    'wire': 'electrical_wire_cable',
    'box': 'electrical_boxes_devices',
    'breaker': 'electrical_breakers_panels',
    'tape': 'hvac_tape_duct_fasteners',
    'fastener': 'trade_fasteners_supports',
  };
  for (final entry in hints.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return 'unknown_family';
}

String _generatedFixtureCommand({
  required String fixturePath,
  required List<String> fixtureIds,
}) {
  if (fixturePath.isEmpty) return '';
  final parts = [
    'dart run tool/work_supply_parser_qa_run_generated_fixtures.dart',
    '--fixture',
    fixturePath,
    '--max-cases',
    fixtureIds.isEmpty ? '25' : fixtureIds.length.toString(),
    if (fixtureIds.isNotEmpty) ...['--fixture-ids', fixtureIds.join(',')],
  ];
  return parts.join(' ');
}
