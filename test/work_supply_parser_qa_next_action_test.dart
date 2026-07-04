import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_next_action.dart';

void main() {
  test('next action allows the next local batch when evidence is ready', () {
    final root = Directory.systemTemp.createTempSync('maintainiac_next_');
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
      'commands': [
        {'cellId': 'plumbing.residential.core.en-US'},
      ],
    });
    _writeJson('build/parser_qa_pass_evidence/evidence_summary.json', {
      'missingArtifactNames': <String>[],
      'unsafeFindings': <String>[],
    });
    final stdout = _MemorySink();

    final exit = runWorkSupplyParserQaNextAction(
      const [],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_NEXT_ACTION'));
    final summary = _readJson('build/parser_qa_pass_evidence/next_action.json');
    expect(summary['readyForNextBatch'], isTrue);
    expect(summary['releaseOneCellCount'], 1);
    expect(summary['nextActions'].toString(), contains('next local-only'));
  });

  test('next action blocks unsafe evidence before release progression', () {
    final root = Directory.systemTemp.createTempSync('maintainiac_next_bad_');
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
      'commands': [
        {'cellId': 'plumbing.residential.core.en-US'},
      ],
    });
    _writeJson('build/parser_qa_pass_evidence/evidence_summary.json', {
      'missingArtifactNames': <String>[],
      'unsafeFindings': ['firebaseWritesAllowed=true'],
    });

    final exit = runWorkSupplyParserQaNextAction(
      const [],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final summary = _readJson('build/parser_qa_pass_evidence/next_action.json');
    expect(summary['readyForNextBatch'], isFalse);
    expect(summary['nextActions'].toString(), contains('unsafe'));
  });

  test('next action waits when a parser batch wave is already running', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_next_active_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
      'commands': [
        {'cellId': 'plumbing.residential.core.en-US'},
      ],
    });
    _writeJson('build/parser_qa_pass_evidence/evidence_summary.json', {
      'missingArtifactNames': <String>[],
      'unsafeFindings': <String>[],
    });
    _writeJson(
      'build/parser_qa_batch_waves/wave/queue/queue-id/latest_status.json',
      {
        'state': 'running',
        'queueId': 'queue-id',
        'activeCellId': 'plumbing_residential_core_en_US',
        'completedCellCount': 1,
        'failedCellCount': 0,
        'updatedAtIso': DateTime.now().toUtc().toIso8601String(),
        'activeCellElapsedMs': 1000,
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': false,
        'ocrCameraExpensesTouched': false,
      },
    );
    _writeJson('build/parser_qa_batch_waves/wave/queue/latest_status.json', {
      'state': 'running',
      'queueId': 'queue-id',
      'activeCellId': 'plumbing_residential_core_en_US',
      'completedCellCount': 1,
      'failedCellCount': 0,
      'updatedAtIso': DateTime.now().toUtc().toIso8601String(),
      'activeCellElapsedMs': 1000,
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': false,
      'ocrCameraExpensesTouched': false,
    });

    final exit = runWorkSupplyParserQaNextAction(
      const [],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final summary = _readJson('build/parser_qa_pass_evidence/next_action.json');
    expect(summary['readyForNextBatch'], isFalse);
    expect(summary['activeWaveCount'], 1);
    expect(summary['nextActions'].toString(), contains('active local-only'));
  });

  test('next action blocks unsafe flags from an active parser wave', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_next_active_unsafe_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
      'commands': [
        {'cellId': 'plumbing.residential.core.en-US'},
      ],
    });
    _writeJson('build/parser_qa_pass_evidence/evidence_summary.json', {
      'missingArtifactNames': <String>[],
      'unsafeFindings': <String>[],
    });
    _writeJson(
      'build/parser_qa_batch_waves/wave/queue/queue-id/latest_status.json',
      {
        'state': 'running',
        'queueId': 'queue-id',
        'activeCellId': 'plumbing_residential_core_en_US',
        'completedCellCount': 1,
        'failedCellCount': 0,
        'updatedAtIso': DateTime.now().toUtc().toIso8601String(),
        'activeCellElapsedMs': 1000,
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': true,
        'ocrCameraExpensesTouched': false,
      },
    );

    final exit = runWorkSupplyParserQaNextAction(
      const [],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final summary = _readJson('build/parser_qa_pass_evidence/next_action.json');
    expect(summary['readyForNextBatch'], isFalse);
    expect(
      summary['activeWaveUnsafeFindings'].toString(),
      contains('firebase'),
    );
    expect(summary['unsafeFindings'].toString(), contains('activeWave'));
  });

  test('next action blocks stale active wave status updates', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_next_stale_status_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
      'commands': [
        {'cellId': 'plumbing.residential.core.en-US'},
      ],
    });
    _writeJson('build/parser_qa_pass_evidence/evidence_summary.json', {
      'missingArtifactNames': <String>[],
      'unsafeFindings': <String>[],
    });
    _writeJson(
      'build/parser_qa_batch_waves/wave/queue/queue-id/latest_status.json',
      {
        'state': 'running',
        'queueId': 'queue-id',
        'activeCellId': 'plumbing_residential_core_en_US',
        'completedCellCount': 1,
        'failedCellCount': 0,
        'updatedAtIso': '2000-01-01T00:00:00.000Z',
        'activeCellElapsedMs': 1000,
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': false,
        'ocrCameraExpensesTouched': false,
      },
    );

    final exit = runWorkSupplyParserQaNextAction(
      const ['--max-status-age-ms', '1000'],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final summary = _readJson('build/parser_qa_pass_evidence/next_action.json');
    expect(summary['readyForNextBatch'], isFalse);
    expect(
      summary['activeWaveUnsafeFindings'].toString(),
      contains('activeWaveStatusStale'),
    );
  });

  test('next action blocks stale active parser cells', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_next_stale_cell_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
      'commands': [
        {'cellId': 'plumbing.residential.core.en-US'},
      ],
    });
    _writeJson('build/parser_qa_pass_evidence/evidence_summary.json', {
      'missingArtifactNames': <String>[],
      'unsafeFindings': <String>[],
    });
    _writeJson(
      'build/parser_qa_batch_waves/wave/queue/queue-id/latest_status.json',
      {
        'state': 'running',
        'queueId': 'queue-id',
        'activeCellId': 'plumbing_residential_core_en_US',
        'completedCellCount': 1,
        'failedCellCount': 0,
        'updatedAtIso': DateTime.now().toUtc().toIso8601String(),
        'activeCellElapsedMs': 60000,
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': false,
        'ocrCameraExpensesTouched': false,
      },
    );

    final exit = runWorkSupplyParserQaNextAction(
      const ['--max-active-cell-ms', '1000'],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final summary = _readJson('build/parser_qa_pass_evidence/next_action.json');
    expect(summary['readyForNextBatch'], isFalse);
    expect(
      summary['activeWaveUnsafeFindings'].toString(),
      contains('activeWaveCellStale'),
    );
  });

  test('next action computes active cell elapsed from start timestamp', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_next_computed_cell_elapsed_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
      'commands': [
        {'cellId': 'plumbing.residential.core.en-US'},
      ],
    });
    _writeJson('build/parser_qa_pass_evidence/evidence_summary.json', {
      'missingArtifactNames': <String>[],
      'unsafeFindings': <String>[],
    });
    final startedAt = DateTime.now()
        .toUtc()
        .subtract(const Duration(minutes: 5))
        .toIso8601String();
    _writeJson(
      'build/parser_qa_batch_waves/wave/queue/queue-id/latest_status.json',
      {
        'state': 'running',
        'queueId': 'queue-id',
        'activeCellId': 'plumbing_residential_core_en_US',
        'activeCellStartedAtIso': startedAt,
        'completedCellCount': 1,
        'failedCellCount': 0,
        'updatedAtIso': startedAt,
        'activeCellElapsedMs': 0,
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': false,
        'ocrCameraExpensesTouched': false,
      },
    );

    final exit = runWorkSupplyParserQaNextAction(
      const ['--max-active-cell-ms', '1000'],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final summary = _readJson('build/parser_qa_pass_evidence/next_action.json');
    expect(
      summary['activeWaveUnsafeFindings'].toString(),
      contains('activeWaveCellStale'),
    );
    expect(
      summary['activeWaveUnsafeFindings'].toString(),
      isNot(contains('activeWaveStatusStale')),
    );
  });

  test('next action blocks active parser waves with failed cells', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_next_failed_cells_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
      'commands': [
        {'cellId': 'plumbing.residential.core.en-US'},
      ],
    });
    _writeJson('build/parser_qa_pass_evidence/evidence_summary.json', {
      'missingArtifactNames': <String>[],
      'unsafeFindings': <String>[],
    });
    _writeJson(
      'build/parser_qa_batch_waves/wave/queue/queue-id/latest_status.json',
      {
        'state': 'running',
        'queueId': 'queue-id',
        'activeCellId': 'plumbing_residential_standard_en_US',
        'completedCellCount': 2,
        'failedCellCount': 1,
        'updatedAtIso': DateTime.now().toUtc().toIso8601String(),
        'activeCellElapsedMs': 1000,
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': false,
        'ocrCameraExpensesTouched': false,
      },
    );

    final exit = runWorkSupplyParserQaNextAction(
      const [],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final summary = _readJson('build/parser_qa_pass_evidence/next_action.json');
    expect(summary['readyForNextBatch'], isFalse);
    expect(
      summary['activeWaveUnsafeFindings'].toString(),
      contains('waveFailedCells'),
    );
  });

  test('next action blocks completed failed parser waves', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_next_failed_wave_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
      'commands': [
        {'cellId': 'plumbing.residential.core.en-US'},
      ],
    });
    _writeJson('build/parser_qa_pass_evidence/evidence_summary.json', {
      'missingArtifactNames': <String>[],
      'unsafeFindings': <String>[],
    });
    _writeJson(
      'build/parser_qa_batch_waves/wave/queue/queue-id/latest_status.json',
      {
        'state': 'failed',
        'queueId': 'queue-id',
        'completedCellCount': 9,
        'failedCellCount': 1,
        'updatedAtIso': DateTime.now().toUtc().toIso8601String(),
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': false,
        'ocrCameraExpensesTouched': false,
      },
    );

    final exit = runWorkSupplyParserQaNextAction(
      const [],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final summary = _readJson('build/parser_qa_pass_evidence/next_action.json');
    expect(summary['readyForNextBatch'], isFalse);
    expect(summary['blockingWaveCount'], 1);
    expect(summary['nextActions'].toString(), contains('Fix failed'));
    expect(summary['unsafeFindings'].toString(), contains('waveFailedCells'));
  });

  test('next action accepts remediated failed parser waves with evidence', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_next_remediated_wave_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
      'commands': [
        {'cellId': 'plumbing.residential.core.en-US'},
      ],
    });
    _writeJson('build/parser_qa_pass_evidence/evidence_summary.json', {
      'missingArtifactNames': <String>[],
      'unsafeFindings': <String>[],
    });
    _writeJson(
      'build/parser_qa_batch_waves/wave/queue/queue-id/latest_status.json',
      {
        'state': 'failed',
        'queueId': 'queue-id',
        'completedCellCount': 9,
        'failedCellCount': 1,
        'updatedAtIso': DateTime.now().toUtc().toIso8601String(),
        'liveServicesAllowed': false,
        'writesProductionCatalog': false,
        'firebaseWritesAllowed': false,
        'ocrCameraExpensesTouched': false,
      },
    );
    _writeJson('build/parser_qa_pass_evidence/remediation_report.json', {
      'checked': 118,
      'failureCount': 0,
    });
    _writeJson('build/parser_qa_pass_evidence/wave_remediations.json', {
      'remediations': [
        {
          'queueId': 'queue-id',
          'fixedCellIds': ['electrical_residential_core_en_US'],
          'fixedCommit': 'abc1234',
          'evidenceReport':
              'build/parser_qa_pass_evidence/remediation_report.json',
        },
      ],
    });

    final exit = runWorkSupplyParserQaNextAction(
      const [],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final summary = _readJson('build/parser_qa_pass_evidence/next_action.json');
    expect(summary['readyForNextBatch'], isTrue);
    expect(summary['blockingWaveCount'], 0);
    expect(summary['remediatedWaveCount'], 1);
    expect(summary['unsafeFindings'].toString(), isNot(contains('queue-id')));
  });

  test(
    'next action accepts remediated stale running parser waves with evidence',
    () {
      final root = Directory.systemTemp.createTempSync(
        'maintainiac_next_remediated_running_wave_',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final previous = Directory.current;
      Directory.current = root;
      addTearDown(() => Directory.current = previous);
      _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
        'commands': [
          {'cellId': 'hvac.residential.standard.es-US'},
        ],
      });
      _writeJson('build/parser_qa_pass_evidence/evidence_summary.json', {
        'missingArtifactNames': <String>[],
        'unsafeFindings': <String>[],
      });
      _writeJson(
        'build/parser_qa_batch_waves/wave/queue/queue-id/latest_status.json',
        {
          'state': 'running',
          'queueId': 'queue-id',
          'activeCellId': 'hvac_residential_standard_es_US',
          'activeCellStartedAtIso': DateTime.now()
              .toUtc()
              .subtract(const Duration(hours: 2))
              .toIso8601String(),
          'completedCellCount': 19,
          'failedCellCount': 3,
          'updatedAtIso': DateTime.now().toUtc().toIso8601String(),
          'liveServicesAllowed': false,
          'writesProductionCatalog': false,
          'firebaseWritesAllowed': false,
          'ocrCameraExpensesTouched': false,
        },
      );
      _writeJson('build/parser_qa_pass_evidence/remediation_report.json', {
        'checked': 360,
        'failureCount': 0,
      });
      _writeJson('build/parser_qa_pass_evidence/wave_remediations.json', {
        'remediations': [
          {
            'queueId': 'queue-id',
            'fixedCellIds': [
              'hvac_residential_core_en_US',
              'hvac_residential_core_es_US',
              'hvac_residential_standard_en_US',
            ],
            'fixedCommit': 'abc1234',
            'evidenceReport':
                'build/parser_qa_pass_evidence/remediation_report.json',
          },
        ],
      });

      final exit = runWorkSupplyParserQaNextAction(
        const [],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 0);
      final summary = _readJson(
        'build/parser_qa_pass_evidence/next_action.json',
      );
      expect(summary['readyForNextBatch'], isTrue);
      expect(summary['blockingWaveCount'], 0);
      expect(summary['activeWaveCount'], 0);
      expect(summary['remediatedWaveCount'], 1);
      expect(summary['unsafeFindings'].toString(), isNot(contains('queue-id')));
    },
  );

  test(
    'next action rejects failed-wave remediation without passing evidence',
    () {
      final root = Directory.systemTemp.createTempSync(
        'maintainiac_next_bad_remediation_',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final previous = Directory.current;
      Directory.current = root;
      addTearDown(() => Directory.current = previous);
      _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
        'commands': [
          {'cellId': 'plumbing.residential.core.en-US'},
        ],
      });
      _writeJson('build/parser_qa_pass_evidence/evidence_summary.json', {
        'missingArtifactNames': <String>[],
        'unsafeFindings': <String>[],
      });
      _writeJson(
        'build/parser_qa_batch_waves/wave/queue/queue-id/latest_status.json',
        {
          'state': 'failed',
          'queueId': 'queue-id',
          'completedCellCount': 9,
          'failedCellCount': 1,
          'updatedAtIso': DateTime.now().toUtc().toIso8601String(),
          'liveServicesAllowed': false,
          'writesProductionCatalog': false,
          'firebaseWritesAllowed': false,
          'ocrCameraExpensesTouched': false,
        },
      );
      _writeJson('build/parser_qa_pass_evidence/remediation_report.json', {
        'checked': 118,
        'failureCount': 1,
      });
      _writeJson('build/parser_qa_pass_evidence/wave_remediations.json', {
        'remediations': [
          {
            'queueId': 'queue-id',
            'fixedCellIds': ['electrical_residential_core_en_US'],
            'fixedCommit': 'abc1234',
            'evidenceReport':
                'build/parser_qa_pass_evidence/remediation_report.json',
          },
        ],
      });

      final exit = runWorkSupplyParserQaNextAction(
        const [],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 1);
      final summary = _readJson(
        'build/parser_qa_pass_evidence/next_action.json',
      );
      expect(summary['readyForNextBatch'], isFalse);
      expect(summary['blockingWaveCount'], 1);
      expect(summary['remediatedWaveCount'], 0);
      expect(summary['unsafeFindings'].toString(), contains('waveFailedCells'));
    },
  );

  test('next action reports corrupt evidence artifacts without crashing', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_next_corrupt_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
      'commands': [
        {'cellId': 'plumbing.residential.core.en-US'},
      ],
    });
    final evidence = File('build/parser_qa_pass_evidence/evidence_summary.json')
      ..parent.createSync(recursive: true);
    evidence.writeAsStringSync('{not-json');

    final exit = runWorkSupplyParserQaNextAction(
      const [],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final summary = _readJson('build/parser_qa_pass_evidence/next_action.json');
    expect(summary['readyForNextBatch'], isFalse);
    expect(summary['unsafeFindings'].toString(), contains('jsonReadError'));
  });

  test('next action reports corrupt active wave status without crashing', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_next_corrupt_status_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/release_one_commands.json', {
      'commands': [
        {'cellId': 'plumbing.residential.core.en-US'},
      ],
    });
    _writeJson('build/parser_qa_pass_evidence/evidence_summary.json', {
      'missingArtifactNames': <String>[],
      'unsafeFindings': <String>[],
    });
    final status = File(
      'build/parser_qa_batch_waves/wave/queue/queue-id/latest_status.json',
    )..parent.createSync(recursive: true);
    status.writeAsStringSync('{not-json');

    final exit = runWorkSupplyParserQaNextAction(
      const [],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final summary = _readJson('build/parser_qa_pass_evidence/next_action.json');
    expect(summary['readyForNextBatch'], isFalse);
    expect(
      summary['activeWaveUnsafeFindings'].toString(),
      contains('ReadError'),
    );
    expect(summary['unsafeFindings'].toString(), contains('activeWaveStatus'));
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
