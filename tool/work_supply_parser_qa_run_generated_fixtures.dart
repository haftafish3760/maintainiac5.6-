import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_run_generated_fixtures.dart '
    '--fixture build/.../generated_fixtures.json '
    '[--max-cases 1000] [--fixture-ids id1,id2] '
    '[--chunk-size 200] '
    '[--start-index 0] [--max-chunks 0] '
    '[--report-dir build/parser_qa_reports/generated_fixtures] '
    '[--timeout-ms 900000] '
    '[--stale-report-timeout-ms 120000] '
    '[--warmup] [--verbose]';

Future<void> main(List<String> args) async {
  final exit = await runGeneratedParserFixtures(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

Future<int> runGeneratedParserFixtures(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
  Future<ProcessResult> Function(
    String executable,
    List<String> arguments, {
    bool runInShell,
  })?
  processRunner,
}) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final options = _FixtureRunnerOptions.parse(args);
  if (options.fixturePath.trim().isEmpty) {
    stderr.writeln('--fixture is required.');
    return 64;
  }
  if (options.maxCases <= 0) {
    stderr.writeln('--max-cases must be greater than zero.');
    return 64;
  }
  if (!File(options.fixturePath).existsSync()) {
    stderr.writeln('Generated fixture file not found: ${options.fixturePath}');
    return 66;
  }

  final chunks = _fixtureChunks(options);
  stdout.writeln(
    'QA_GENERATED_FIXTURE_RUN_WRAPPER runner=flutter-test '
    'reason=parser_core_not_yet_extracted_for_dart_cli '
    'fixture=${options.fixturePath} maxCases=${options.maxCases} '
    'chunkSize=${options.chunkSize} chunks=${chunks.length} '
    'startIndex=${options.startIndex} maxChunks=${options.maxChunks} '
    'timeoutMs=${options.timeoutMs} '
    'staleReportTimeoutMs=${options.staleReportTimeoutMs} '
    'warmup=${options.warmup} '
    'outputMode=${options.verbose ? 'verbose' : 'summary'}',
  );

  final chunkResults = <_ChunkRunSummary>[];
  var exitCode = 0;
  for (var index = 0; index < chunks.length; index++) {
    final chunk = chunks[index];
    final chunkReportDir =
        '${options.reportDir}/chunks/'
        '${(index + 1).toString().padLeft(3, '0')}';
    final command = _flutterCommandFor(
      options,
      chunk: chunk,
      reportDir: chunkReportDir,
    );
    final timer = Stopwatch()..start();
    final result = processRunner == null
        ? await _runProcessWithTimeout(
            'flutter',
            ['test', ...command],
            timeoutMs: options.timeoutMs,
            staleReportTimeoutMs: options.staleReportTimeoutMs,
            activeReportPath:
                '$chunkReportDir/latest_generated_fixture_run.json',
            runInShell: Platform.isWindows,
          )
        : await processRunner('flutter', [
            'test',
            ...command,
          ], runInShell: Platform.isWindows);
    timer.stop();
    final output = '${result.stdout}';
    final errorOutput = '${result.stderr}';
    final summary = _chunkSummary(
      chunkNumber: index + 1,
      chunkCount: chunks.length,
      fixtureCount: chunk.count,
      startIndex: chunk.startIndex,
      durationMs: timer.elapsedMilliseconds,
      output: output,
      reportDir: chunkReportDir,
      exitCode: result.exitCode,
    );
    chunkResults.add(summary);
    if (options.verbose) {
      stdout.write(output);
      stderr.write(errorOutput);
    } else {
      stdout.writeln(summary.toLogLine());
      if (result.exitCode != 0) {
        stdout.writeln(_tail(output, maxChars: 2400));
        if (errorOutput.trim().isNotEmpty) {
          stderr.writeln(_tail(errorOutput, maxChars: 2400));
        }
      }
    }
    if (result.exitCode != 0) {
      exitCode = result.exitCode;
      break;
    }
  }
  final aggregate = _writeAggregateReport(
    options: options,
    chunks: chunkResults,
    completedChunkCount: chunkResults.length,
    plannedChunkCount: chunks.length,
  );
  stdout.writeln(
    'QA_GENERATED_FIXTURE_RUN_AGGREGATE '
    'checked=${aggregate.checked} failures=${aggregate.failures} '
    'parserCalls=${aggregate.parserCalls} '
    'completedChunks=${chunkResults.length} plannedChunks=${chunks.length} '
    'report=${aggregate.reportPath}',
  );
  if (exitCode != 0) return exitCode;
  if (aggregate.failures > 0) return 1;
  if (aggregate.checked > 0 && aggregate.parserCalls <= 0) return 1;
  return exitCode;
}

class _FixtureRunnerOptions {
  const _FixtureRunnerOptions({
    required this.fixturePath,
    required this.maxCases,
    required this.reportDir,
    required this.fixtureIds,
    required this.chunkSize,
    required this.startIndex,
    required this.maxChunks,
    required this.timeoutMs,
    required this.staleReportTimeoutMs,
    required this.warmup,
    required this.verbose,
  });

  final String fixturePath;
  final int maxCases;
  final String reportDir;
  final Set<String> fixtureIds;
  final int chunkSize;
  final int startIndex;
  final int maxChunks;
  final int timeoutMs;
  final int staleReportTimeoutMs;
  final bool warmup;
  final bool verbose;

  static _FixtureRunnerOptions parse(List<String> args) {
    final timeoutMs =
        int.tryParse(_valueAfter(args, '--timeout-ms') ?? '') ?? 900000;
    final staleReportTimeoutMs =
        int.tryParse(_valueAfter(args, '--stale-report-timeout-ms') ?? '') ??
        120000;
    final chunkSize =
        int.tryParse(_valueAfter(args, '--chunk-size') ?? '') ?? 200;
    final startIndex =
        int.tryParse(_valueAfter(args, '--start-index') ?? '') ?? 0;
    final maxChunks =
        int.tryParse(_valueAfter(args, '--max-chunks') ?? '') ?? 0;
    return _FixtureRunnerOptions(
      fixturePath: _valueAfter(args, '--fixture') ?? '',
      maxCases: int.tryParse(_valueAfter(args, '--max-cases') ?? '') ?? 1000,
      reportDir:
          _valueAfter(args, '--report-dir') ??
          'build/parser_qa_reports/generated_fixtures',
      fixtureIds: _csvSet(_valueAfter(args, '--fixture-ids') ?? ''),
      chunkSize: chunkSize <= 0 ? 200 : chunkSize,
      startIndex: startIndex < 0 ? 0 : startIndex,
      maxChunks: maxChunks < 0 ? 0 : maxChunks,
      timeoutMs: timeoutMs <= 0 ? 900000 : timeoutMs,
      staleReportTimeoutMs: staleReportTimeoutMs < 0 ? 0 : staleReportTimeoutMs,
      warmup: args.contains('--warmup'),
      verbose: args.contains('--verbose'),
    );
  }
}

List<_FixtureChunk> _fixtureChunks(_FixtureRunnerOptions options) {
  final selectedCount = _selectedFixtureCount(options);
  if (selectedCount == 0) {
    return [const _FixtureChunk(startIndex: 0, count: 0)];
  }
  if (options.startIndex >= selectedCount) {
    return [_FixtureChunk(startIndex: options.startIndex, count: 0)];
  }
  final chunks = <_FixtureChunk>[];
  for (
    var startIndex = options.startIndex;
    startIndex < selectedCount;
    startIndex += options.chunkSize
  ) {
    if (options.maxChunks > 0 && chunks.length >= options.maxChunks) break;
    final count = startIndex + options.chunkSize > selectedCount
        ? selectedCount - startIndex
        : options.chunkSize;
    chunks.add(_FixtureChunk(startIndex: startIndex, count: count));
  }
  return chunks;
}

int _selectedFixtureCount(_FixtureRunnerOptions options) {
  final decoded = jsonDecode(File(options.fixturePath).readAsStringSync());
  if (decoded is! List) return 0;
  var count = 0;
  for (final entry in decoded) {
    if (entry is! Map) continue;
    final id = entry['id'] as String?;
    if (id == null || id.trim().isEmpty) continue;
    if (options.fixtureIds.isNotEmpty && !options.fixtureIds.contains(id)) {
      continue;
    }
    count++;
    if (count >= options.maxCases) break;
  }
  return count;
}

List<String> _flutterCommandFor(
  _FixtureRunnerOptions options, {
  required _FixtureChunk chunk,
  required String reportDir,
}) {
  return [
    'test/work_supply_parser_generated_fixture_runner_test.dart',
    '--dart-define=PARSER_QA_GENERATED_FIXTURE_PATH=${options.fixturePath}',
    '--dart-define=PARSER_QA_GENERATED_FIXTURE_MAX_CASES=${chunk.count}',
    '--dart-define=PARSER_QA_GENERATED_REPORT_DIR=$reportDir',
    '--dart-define=PARSER_QA_GENERATED_FIXTURE_START_INDEX=${chunk.startIndex}',
    if (options.warmup) '--dart-define=PARSER_QA_GENERATED_WARMUP=true',
    if (options.fixtureIds.isNotEmpty)
      '--dart-define=PARSER_QA_GENERATED_FIXTURE_IDS=${options.fixtureIds.join(',')}',
    '--reporter',
    'compact',
  ];
}

class _FixtureChunk {
  const _FixtureChunk({required this.startIndex, required this.count});

  final int startIndex;
  final int count;
}

Future<ProcessResult> _runProcessWithTimeout(
  String executable,
  List<String> arguments, {
  required int timeoutMs,
  required int staleReportTimeoutMs,
  required String activeReportPath,
  required bool runInShell,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    runInShell: runInShell,
  );
  final stdoutFuture = process.stdout.transform(utf8.decoder).join();
  final stderrFuture = process.stderr.transform(utf8.decoder).join();
  var stopReason = '';
  final futures = <Future<int>>[
    process.exitCode,
    Future<int>.delayed(Duration(milliseconds: timeoutMs), () {
      stopReason = 'timed out after ${timeoutMs}ms';
      _killProcessTree(process.pid);
      return 124;
    }),
  ];
  if (staleReportTimeoutMs > 0) {
    futures.add(
      _staleActiveReportExitCode(
        activeReportPath,
        staleReportTimeoutMs: staleReportTimeoutMs,
        processId: process.pid,
      ).then((staleExit) async {
        if (staleExit != null) {
          stopReason =
              'stalled with no completed parser cases for '
              '${staleReportTimeoutMs}ms';
          return staleExit;
        }
        return process.exitCode;
      }),
    );
  }
  final exitCode = await Future.any<int>(futures);
  final stdoutText = await stdoutFuture;
  final stderrText = await stderrFuture;
  return ProcessResult(
    process.pid,
    exitCode,
    stdoutText,
    stopReason.isNotEmpty
        ? '$stderrText\nGenerated fixture runner $stopReason.'
        : stderrText,
  );
}

Future<int?> _staleActiveReportExitCode(
  String reportPath, {
  required int staleReportTimeoutMs,
  required int processId,
}) async {
  final deadline = DateTime.now().add(
    Duration(milliseconds: staleReportTimeoutMs),
  );
  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!_isProcessAlive(processId)) return null;
    final report = File(reportPath);
    if (!report.existsSync()) continue;
    try {
      final json = jsonDecode(report.readAsStringSync()) as Map;
      final checked = json['checked'] as int? ?? 0;
      final incomplete = json['incomplete'] == true;
      if (checked > 0 || !incomplete) return null;
    } catch (_) {
      return null;
    }
  }
  if (_isProcessAlive(processId)) {
    _killProcessTree(processId);
    return 124;
  }
  return null;
}

bool _isProcessAlive(int processId) {
  try {
    if (Platform.isWindows) {
      final result = Process.runSync('tasklist', ['/FI', 'PID eq $processId']);
      return '${result.stdout}'.contains('$processId');
    }
    return Process.runSync('kill', ['-0', '$processId']).exitCode == 0;
  } catch (_) {
    return false;
  }
}

void _killProcessTree(int processId) {
  if (Platform.isWindows) {
    Process.runSync('taskkill', ['/PID', '$processId', '/T', '/F']);
  } else {
    Process.killPid(processId, ProcessSignal.sigkill);
  }
}

_ChunkRunSummary _chunkSummary({
  required int chunkNumber,
  required int chunkCount,
  required int fixtureCount,
  required int startIndex,
  required int durationMs,
  required String output,
  required String reportDir,
  required int exitCode,
}) {
  final report = File('$reportDir/latest_generated_fixture_run.json');
  if (report.existsSync()) {
    try {
      final json =
          jsonDecode(report.readAsStringSync()) as Map<String, dynamic>;
      final incomplete = json['incomplete'] == true;
      return _ChunkRunSummary(
        chunkNumber: chunkNumber,
        chunkCount: chunkCount,
        checked: json['checked'] as int? ?? fixtureCount,
        failures: incomplete ? 1 : json['failureCount'] as int? ?? 0,
        warmupMs: json['warmupMs'] as int? ?? 0,
        parserCalls: json['parserCalls'] as int? ?? 0,
        exitCode: incomplete && exitCode == 0 ? 1 : exitCode,
        startIndex: startIndex,
        fixtureCount: fixtureCount,
        durationMs: durationMs,
        reportPath: report.path,
      );
    } catch (_) {
      // Corrupt chunk report falls back to stdout summary below; the non-zero
      // child exit still preserves the underlying failure.
    }
  }
  final line = output
      .split(RegExp(r'\r?\n'))
      .lastWhere(
        (entry) => entry.startsWith('QA_GENERATED_FIXTURE_RUN '),
        orElse: () => '',
      )
      .trim();
  return _ChunkRunSummary(
    chunkNumber: chunkNumber,
    chunkCount: chunkCount,
    checked: _intField(line, 'checked') ?? fixtureCount,
    failures: _intField(line, 'failures') ?? (exitCode == 0 ? 0 : 1),
    warmupMs: _intField(line, 'warmupMs') ?? 0,
    parserCalls: _intField(line, 'parserCalls') ?? 0,
    exitCode: exitCode,
    startIndex: startIndex,
    fixtureCount: fixtureCount,
    durationMs: durationMs,
    reportPath: report.path,
  );
}

_AggregateRunSummary _writeAggregateReport({
  required _FixtureRunnerOptions options,
  required List<_ChunkRunSummary> chunks,
  required int completedChunkCount,
  required int plannedChunkCount,
}) {
  final directory = Directory(options.reportDir)..createSync(recursive: true);
  final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
    RegExp(r'[:.]'),
    '',
  );
  final timestamped = File(
    '${directory.path}/generated_fixture_aggregate_$stamp.json',
  );
  final latest = File('${directory.path}/latest_generated_fixture_run.json');
  final checked = chunks.fold<int>(0, (sum, chunk) => sum + chunk.checked);
  final failures = chunks.fold<int>(0, (sum, chunk) => sum + chunk.failures);
  final parserCalls = chunks.fold<int>(
    0,
    (sum, chunk) => sum + chunk.parserCalls,
  );
  final durationMs = chunks.fold<int>(
    0,
    (sum, chunk) => sum + chunk.durationMs,
  );
  final nonZeroChunkExitCount = chunks
      .where((chunk) => chunk.exitCode != 0)
      .length;
  final timedOutChunkCount = chunks
      .where((chunk) => chunk.exitCode == 124)
      .length;
  final report = {
    'schemaVersion': 1,
    'domain': 'work_supply_inventory_parser_generated_fixtures',
    'fixturePath': options.fixturePath,
    'maxCases': options.maxCases,
    'chunkSize': options.chunkSize,
    'startIndex': options.startIndex,
    'maxChunks': options.maxChunks,
    'plannedChunkCount': plannedChunkCount,
    'completedChunkCount': completedChunkCount,
    'checked': checked,
    'failureCount': failures,
    'parserCalls': parserCalls,
    'durationMs': durationMs,
    'nonZeroChunkExitCount': nonZeroChunkExitCount,
    'timedOutChunkCount': timedOutChunkCount,
    'failedChunkStartIndex': _failedChunkStartIndex(chunks),
    'nextResumeStartIndex': _nextResumeStartIndex(chunks, plannedChunkCount),
    'resumeCommand': _resumeCommand(options, chunks, plannedChunkCount),
    'chunkReports': [
      for (final chunk in chunks)
        {
          'chunkNumber': chunk.chunkNumber,
          'chunkCount': chunk.chunkCount,
          'startIndex': chunk.startIndex,
          'fixtureCount': chunk.fixtureCount,
          'checked': chunk.checked,
          'failureCount': chunk.failures,
          'warmupMs': chunk.warmupMs,
          'parserCalls': chunk.parserCalls,
          'exitCode': chunk.exitCode,
          'durationMs': chunk.durationMs,
          'reportPath': chunk.reportPath,
        },
    ],
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
    'generatedAtIso': DateTime.now().toUtc().toIso8601String(),
  };
  final encoded = const JsonEncoder.withIndent('  ').convert(report);
  timestamped.writeAsStringSync(encoded, flush: true);
  latest.writeAsStringSync(encoded, flush: true);
  return _AggregateRunSummary(
    checked: checked,
    failures: failures,
    parserCalls: parserCalls,
    nonZeroChunkExitCount: nonZeroChunkExitCount,
    timedOutChunkCount: timedOutChunkCount,
    reportPath: latest.path,
  );
}

int? _failedChunkStartIndex(List<_ChunkRunSummary> chunks) {
  for (final chunk in chunks) {
    if (chunk.exitCode != 0) return chunk.startIndex;
  }
  return null;
}

int? _nextResumeStartIndex(
  List<_ChunkRunSummary> chunks,
  int plannedChunkCount,
) {
  if (chunks.isEmpty || chunks.length >= plannedChunkCount) return null;
  final last = chunks.last;
  if (last.exitCode != 0) return last.startIndex;
  return last.startIndex + last.fixtureCount;
}

String _resumeCommand(
  _FixtureRunnerOptions options,
  List<_ChunkRunSummary> chunks,
  int plannedChunkCount,
) {
  final failedIndex = _failedChunkStartIndex(chunks);
  final resumeIndex =
      failedIndex ?? _nextResumeStartIndex(chunks, plannedChunkCount);
  if (resumeIndex == null) return '';
  return [
    'dart run tool/work_supply_parser_qa_run_generated_fixtures.dart',
    '--fixture ${options.fixturePath}',
    '--max-cases ${options.maxCases}',
    '--chunk-size ${options.chunkSize}',
    '--start-index $resumeIndex',
    if (options.maxChunks > 0) '--max-chunks ${options.maxChunks}',
    if (options.fixtureIds.isNotEmpty)
      '--fixture-ids ${options.fixtureIds.join(',')}',
    '--report-dir ${options.reportDir}',
    '--timeout-ms ${options.timeoutMs}',
    '--stale-report-timeout-ms ${options.staleReportTimeoutMs}',
  ].join(' ');
}

int? _intField(String line, String name) {
  final match = RegExp('(?:^| )$name=([0-9]+)(?: |\$)').firstMatch(line);
  return int.tryParse(match?.group(1) ?? '');
}

class _ChunkRunSummary {
  const _ChunkRunSummary({
    required this.chunkNumber,
    required this.chunkCount,
    required this.checked,
    required this.failures,
    required this.warmupMs,
    required this.parserCalls,
    required this.exitCode,
    required this.startIndex,
    required this.fixtureCount,
    required this.durationMs,
    required this.reportPath,
  });

  final int chunkNumber;
  final int chunkCount;
  final int checked;
  final int failures;
  final int warmupMs;
  final int parserCalls;
  final int exitCode;
  final int startIndex;
  final int fixtureCount;
  final int durationMs;
  final String reportPath;

  String toLogLine() {
    return 'QA_GENERATED_FIXTURE_RUN_CHUNK '
        'chunk=$chunkNumber/$chunkCount startIndex=$startIndex '
        'fixtureCount=$fixtureCount checked=$checked failures=$failures '
        'warmupMs=$warmupMs parserCalls=$parserCalls durationMs=$durationMs '
        'exitCode=$exitCode report=$reportPath';
  }
}

class _AggregateRunSummary {
  const _AggregateRunSummary({
    required this.checked,
    required this.failures,
    required this.parserCalls,
    required this.nonZeroChunkExitCount,
    required this.timedOutChunkCount,
    required this.reportPath,
  });

  final int checked;
  final int failures;
  final int parserCalls;
  final int nonZeroChunkExitCount;
  final int timedOutChunkCount;
  final String reportPath;
}

String _tail(String value, {required int maxChars}) {
  final trimmed = value.trim();
  if (trimmed.length <= maxChars) return trimmed;
  return '... output truncated ...\n'
      '${trimmed.substring(trimmed.length - maxChars)}';
}

Set<String> _csvSet(String value) {
  return value
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toSet();
}

String? _valueAfter(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}
