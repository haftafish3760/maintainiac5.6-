import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_background_queue.dart';

void main() {
  test('background queue dry-run writes commands and transcripts', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_background_queue_',
    );
    addTearDown(() => output.delete(recursive: true));

    final stdout = _MemorySink();
    final exit = await runWorkSupplyParserQaBackgroundQueue(
      [
        '--trades',
        'plumbing',
        '--tiers',
        'core,standard',
        '--locales',
        'en-US,es-US',
        '--limit',
        '50',
        '--fixture-run-limit',
        '10',
        '--queue-id',
        'dry-run-test',
        '--output-root',
        output.path,
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_BACKGROUND_QUEUE_SUMMARY'));
    final summary =
        jsonDecode(
              File(
                '${output.path}/dry-run-test/summary.json',
              ).readAsStringSync(),
            )
            as Map;
    expect(summary['dryRun'], true);
    expect(summary['cellCount'], 4);
    expect(summary['completedCellCount'], 4);
    expect(summary['startedAtIso'], isA<String>());
    expect(summary['completedAtIso'], isA<String>());
    expect(summary['durationMs'], isA<int>());
    expect(summary['liveServicesAllowed'], false);
    expect(summary['writesProductionCatalog'], false);
    final status =
        jsonDecode(
              File(
                '${output.path}/dry-run-test/latest_status.json',
              ).readAsStringSync(),
            )
            as Map;
    expect(status['state'], 'complete');
    expect(status['completedCellCount'], 4);
    expect(status['liveServicesAllowed'], false);
    expect(status['writesProductionCatalog'], false);
    final first = (summary['results'] as List).first as Map;
    expect(first['startedAtIso'], isA<String>());
    expect(first['completedAtIso'], isA<String>());
    expect(first['durationMs'], isA<int>());
    final transcript = File(first['transcriptPath'].toString());
    expect(transcript.existsSync(), true);
    final transcriptText = transcript.readAsStringSync();
    expect(transcriptText, contains('startedAt='));
    expect(transcriptText, contains('completedAt='));
    expect(transcriptText, contains('DRY RUN'));
    expect(transcriptText, contains('work_supply_parser_qa_matrix_pipeline'));
    expect(transcriptText, contains('--fixture-run-limit 10'));
  });

  test('background queue rejects unsafe empty limits', () async {
    final stderr = _MemorySink();
    final exit = await runWorkSupplyParserQaBackgroundQueue(
      ['--limit', '0'],
      stdout: _MemorySink(),
      stderr: stderr,
    );

    expect(exit, 64);
    expect(stderr.content, contains('must be greater than zero'));
  });

  test('background queue resume skips already successful cells', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_background_queue_resume_',
    );
    addTearDown(() => output.delete(recursive: true));
    final queueDir = Directory('${output.path}/resume-test')
      ..createSync(recursive: true);
    final previousTranscript = File(
      '${queueDir.path}/plumbing_residential_core_en_US_transcript.txt',
    )..writeAsStringSync('previous successful transcript');
    File('${queueDir.path}/latest_status.json').writeAsStringSync(
      jsonEncode({
        'results': [
          {
            'cellId': 'plumbing_residential_core_en_US',
            'trade': 'plumbing',
            'marketScope': 'residential',
            'tier': 'core',
            'localePackId': 'en-US',
            'exitCode': 0,
            'durationMs': 123,
            'startedAtIso': '2026-07-04T11:20:24.071782Z',
            'completedAtIso': '2026-07-04T11:24:41.545512Z',
            'transcriptPath': previousTranscript.path,
            'dryRun': true,
          },
        ],
      }),
    );

    final stdout = _MemorySink();
    final exit = await runWorkSupplyParserQaBackgroundQueue(
      [
        '--trades',
        'plumbing',
        '--tiers',
        'core',
        '--locales',
        'en-US,es-US',
        '--limit',
        '50',
        '--fixture-run-limit',
        '10',
        '--queue-id',
        'resume-test',
        '--output-root',
        output.path,
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final summary =
        jsonDecode(File('${queueDir.path}/summary.json').readAsStringSync())
            as Map;
    expect(summary['cellCount'], 2);
    expect(summary['completedCellCount'], 2);
    expect(summary['resumedCellCount'], 1);
    final results = summary['results'] as List;
    expect(
      results.where(
        (result) =>
            (result as Map)['cellId'] == 'plumbing_residential_core_en_US',
      ),
      hasLength(1),
    );
    expect(
      previousTranscript.readAsStringSync(),
      'previous successful transcript',
    );
    final newTranscript = File(
      '${queueDir.path}/plumbing_residential_core_es_US_transcript.txt',
    );
    expect(newTranscript.existsSync(), true);
    expect(newTranscript.readAsStringSync(), contains('DRY RUN'));
  });

  test(
    'background queue resume recovers successful generated fixture artifacts',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_background_queue_artifact_resume_',
      );
      addTearDown(() => output.delete(recursive: true));
      final queueDir = Directory('${output.path}/artifact-resume-test')
        ..createSync(recursive: true);
      final reportDir = Directory(
        '${queueDir.path}/cells/electrical/residential/core/en-US/reports',
      )..createSync(recursive: true);
      File(
        '${reportDir.path}/latest_generated_fixture_run.json',
      ).writeAsStringSync(
        jsonEncode({
          'schemaVersion': 1,
          'checked': 125,
          'failureCount': 0,
          'liveServicesAllowed': false,
          'writesProductionCatalog': false,
          'firebaseWritesAllowed': false,
          'ocrCameraExpensesTouched': false,
          'generatedAtIso': '2026-07-04T13:55:27.383162Z',
        }),
      );
      File('${queueDir.path}/latest_status.json').writeAsStringSync(
        jsonEncode({
          'state': 'running',
          'activeCellId': 'electrical_residential_core_en_US',
          'results': <Map<String, Object?>>[],
        }),
      );

      final exit = await runWorkSupplyParserQaBackgroundQueue(
        [
          '--trades',
          'electrical',
          '--tiers',
          'core',
          '--locales',
          'en-US,es-US',
          '--limit',
          '500',
          '--fixture-run-limit',
          '125',
          '--queue-id',
          'artifact-resume-test',
          '--output-root',
          output.path,
        ],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 0);
      final summary =
          jsonDecode(File('${queueDir.path}/summary.json').readAsStringSync())
              as Map;
      expect(summary['cellCount'], 2);
      expect(summary['completedCellCount'], 2);
      expect(summary['resumedCellCount'], 1);
      final results = summary['results'] as List;
      final recovered = results.cast<Map>().singleWhere(
        (result) => result['cellId'] == 'electrical_residential_core_en_US',
      );
      expect(recovered['recoveredFromGeneratedFixtureReport'], true);
      expect(recovered['checked'], 125);
      final newTranscript = File(
        '${queueDir.path}/electrical_residential_core_es_US_transcript.txt',
      );
      expect(newTranscript.existsSync(), true);
      expect(newTranscript.readAsStringSync(), contains('DRY RUN'));
    },
  );

  test(
    'background queue does not recover undersized fixture artifacts',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_background_queue_undersized_resume_',
      );
      addTearDown(() => output.delete(recursive: true));
      final queueDir = Directory('${output.path}/undersized-resume-test')
        ..createSync(recursive: true);
      final reportDir = Directory(
        '${queueDir.path}/cells/electrical/residential/core/en-US/reports',
      )..createSync(recursive: true);
      File(
        '${reportDir.path}/latest_generated_fixture_run.json',
      ).writeAsStringSync(
        jsonEncode({
          'schemaVersion': 1,
          'checked': 125,
          'failureCount': 0,
          'generatedAtIso': '2026-07-04T13:55:27.383162Z',
        }),
      );

      final exit = await runWorkSupplyParserQaBackgroundQueue(
        [
          '--trades',
          'electrical',
          '--tiers',
          'core',
          '--locales',
          'en-US',
          '--limit',
          '500',
          '--fixture-run-limit',
          '500',
          '--queue-id',
          'undersized-resume-test',
          '--output-root',
          output.path,
        ],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 0);
      final summary =
          jsonDecode(File('${queueDir.path}/summary.json').readAsStringSync())
              as Map;
      expect(summary['resumedCellCount'], 0);
      final transcript = File(
        '${queueDir.path}/electrical_residential_core_en_US_transcript.txt',
      );
      expect(transcript.existsSync(), true);
      expect(transcript.readAsStringSync(), contains('DRY RUN'));
    },
  );

  test(
    'background queue does not recover reports missing safety evidence',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_background_queue_missing_safety_resume_',
      );
      addTearDown(() => output.delete(recursive: true));
      final queueDir = Directory('${output.path}/missing-safety-resume-test')
        ..createSync(recursive: true);
      final reportDir = Directory(
        '${queueDir.path}/cells/electrical/residential/core/en-US/reports',
      )..createSync(recursive: true);
      File(
        '${reportDir.path}/latest_generated_fixture_run.json',
      ).writeAsStringSync(
        jsonEncode({
          'schemaVersion': 1,
          'checked': 125,
          'failureCount': 0,
          'generatedAtIso': '2026-07-04T13:55:27.383162Z',
        }),
      );
      File('${queueDir.path}/latest_status.json').writeAsStringSync(
        jsonEncode({
          'results': [
            {
              'cellId': 'electrical_residential_core_en_US',
              'trade': 'electrical',
              'marketScope': 'residential',
              'tier': 'core',
              'localePackId': 'en-US',
              'exitCode': 0,
              'durationMs': 0,
              'startedAtIso': '2026-07-04T13:55:27.383162Z',
              'completedAtIso': '2026-07-04T13:55:27.383162Z',
              'dryRun': false,
            },
          ],
        }),
      );

      final exit = await runWorkSupplyParserQaBackgroundQueue(
        [
          '--trades',
          'electrical',
          '--tiers',
          'core',
          '--locales',
          'en-US',
          '--limit',
          '500',
          '--fixture-run-limit',
          '125',
          '--queue-id',
          'missing-safety-resume-test',
          '--output-root',
          output.path,
        ],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 0);
      final summary =
          jsonDecode(File('${queueDir.path}/summary.json').readAsStringSync())
              as Map;
      expect(summary['resumedCellCount'], 0);
      final transcript = File(
        '${queueDir.path}/electrical_residential_core_en_US_transcript.txt',
      );
      expect(transcript.existsSync(), true);
      expect(transcript.readAsStringSync(), contains('DRY RUN'));
    },
  );

  test('background queue records timed-out cell evidence', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_background_queue_timeout_',
    );
    addTearDown(() => output.delete(recursive: true));

    final exit = await runWorkSupplyParserQaBackgroundQueue(
      [
        '--execute',
        '--trades',
        'hvac',
        '--tiers',
        'core',
        '--locales',
        'en-US',
        '--limit',
        '500',
        '--fixture-run-limit',
        '125',
        '--cell-timeout-ms',
        '250',
        '--queue-id',
        'timeout-test',
        '--output-root',
        output.path,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
      cellRunner: (command, {timeout, onHeartbeat}) async {
        expect(
          command,
          contains('tool/work_supply_parser_qa_matrix_pipeline.dart'),
        );
        expect(timeout, const Duration(milliseconds: 250));
        onHeartbeat?.call();
        final activeStatus =
            jsonDecode(
                  File(
                    '${output.path}/timeout-test/latest_status.json',
                  ).readAsStringSync(),
                )
                as Map;
        expect(activeStatus['activeCellId'], 'hvac_residential_core_en_US');
        expect(activeStatus['activeCellElapsedMs'], isA<int>());
        return const BackgroundQueueCellResult(
          exitCode: 124,
          stdout: 'partial stdout',
          stderr: 'QA_BACKGROUND_QUEUE_CELL_TIMEOUT timeoutMs=250',
        );
      },
    );

    expect(exit, 1);
    final queueDir = Directory('${output.path}/timeout-test');
    final summary =
        jsonDecode(File('${queueDir.path}/summary.json').readAsStringSync())
            as Map;
    expect(summary['failedCellCount'], 1);
    expect(summary['cellTimeoutMs'], 250);
    final transcript = File(
      '${queueDir.path}/hvac_residential_core_en_US_transcript.txt',
    );
    expect(transcript.readAsStringSync(), contains('CELL_TIMEOUT'));
  });

  test('background queue applies default bounded cell timeout', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_background_queue_default_timeout_',
    );
    addTearDown(() => output.delete(recursive: true));

    final exit = await runWorkSupplyParserQaBackgroundQueue(
      [
        '--execute',
        '--trades',
        'plumbing',
        '--tiers',
        'core',
        '--locales',
        'en-US',
        '--queue-id',
        'default-timeout-test',
        '--output-root',
        output.path,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
      cellRunner: (command, {timeout, onHeartbeat}) async {
        expect(timeout, const Duration(milliseconds: 1200000));
        return const BackgroundQueueCellResult(
          exitCode: 0,
          stdout: 'ok',
          stderr: '',
        );
      },
    );

    expect(exit, 0);
    final summary =
        jsonDecode(
              File(
                '${output.path}/default-timeout-test/summary.json',
              ).readAsStringSync(),
            )
            as Map;
    expect(summary['cellTimeoutMs'], 1200000);
  });
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
