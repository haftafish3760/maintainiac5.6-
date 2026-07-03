import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_batch_wave.dart';

void main() {
  test('batch wave dry-run records accumulated QA layer plan', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_batch_wave_',
    );
    addTearDown(() => output.delete(recursive: true));

    final stdout = _MemorySink();
    final exit = await runWorkSupplyParserQaBatchWave(
      [
        '--wave-id',
        'residential-core-wave-002',
        '--previous-wave-id',
        'residential-core-wave-001',
        '--qa-layer',
        'merchant-abbreviation-v1',
        '--trades',
        'plumbing,electrical',
        '--tiers',
        'core',
        '--locales',
        'en-US,es-US',
        '--limit',
        '75',
        '--fixture-run-limit',
        '12',
        '--output-root',
        output.path,
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_BACKGROUND_QUEUE_SUMMARY'));
    expect(stdout.content, contains('QA_BATCH_WAVE_SUMMARY'));

    final waveDir = '${output.path}/residential-core-wave-002';
    final plan = _readJson('$waveDir/wave_plan.json');
    expect(plan['dryRun'], true);
    expect(plan['qaLayer'], 'merchant-abbreviation-v1');
    expect(
      plan['accumulatedWaveIds'],
      ['residential-core-wave-001', 'residential-core-wave-002'],
    );
    expect(plan['liveServicesAllowed'], false);
    expect(plan['writesProductionCatalog'], false);
    expect(plan['firebaseWritesAllowed'], false);
    expect(plan['ocrCameraExpensesTouched'], false);

    final summary = _readJson('$waveDir/wave_summary.json');
    expect(summary['queueExitCode'], 0);
    expect(summary['fixtureRunLimit'], 12);
    expect(summary['queueSummaryPath'], contains('summary.json'));

    final queueSummaryPath = summary['queueSummaryPath'].toString();
    final queueSummary = _readJson(queueSummaryPath);
    expect(queueSummary['dryRun'], true);
    expect(queueSummary['cellCount'], 4);
    expect(queueSummary['completedCellCount'], 4);
    expect(queueSummary['liveServicesAllowed'], false);
    expect(queueSummary['writesProductionCatalog'], false);
  });

  test('batch wave rejects unsafe empty limits', () async {
    final stderr = _MemorySink();
    final exit = await runWorkSupplyParserQaBatchWave(
      ['--limit', '0'],
      stdout: _MemorySink(),
      stderr: stderr,
    );

    expect(exit, 64);
    expect(stderr.content, contains('must be greater than zero'));
  });
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
