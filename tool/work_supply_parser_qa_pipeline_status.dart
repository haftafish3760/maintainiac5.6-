import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_pipeline_status.dart '
    '[--output-root build/parser_qa_pipeline] '
    '[--trades plumbing] [--scopes residential] [--tiers core] '
    '[--locales en-US,es-US] [--report-dir build/parser_qa_pipeline/status_reports] '
    '[--require-complete]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaPipelineStatus(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaPipelineStatus(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final options = _StatusOptions.parse(args);
  final cells = <Map<String, Object?>>[];
  var missing = 0;
  var unsafe = 0;
  var parserCalls = 0;
  var parserEvidenceCells = 0;
  for (final trade in options.trades) {
    for (final scope in options.scopes) {
      for (final tier in options.tiers) {
        for (final locale in options.locales) {
          final cell = _readCell(options, trade, scope, tier, locale);
          cells.add(cell);
          if (cell['status'] == 'missing') missing++;
          if (cell['localOnlySafe'] == false) unsafe++;
          parserCalls += (cell['parserCalls'] as int?) ?? 0;
          if (cell['parserEvidenceReady'] == true) parserEvidenceCells++;
        }
      }
    }
  }
  final present = cells.length - missing;
  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_pipeline_status',
    'outputRoot': options.outputRoot,
    'expectedCells': cells.length,
    'presentCells': present,
    'missingCells': missing,
    'unsafeCells': unsafe,
    'parserCalls': parserCalls,
    'parserEvidenceCells': parserEvidenceCells,
    'missingParserEvidenceCells': present - parserEvidenceCells,
    'requireComplete': options.requireComplete,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'cells': cells,
  };
  final artifact = _writeStatusSummary(
    reportDir: options.reportDir,
    summary: summary,
  );
  stdout.writeln(
    'QA_ECONOMICAL_PIPELINE_STATUS '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln(
    'QA_ECONOMICAL_PIPELINE_STATUS_ARTIFACT '
    'json=${artifact.timestampedJsonPath} latestJson=${artifact.latestJsonPath}',
  );
  if (unsafe > 0) return 1;
  if (options.requireComplete && missing > 0) return 2;
  return 0;
}

_StatusArtifact _writeStatusSummary({
  required String reportDir,
  required Map<String, Object?> summary,
}) {
  final directory = Directory(reportDir)..createSync(recursive: true);
  final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
    RegExp(r'[:.]'),
    '',
  );
  final timestamped = File('${directory.path}/pipeline_status_$stamp.json');
  final latest = File('${directory.path}/latest_pipeline_status.json');
  final encoded = const JsonEncoder.withIndent('  ').convert({
    ...summary,
    'generatedAtIso': DateTime.now().toUtc().toIso8601String(),
  });
  timestamped.writeAsStringSync(encoded, flush: true);
  latest.writeAsStringSync(encoded, flush: true);
  return _StatusArtifact(
    timestampedJsonPath: timestamped.path,
    latestJsonPath: latest.path,
  );
}

Map<String, Object?> _readCell(
  _StatusOptions options,
  String trade,
  String scope,
  String tier,
  String locale,
) {
  final summaryPath = _summaryPathFor(options, trade, scope, tier, locale);
  final summaryFile = summaryPath == null ? null : File(summaryPath);
  final displaySummaryPath =
      summaryPath ??
      '${options.outputRoot}/$trade/$scope/$tier/$locale/pipeline_reports/'
          'latest_pipeline_summary.json';
  if (summaryFile == null || !summaryFile.existsSync()) {
    return _cell(
      trade: trade,
      scope: scope,
      tier: tier,
      locale: locale,
      status: 'missing',
      summaryPath: displaySummaryPath,
      localOnlySafe: true,
    );
  }
  final json = jsonDecode(summaryFile.readAsStringSync()) as Map;
  final matchesRequestedCell =
      json['trade'] == trade &&
      json['marketScope'] == scope &&
      json['tier'] == tier &&
      json['localePackId'] == locale;
  if (!matchesRequestedCell) {
    return _cell(
      trade: trade,
      scope: scope,
      tier: tier,
      locale: locale,
      status: 'missing',
      summaryPath: displaySummaryPath,
      localOnlySafe: true,
    );
  }
  final blueprintPath = json['blueprintPath'] as String?;
  final fixturePath = json['fixturePath'] as String?;
  final parserCalls = (json['parserCalls'] as int?) ?? 0;
  final localOnlySafe =
      json['liveServicesAllowed'] == false &&
      json['writesProductionCatalog'] == false;
  return _cell(
    trade: trade,
    scope: scope,
    tier: tier,
    locale: locale,
    status: 'present',
    summaryPath: displaySummaryPath,
    localOnlySafe: localOnlySafe,
    blueprintExists: blueprintPath != null && File(blueprintPath).existsSync(),
    fixtureExists: fixturePath != null && File(fixturePath).existsSync(),
    dryRun: json['dryRun'] == true,
    runFixtures: json['runFixtures'] == true,
    parserCalls: parserCalls,
    parserEvidenceReady: parserCalls > 0,
  );
}

String? _summaryPathFor(
  _StatusOptions options,
  String trade,
  String scope,
  String tier,
  String locale,
) {
  final candidates = [
    '${options.outputRoot}/$trade/$scope/$tier/$locale/pipeline_reports/'
        'latest_pipeline_summary.json',
    '${options.outputRoot}/$locale/pipeline_reports/latest_pipeline_summary.json',
  ];
  for (final candidate in candidates) {
    if (File(candidate).existsSync()) return candidate;
  }
  return null;
}

Map<String, Object?> _cell({
  required String trade,
  required String scope,
  required String tier,
  required String locale,
  required String status,
  required String summaryPath,
  required bool localOnlySafe,
  bool blueprintExists = false,
  bool fixtureExists = false,
  bool dryRun = false,
  bool runFixtures = false,
  int parserCalls = 0,
  bool parserEvidenceReady = false,
}) {
  return {
    'trade': trade,
    'marketScope': scope,
    'tier': tier,
    'localePackId': locale,
    'status': status,
    'latestPipelineSummary': summaryPath,
    'blueprintExists': blueprintExists,
    'fixtureExists': fixtureExists,
    'dryRun': dryRun,
    'runFixtures': runFixtures,
    'parserCalls': parserCalls,
    'parserEvidenceReady': parserEvidenceReady,
    'localOnlySafe': localOnlySafe,
  };
}

class _StatusOptions {
  const _StatusOptions({
    required this.outputRoot,
    required this.trades,
    required this.scopes,
    required this.tiers,
    required this.locales,
    required this.reportDir,
    required this.requireComplete,
  });

  final String outputRoot;
  final List<String> trades;
  final List<String> scopes;
  final List<String> tiers;
  final List<String> locales;
  final String reportDir;
  final bool requireComplete;

  static _StatusOptions parse(List<String> args) {
    final values = <String, String>{};
    final flags = <String>{};
    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      if (!arg.startsWith('--')) continue;
      final key = arg.substring(2);
      if (index + 1 < args.length && !args[index + 1].startsWith('--')) {
        values[key] = args[++index];
      } else {
        flags.add(key);
      }
    }
    return _StatusOptions(
      outputRoot: values['output-root'] ?? 'build/parser_qa_pipeline',
      trades: _csv(values['trades'] ?? 'plumbing'),
      scopes: _csv(values['scopes'] ?? 'residential'),
      tiers: _csv(values['tiers'] ?? 'core'),
      locales: _csv(values['locales'] ?? 'en-US,es-US'),
      reportDir:
          values['report-dir'] ?? 'build/parser_qa_pipeline/status_reports',
      requireComplete: flags.contains('require-complete'),
    );
  }

  static List<String> _csv(String value) {
    return value
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }
}

class _StatusArtifact {
  const _StatusArtifact({
    required this.timestampedJsonPath,
    required this.latestJsonPath,
  });

  final String timestampedJsonPath;
  final String latestJsonPath;
}
