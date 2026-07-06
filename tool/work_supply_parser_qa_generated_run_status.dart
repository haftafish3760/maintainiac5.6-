import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_generated_run_status.dart '
    '[--report-root build/parser_qa_background_queue/pass2372-core-semantic-fixtures/cells] '
    '[--trades plumbing,electrical,hvac] [--scopes residential] '
    '[--tiers core] [--locales en-US,es-US] '
    '[--min-checked-per-cell 0] '
    '[--output build/parser_qa_pipeline/core_generated_run_status.json] '
    '[--require-complete]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaGeneratedRunStatus(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaGeneratedRunStatus(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final options = _Options.parse(args);
  final cells = <Map<String, Object?>>[];
  var missing = 0;
  var failed = 0;
  var unsafe = 0;
  var checkedTotal = 0;
  var parserCalls = 0;
  var durationMs = 0;
  var underMinChecked = 0;

  for (final trade in options.trades) {
    for (final scope in options.scopes) {
      for (final tier in options.tiers) {
        for (final locale in options.locales) {
          final cell = _readCell(options, trade, scope, tier, locale);
          cells.add(cell);
          if (cell['status'] == 'missing') missing++;
          if (((cell['failureCount'] as int?) ?? 0) > 0) failed++;
          if (cell['localOnlySafe'] == false) unsafe++;
          if (cell['underMinChecked'] == true) underMinChecked++;
          checkedTotal += (cell['checked'] as int?) ?? 0;
          parserCalls += (cell['parserCalls'] as int?) ?? 0;
          durationMs += (cell['durationMs'] as int?) ?? 0;
        }
      }
    }
  }

  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_generated_run_status',
    'reportRoot': options.reportRoot,
    'expectedCells': cells.length,
    'presentCells': cells.length - missing,
    'missingCells': missing,
    'failedCells': failed,
    'unsafeCells': unsafe,
    'underMinCheckedCells': underMinChecked,
    'minCheckedPerCell': options.minCheckedPerCell,
    'checkedTotal': checkedTotal,
    'parserCalls': parserCalls,
    'durationMs': durationMs,
    'requireComplete': options.requireComplete,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
    'cells': cells,
    'generatedAtIso': DateTime.now().toUtc().toIso8601String(),
  };

  final output = File(options.output)..parent.createSync(recursive: true);
  output.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(summary),
    flush: true,
  );
  stdout.writeln(
    'QA_GENERATED_RUN_STATUS '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln('QA_GENERATED_RUN_STATUS_ARTIFACT json=${output.path}');

  if (unsafe > 0 || failed > 0 || underMinChecked > 0) return 1;
  if (options.requireComplete && missing > 0) return 2;
  return 0;
}

Map<String, Object?> _readCell(
  _Options options,
  String trade,
  String scope,
  String tier,
  String locale,
) {
  final reportPath = _reportPathFor(options, trade, scope, tier, locale);
  final file = File(reportPath);
  if (!file.existsSync()) {
    return _cell(
      trade: trade,
      scope: scope,
      tier: tier,
      locale: locale,
      status: 'missing',
      reportPath: reportPath,
      localOnlySafe: true,
    );
  }
  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  final failureCount = (json['failureCount'] as int?) ?? 0;
  final safety = _cellSafety(json);
  final parserCalls = _parserCallCount(json);
  final durationMs = _durationMs(json);
  final chunkRunComplete = _chunkRunComplete(json);
  final nonZeroChunkExitCount = (json['nonZeroChunkExitCount'] as int?) ?? 0;
  final timedOutChunkCount = (json['timedOutChunkCount'] as int?) ?? 0;
  final checked = (json['checked'] as int?) ?? 0;
  final underMinChecked =
      options.minCheckedPerCell > 0 && checked < options.minCheckedPerCell;
  return _cell(
    trade: trade,
    scope: scope,
    tier: tier,
    locale: locale,
    status: failureCount == 0 ? 'passed' : 'failed',
    reportPath: reportPath,
    localOnlySafe:
        safety.isSafe &&
        parserCalls > 0 &&
        chunkRunComplete &&
        nonZeroChunkExitCount == 0 &&
        timedOutChunkCount == 0 &&
        !underMinChecked,
    safetyFlags: safety.flags,
    safetyMissingFields: safety.missingFields,
    chunkRunComplete: chunkRunComplete,
    nonZeroChunkExitCount: nonZeroChunkExitCount,
    timedOutChunkCount: timedOutChunkCount,
    checked: checked,
    failureCount: failureCount,
    parserCalls: parserCalls,
    durationMs: durationMs,
    minCheckedPerCell: options.minCheckedPerCell,
    underMinChecked: underMinChecked,
    fixturePath: json['fixturePath']?.toString() ?? '',
  );
}

String _reportPathFor(
  _Options options,
  String trade,
  String scope,
  String tier,
  String locale,
) {
  final matrixPath =
      '${options.reportRoot}/$trade/$scope/$tier/$locale/reports/latest_generated_fixture_run.json';
  if (File(matrixPath).existsSync()) return matrixPath;
  final directPath =
      '${options.reportRoot}/reports/latest_generated_fixture_run.json';
  final singleCell =
      options.trades.length == 1 &&
      options.scopes.length == 1 &&
      options.tiers.length == 1 &&
      options.locales.length == 1;
  if (singleCell && File(directPath).existsSync()) return directPath;
  return matrixPath;
}

bool _chunkRunComplete(Map<String, Object?> json) {
  final planned = json['plannedChunkCount'];
  final completed = json['completedChunkCount'];
  if (planned is! int && completed is! int) return true;
  if (planned is! int || completed is! int) return false;
  return planned > 0 && completed == planned;
}

int _parserCallCount(Map<String, Object?> json) {
  final direct = json['parserCalls'];
  if (direct is int && direct > 0) return direct;
  final chunkReports = json['chunkReports'];
  if (chunkReports is! List) return 0;
  var total = 0;
  for (final chunk in chunkReports) {
    if (chunk is! Map) continue;
    final inline = chunk['parserCalls'];
    if (inline is int && inline > 0) {
      total += inline;
      continue;
    }
    final reportPath = chunk['reportPath']?.toString() ?? '';
    if (reportPath.isEmpty) continue;
    final report = File(reportPath);
    if (!report.existsSync()) continue;
    try {
      final decoded = jsonDecode(report.readAsStringSync());
      if (decoded is! Map) continue;
      final recovered = decoded['parserCalls'];
      if (recovered is int && recovered > 0) total += recovered;
    } catch (_) {
      continue;
    }
  }
  return total;
}

int _durationMs(Map<String, Object?> json) {
  final direct = json['durationMs'];
  if (direct is int && direct >= 0) return direct;
  final chunkReports = json['chunkReports'];
  if (chunkReports is! List) return 0;
  var total = 0;
  for (final chunk in chunkReports) {
    if (chunk is! Map) continue;
    final inline = chunk['durationMs'];
    if (inline is int && inline >= 0) total += inline;
  }
  return total;
}

Map<String, Object?> _cell({
  required String trade,
  required String scope,
  required String tier,
  required String locale,
  required String status,
  required String reportPath,
  required bool localOnlySafe,
  Map<String, Object?> safetyFlags = const {},
  List<String> safetyMissingFields = const [],
  bool chunkRunComplete = true,
  int nonZeroChunkExitCount = 0,
  int timedOutChunkCount = 0,
  int checked = 0,
  int failureCount = 0,
  int parserCalls = 0,
  int durationMs = 0,
  int minCheckedPerCell = 0,
  bool underMinChecked = false,
  String fixturePath = '',
}) {
  return {
    'cellId': '${trade}_${scope}_${tier}_${locale.replaceAll('-', '_')}',
    'trade': trade,
    'marketScope': scope,
    'tier': tier,
    'localePackId': locale,
    'status': status,
    'reportPath': reportPath,
    'reportExists': status != 'missing',
    'checked': checked,
    'failureCount': failureCount,
    'parserCalls': parserCalls,
    'durationMs': durationMs,
    'minCheckedPerCell': minCheckedPerCell,
    'underMinChecked': underMinChecked,
    'fixturePath': fixturePath,
    'localOnlySafe': localOnlySafe,
    'safetyFlags': safetyFlags,
    'safetyMissingFields': safetyMissingFields,
    'chunkRunComplete': chunkRunComplete,
    'nonZeroChunkExitCount': nonZeroChunkExitCount,
    'timedOutChunkCount': timedOutChunkCount,
  };
}

_CellSafety _cellSafety(Map<String, Object?> json) {
  const requiredFalseFields = [
    'liveServicesAllowed',
    'writesProductionCatalog',
    'firebaseWritesAllowed',
    'ocrCameraExpensesTouched',
  ];
  final flags = {for (final field in requiredFalseFields) field: json[field]};
  final missing = [
    for (final field in requiredFalseFields)
      if (!json.containsKey(field)) field,
  ];
  final unsafe = requiredFalseFields.any((field) => json[field] == true);
  return _CellSafety(
    flags: flags,
    missingFields: missing,
    isSafe: !unsafe && missing.isEmpty,
  );
}

class _CellSafety {
  const _CellSafety({
    required this.flags,
    required this.missingFields,
    required this.isSafe,
  });

  final Map<String, Object?> flags;
  final List<String> missingFields;
  final bool isSafe;
}

class _Options {
  const _Options({
    required this.reportRoot,
    required this.trades,
    required this.scopes,
    required this.tiers,
    required this.locales,
    required this.output,
    required this.requireComplete,
    required this.minCheckedPerCell,
  });

  final String reportRoot;
  final List<String> trades;
  final List<String> scopes;
  final List<String> tiers;
  final List<String> locales;
  final String output;
  final bool requireComplete;
  final int minCheckedPerCell;

  static _Options parse(List<String> args) {
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
    return _Options(
      reportRoot:
          values['report-root'] ??
          'build/parser_qa_background_queue/pass2372-core-semantic-fixtures/cells',
      trades: _csv(values['trades'] ?? 'plumbing,electrical,hvac'),
      scopes: _csv(values['scopes'] ?? 'residential'),
      tiers: _csv(values['tiers'] ?? 'core'),
      locales: _csv(values['locales'] ?? 'en-US,es-US', lowerCase: false),
      output:
          values['output'] ??
          'build/parser_qa_pipeline/core_generated_run_status.json',
      requireComplete: flags.contains('require-complete'),
      minCheckedPerCell:
          int.tryParse(values['min-checked-per-cell'] ?? '') ?? 0,
    );
  }
}

List<String> _csv(String value, {bool lowerCase = true}) {
  return value
      .split(',')
      .map((entry) => lowerCase ? entry.trim().toLowerCase() : entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();
}
