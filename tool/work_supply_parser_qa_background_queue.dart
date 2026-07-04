import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_background_queue.dart '
    '[--execute] [--trades plumbing] [--tiers core,standard] '
    '[--locales en-US,es-US] [--limit 500] [--fixture-run-limit 25]';

Future<void> main(List<String> args) async {
  final exit = await runWorkSupplyParserQaBackgroundQueue(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

Future<int> runWorkSupplyParserQaBackgroundQueue(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final options = _QueueOptions.parse(args);
  if (options.limit <= 0 || options.fixtureRunLimit <= 0) {
    stderr.writeln(
      '--limit and --fixture-run-limit must be greater than zero.',
    );
    return 64;
  }
  final runDir = Directory('${options.outputRoot}/${options.queueId}')
    ..createSync(recursive: true);
  final cells = _cells(options);
  final results = <Map<String, Object?>>[];
  final queueStartedAt = DateTime.now().toUtc();
  var failed = false;
  _writeStatus(
    options: options,
    runDir: runDir,
    cells: cells,
    results: results,
    activeCell: null,
    state: 'starting',
  );
  for (final cell in cells) {
    final command = _matrixCommand(options, cell);
    final transcriptPath = '${runDir.path}/${cell.id}_transcript.txt';
    final startedAt = DateTime.now().toUtc();
    _writeStatus(
      options: options,
      runDir: runDir,
      cells: cells,
      results: results,
      activeCell: cell,
      activeCellStartedAt: startedAt,
      state: 'running',
    );
    var exit = 0;
    var stdoutText = 'DRY RUN';
    var stderrText = '';
    var durationMs = 0;
    if (options.execute) {
      final process = await Process.run(
        command.first,
        command.skip(1).toList(),
        workingDirectory: Directory.current.path,
        runInShell: Platform.isWindows,
      );
      exit = process.exitCode;
      stdoutText = process.stdout.toString();
      stderrText = process.stderr.toString();
      durationMs = DateTime.now().toUtc().difference(startedAt).inMilliseconds;
    }
    final completedAt = DateTime.now().toUtc();
    File(transcriptPath).writeAsStringSync(
      [
        'startedAt=${startedAt.toIso8601String()}',
        'completedAt=${completedAt.toIso8601String()}',
        'workingDirectory=${Directory.current.path}',
        'command=${command.join(' ')}',
        'exitCode=$exit',
        'durationMs=$durationMs',
        '--- stdout ---',
        stdoutText,
        '--- stderr ---',
        stderrText,
      ].join('\n'),
      flush: true,
    );
    results.add({
      'cellId': cell.id,
      'trade': cell.trade,
      'marketScope': cell.scope,
      'tier': cell.tier,
      'localePackId': cell.locale,
      'exitCode': exit,
      'durationMs': durationMs,
      'startedAtIso': startedAt.toIso8601String(),
      'completedAtIso': completedAt.toIso8601String(),
      'transcriptPath': transcriptPath,
      'dryRun': !options.execute,
    });
    if (exit != 0) {
      failed = true;
      if (options.stopOnFailure) break;
    }
    _writeStatus(
      options: options,
      runDir: runDir,
      cells: cells,
      results: results,
      activeCell: null,
      state: failed ? 'failed' : 'running',
    );
  }
  final queueCompletedAt = DateTime.now().toUtc();
  final summary = {
    'schemaVersion': 1,
    'queue': 'work_supply_parser_qa_background_queue',
    'queueId': options.queueId,
    'dryRun': !options.execute,
    'startedAtIso': queueStartedAt.toIso8601String(),
    'completedAtIso': queueCompletedAt.toIso8601String(),
    'durationMs': queueCompletedAt.difference(queueStartedAt).inMilliseconds,
    'cellCount': cells.length,
    'completedCellCount': results.length,
    'failedCellCount': results.where((r) => r['exitCode'] != 0).length,
    'limit': options.limit,
    'fixtureRunLimit': options.fixtureRunLimit,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
    'results': results,
  };
  final summaryPath = '${runDir.path}/summary.json';
  File(summaryPath).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(summary),
    flush: true,
  );
  File('${options.outputRoot}/latest_summary.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(summary));
  stdout.writeln('QA_BACKGROUND_QUEUE_SUMMARY $summaryPath');
  _writeStatus(
    options: options,
    runDir: runDir,
    cells: cells,
    results: results,
    activeCell: null,
    state: failed ? 'failed' : 'complete',
  );
  return failed ? 1 : 0;
}

void _writeStatus({
  required _QueueOptions options,
  required Directory runDir,
  required List<_QueueCell> cells,
  required List<Map<String, Object?>> results,
  required _QueueCell? activeCell,
  DateTime? activeCellStartedAt,
  required String state,
}) {
  final now = DateTime.now().toUtc();
  final status = {
    'schemaVersion': 1,
    'queue': 'work_supply_parser_qa_background_queue_status',
    'queueId': options.queueId,
    'state': state,
    'dryRun': !options.execute,
    'cellCount': cells.length,
    'completedCellCount': results.length,
    'failedCellCount': results.where((r) => r['exitCode'] != 0).length,
    if (activeCell != null) 'activeCellId': activeCell.id,
    if (activeCellStartedAt != null)
      'activeCellStartedAtIso': activeCellStartedAt.toIso8601String(),
    if (activeCellStartedAt != null)
      'activeCellElapsedMs': now.difference(activeCellStartedAt).inMilliseconds,
    'updatedAtIso': now.toIso8601String(),
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
    'results': results,
  };
  final json = const JsonEncoder.withIndent('  ').convert(status);
  File(
    '${runDir.path}/latest_status.json',
  ).writeAsStringSync(json, flush: true);
  File('${options.outputRoot}/latest_status.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(json, flush: true);
}

List<_QueueCell> _cells(_QueueOptions options) {
  return [
    for (final trade in options.trades)
      for (final scope in options.scopes)
        for (final tier in options.tiers)
          for (final locale in options.locales)
            _QueueCell(trade: trade, scope: scope, tier: tier, locale: locale),
  ];
}

List<String> _matrixCommand(_QueueOptions options, _QueueCell cell) {
  return [
    'dart',
    'run',
    'tool/work_supply_parser_qa_matrix_pipeline.dart',
    '--first-round',
    if (options.execute) '--execute',
    if (options.resume) '--resume',
    if (options.continueOnFailure) '--continue-on-failure',
    '--trades',
    cell.trade,
    '--scopes',
    cell.scope,
    '--tiers',
    cell.tier,
    '--locales',
    cell.locale,
    '--limit',
    '${options.limit}',
    '--fixture-run-limit',
    '${options.fixtureRunLimit}',
    '--output-root',
    '${options.outputRoot}/${options.queueId}/cells',
  ];
}

class _QueueOptions {
  const _QueueOptions({
    required this.trades,
    required this.scopes,
    required this.tiers,
    required this.locales,
    required this.limit,
    required this.fixtureRunLimit,
    required this.outputRoot,
    required this.queueId,
    required this.execute,
    required this.resume,
    required this.stopOnFailure,
    required this.continueOnFailure,
  });

  final List<String> trades;
  final List<String> scopes;
  final List<String> tiers;
  final List<String> locales;
  final int limit;
  final int fixtureRunLimit;
  final String outputRoot;
  final String queueId;
  final bool execute;
  final bool resume;
  final bool stopOnFailure;
  final bool continueOnFailure;

  static _QueueOptions parse(List<String> args) {
    final values = <String, String>{};
    final flags = <String>{};
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (!arg.startsWith('--')) continue;
      final key = arg.substring(2);
      if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
        values[key] = args[++i];
      } else {
        flags.add(key);
      }
    }
    final now = DateTime.now().toUtc().toIso8601String();
    return _QueueOptions(
      trades: _csv(values['trades'] ?? 'plumbing'),
      scopes: _csv(values['scopes'] ?? 'residential'),
      tiers: _csv(values['tiers'] ?? 'core,standard'),
      locales: _csv(values['locales'] ?? 'en-US,es-US', lowerCase: false),
      limit: int.tryParse(values['limit'] ?? '') ?? 500,
      fixtureRunLimit: int.tryParse(values['fixture-run-limit'] ?? '') ?? 25,
      outputRoot: values['output-root'] ?? 'build/parser_qa_background_queue',
      queueId: values['queue-id'] ?? now.replaceAll(RegExp(r'[:.]'), ''),
      execute: flags.contains('execute'),
      resume: !flags.contains('no-resume'),
      stopOnFailure: !flags.contains('continue-on-failure'),
      continueOnFailure: flags.contains('continue-on-failure'),
    );
  }
}

class _QueueCell {
  const _QueueCell({
    required this.trade,
    required this.scope,
    required this.tier,
    required this.locale,
  });

  final String trade;
  final String scope;
  final String tier;
  final String locale;

  String get id => '${trade}_${scope}_${tier}_$locale'.replaceAll('-', '_');
}

List<String> _csv(String value, {bool lowerCase = true}) {
  return value
      .split(',')
      .map((entry) => lowerCase ? entry.trim().toLowerCase() : entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();
}
