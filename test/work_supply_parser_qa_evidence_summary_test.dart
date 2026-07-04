import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_evidence_summary.dart';

void main() {
  test('evidence summary rolls up local-only artifacts', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_evidence_summary_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
      'cellCount': 24,
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': false,
      'ocrCameraExpensesTouched': false,
    });
    _writeJson('build/parser_qa_pipeline/fixture_readiness_rollup.json', {
      'totalCells': 24,
      'generatedFixtureCount': 24,
      'readyForParserExecution': true,
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': false,
      'ocrCameraExpensesTouched': false,
    });
    _writeJson(
      'build/parser_qa_batch_waves/residential_all_tiers_wave_001/queue_watchdog.json',
      {
        'healthy': true,
        'findings': [],
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': false,
        'ocrCameraExpensesTouched': false,
      },
    );
    _writeJson('build/parser_qa_pass_evidence/latest_pass_evidence.json', {
      'pass': '350',
      'label': 'test-pass',
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': false,
      'ocrCameraExpensesTouched': false,
    });
    _writeJson(
      'build/parser_qa_reports/latest_work_supply_inventory_parser.json',
      {'checked': 159, 'actualFailureCount': 0},
    );
    final stdout = _MemorySink();

    final exit = runWorkSupplyParserQaEvidenceSummary(
      const [],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_EVIDENCE_SUMMARY'));
    final summary = _readJson(
      'build/parser_qa_pass_evidence/evidence_summary.json',
    );
    expect(summary['ready'], isTrue);
    expect(summary['missingArtifactNames'], isEmpty);
    expect(summary['unsafeFindings'], isEmpty);
    expect(summary['artifacts'].toString(), contains('fixtureReadinessRollup'));
    expect(summary['artifacts'].toString(), contains('queueWatchdog'));
  });

  test('evidence summary exits nonzero for unsafe artifact flags', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_evidence_summary_unsafe_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
      'liveServicesAllowed': true,
    });
    _writeJson('build/parser_qa_pipeline/fixture_readiness_rollup.json', {
      'liveServicesAllowed': false,
    });
    _writeJson(
      'build/parser_qa_batch_waves/residential_all_tiers_wave_001/queue_watchdog.json',
      {'liveServicesAllowed': false},
    );
    _writeJson('build/parser_qa_pass_evidence/latest_pass_evidence.json', {
      'firebaseWritesAllowed': false,
    });
    _writeJson(
      'build/parser_qa_reports/latest_work_supply_inventory_parser.json',
      {'checked': 1},
    );

    final exit = runWorkSupplyParserQaEvidenceSummary(
      const [],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final summary = _readJson(
      'build/parser_qa_pass_evidence/evidence_summary.json',
    );
    expect(summary['ready'], isFalse);
    expect(
      summary['unsafeFindings'].toString(),
      contains('liveServicesAllowed'),
    );
  });

  test('evidence summary exits nonzero for unhealthy watchdog artifact', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_evidence_summary_watchdog_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
      'liveServicesAllowed': false,
    });
    _writeJson('build/parser_qa_pipeline/fixture_readiness_rollup.json', {
      'liveServicesAllowed': false,
    });
    _writeJson(
      'build/parser_qa_batch_waves/residential_all_tiers_wave_001/queue_watchdog.json',
      {
        'healthy': false,
        'findings': ['active_cell_stale'],
        'liveServicesAllowed': false,
      },
    );
    _writeJson('build/parser_qa_pass_evidence/latest_pass_evidence.json', {
      'firebaseWritesAllowed': false,
    });
    _writeJson(
      'build/parser_qa_reports/latest_work_supply_inventory_parser.json',
      {'checked': 1},
    );

    final exit = runWorkSupplyParserQaEvidenceSummary(
      const [],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final summary = _readJson(
      'build/parser_qa_pass_evidence/evidence_summary.json',
    );
    expect(summary['ready'], isFalse);
    expect(summary['unsafeFindings'].toString(), contains('healthy=false'));
  });

  test('evidence summary exits nonzero for missing required artifacts', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_evidence_summary_missing_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': false,
      'ocrCameraExpensesTouched': false,
    });

    final exit = runWorkSupplyParserQaEvidenceSummary(
      const [],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final summary = _readJson(
      'build/parser_qa_pass_evidence/evidence_summary.json',
    );
    expect(summary['ready'], isFalse);
    expect(
      summary['missingArtifactNames'].toString(),
      contains('queueWatchdog'),
    );
  });

  test('evidence summary can use the current queue watchdog artifact', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_evidence_summary_current_watchdog_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
      'cellCount': 24,
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': false,
      'ocrCameraExpensesTouched': false,
    });
    _writeJson('build/parser_qa_pipeline/fixture_readiness_rollup.json', {
      'totalCells': 24,
      'generatedFixtureCount': 24,
      'readyForParserExecution': true,
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': false,
      'ocrCameraExpensesTouched': false,
    });
    _writeJson('build/current/queue_watchdog.json', {
      'healthy': true,
      'findings': [],
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': false,
      'ocrCameraExpensesTouched': false,
    });
    _writeJson('build/parser_qa_pass_evidence/latest_pass_evidence.json', {
      'pass': '2429',
      'label': 'release-one-core-standard-broad-contract-gate',
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': false,
      'ocrCameraExpensesTouched': false,
    });
    _writeJson(
      'build/parser_qa_reports/latest_work_supply_inventory_parser.json',
      {'checked': 228043, 'actualFailureCount': 0},
    );

    final exit = runWorkSupplyParserQaEvidenceSummary(
      const ['--queue-watchdog', 'build/current/queue_watchdog.json'],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final summary = _readJson(
      'build/parser_qa_pass_evidence/evidence_summary.json',
    );
    expect(summary['ready'], isTrue);
    expect(summary['missingArtifactNames'], isEmpty);
    expect(summary['artifacts'].toString(), contains('build/current'));
  });
}

void _writeJson(String path, Map<String, Object?> value) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(value));
}

Map<String, Object?> _readJson(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
}

class _MemorySink implements IOSink {
  final _buffer = StringBuffer();

  String get content => _buffer.toString();

  @override
  void write(Object? object) => _buffer.write(object);

  @override
  void writeln([Object? object = '']) => _buffer.writeln(object);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
