import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/reusable_parsing_qa_handoff_sync.dart';

void main() {
  test('handoff sync refreshes docs and regenerates checkpoint together', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_reusable_handoff_sync_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    _writeJson('${root.path}/docs/reusable_parsing_qa_mac_handoff_packet.json', {
      'primaryBranch': 'old-branch',
      'baselineCommit': 'old1234',
      'baselineCommitFull': 'old1234full',
      'baselineCommitLabel': 'old label',
      'handoffMarkerPath': 'docs/reusable_parsing_qa_handoff_marker.md',
      'runbookPath': 'docs/reusable_parsing_qa_mac_runbook.md',
    });
    _writeJson('${root.path}/build/parser_qa_pipeline/peh_core_handoff_readiness.json', {
      'readyForMacMeasurementWave': true,
      'readyToClaimNinetyPlus': false,
      'nextActions': ['Wait on HVAC Mac wave before claiming 90-95 percent.'],
    });
    _writeJson('${root.path}/build/parser_qa_pipeline/peh_core_measurement_gap.json', {
      'totalRemainingChecked': 38,
      'nextTradesByRemainingGap': ['hvac'],
    });
    _writeJson('${root.path}/build/parser_qa_pipeline/peh_core_windows_status_rollup.json', {
      'sampleSizedTradeCount': 1,
      'underTargetTradeCount': 1,
    });

    final stdout = _MemorySink();
    final stderr = _MemorySink();
    final exit = runReusableParsingQaHandoffSync(
      const [
        '--root',
        '.',
        '--branch',
        'codex/reusable-parsing-qa-foundation',
        '--commit',
        'abc1234',
        '--commit-full',
        'abc1234fullsha',
        '--label',
        'Reusable parsing QA 2026-07-09 20:30 EDT: sync handoff stack',
        '--updated-at',
        '2026-07-09 20:30 EDT',
      ],
      stdout: stdout,
      stderr: stderr,
    );

    expect(exit, 0);
    expect(stderr.content, isEmpty);
    expect(stdout.content, contains('QA_REUSABLE_PARSING_HANDOFF_REFRESH'));
    expect(stdout.content, contains('QA_REUSABLE_PARSING_HANDOFF_CHECKPOINT'));
    expect(stdout.content, contains('QA_REUSABLE_PARSING_HANDOFF_SYNC_COMPLETE'));

    final packet = _readJson(
      '${root.path}/docs/reusable_parsing_qa_mac_handoff_packet.json',
    );
    final checkpoint = _readJson(
      '${root.path}/docs/reusable_parsing_qa_checkpoint.json',
    );
    final marker = File(
      '${root.path}/docs/reusable_parsing_qa_handoff_marker.md',
    ).readAsStringSync();

    expect(packet['baselineCommit'], 'abc1234');
    expect(
      packet['windowsCheckpointSyncCommand'],
      contains('reusable_parsing_qa_handoff_sync.dart'),
    );
    expect(checkpoint['validatedFloorCommit'], 'abc1234');
    expect(
      (checkpoint['macMiniNextActions'] as List<Object?>).join(' '),
      contains('hvac'),
    );
    expect(marker, contains('reusable_parsing_qa_checkpoint.md'));
  });
}

void _writeJson(String path, Map<String, Object?> value) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(value));
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
