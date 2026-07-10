import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/reusable_parsing_qa_handoff_checkpoint.dart';

void main() {
  test('handoff checkpoint emits windows and mac next actions from live artifacts', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_reusable_checkpoint_',
    );
    addTearDown(() => root.deleteSync(recursive: true));

    _writeJson('${root.path}/docs/reusable_parsing_qa_mac_handoff_packet.json', {
      'primaryBranch': 'codex/reusable-parsing-qa-foundation',
      'windowsWorkingBranch': 'codex/inventory-parser-backup-20260702-2056',
      'baselineCommit': '44f66d7',
      'baselineCommitLabel':
          'Reusable parsing QA 2026-07-09 20:24 EDT: add scope boundary handoff map',
      'generatedAtEdt': '2026-07-09 20:24 EDT',
    });
    _writeJson('${root.path}/build/parser_qa_pipeline/peh_core_handoff_readiness.json', {
      'readyForMacMeasurementWave': true,
      'readyToClaimNinetyPlus': false,
      'nextActions': [
        'Keep the branch below a 90-95 percent claim until Electrical and HVAC clear their broader measured Mac wave.',
      ],
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
    final exit = runReusableParsingQaHandoffCheckpoint(
      ['--root', root.path],
      stdout: stdout,
      stderr: stderr,
    );

    expect(exit, 0);
    expect(stderr.content, isEmpty);
    expect(stdout.content, contains('QA_REUSABLE_PARSING_HANDOFF_CHECKPOINT'));

    final checkpoint = jsonDecode(
          File('${root.path}/docs/reusable_parsing_qa_checkpoint.json')
              .readAsStringSync(),
        )
        as Map<String, Object?>;
    final markdown = File('${root.path}/docs/reusable_parsing_qa_checkpoint.md')
        .readAsStringSync();

    expect(checkpoint['validatedFloorCommit'], '44f66d7');
    expect(checkpoint['readyForMacMeasurementWave'], isTrue);
    expect(checkpoint['readyToClaimNinetyPlus'], isFalse);
    expect(checkpoint['totalRemainingChecked'], 38);
    expect(
      (checkpoint['nextTradesByRemainingGap'] as List<Object?>),
      contains('hvac'),
    );
    expect(markdown, contains('## Windows Next'));
    expect(markdown, contains('## Mac Mini Next'));
    expect(markdown, contains('hvac'));
  });
}

void _writeJson(String path, Map<String, Object?> value) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(value));
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
