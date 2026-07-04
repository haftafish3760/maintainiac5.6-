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
