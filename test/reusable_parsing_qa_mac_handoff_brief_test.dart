import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/reusable_parsing_qa_mac_handoff_brief.dart';

void main() {
  test('mac handoff brief emits compact next-step packet for the Mac Mini', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_reusable_mac_handoff_brief_',
    );
    addTearDown(() => root.deleteSync(recursive: true));

    _writeJson('${root.path}/docs/reusable_parsing_qa_checkpoint.json', {
      'windowsWorkingBranch': 'codex/inventory-parser-backup-20260702-2056',
      'windowsExecutionCommit': '2b52b6b',
      'readyForMacMeasurementWave': true,
      'readyToClaimNinetyPlus': false,
      'nextTradesByRemainingGap': ['hvac'],
      'totalRemainingChecked': 38,
      'expectedLocalDocsRefreshFiles': [
        'docs/reusable_parsing_qa_checkpoint.json',
        'docs/reusable_parsing_qa_checkpoint.md',
        'docs/reusable_parsing_qa_handoff_index.md',
      ],
      'generatedAtEdt': '2026-07-09 11:25 PM EDT',
    });

    _writeJson('${root.path}/docs/reusable_parsing_qa_mac_handoff_packet.json', {
      'primaryBranch': 'codex/reusable-parsing-qa-foundation',
      'baselineCommit': '8e9771d',
      'baselineCommitLabel':
          'Reusable parsing QA 2026-07-09 09:20 PM EDT: relax stale packet assertion',
      'generatedAtEdt': '2026-07-09 11:25 PM EDT',
      'claimBlockingFindings': ['trade_not_ready:hvac', 'mac_wave_not_merge_ready'],
      'claimNextActions': [
        'Keep the hvac Mac wave running until peh_core_mac_wave_status.json marks it readyToMerge.',
      ],
      'measurementCommandCount': 2,
      'rollupCommandCount': 1,
      'macMiniExpectedOutputs': [
        'build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json',
        'build/parser_qa_pipeline/peh_core_claim_readiness.json',
      ],
      'macMiniNextCommands': [
        [
          'dart',
          'run',
          'tool/work_supply_parser_qa_run_generated_fixtures.dart',
          '--fixture',
          'build/parser_qa_generated/work_supply_parser/hvac/residential/core/en-US/generated_fixtures.json',
        ],
        [
          'dart',
          'run',
          'tool/work_supply_parser_qa_generated_run_status.dart',
          '--output',
          'build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json',
        ],
      ],
      'currentMeasurementState': {
        'nextTradeByGap': 'hvac',
        'remainingCheckedForTopGap': 38,
        'totalRemainingChecked': 38,
      },
    });

    final stdout = _MemorySink();
    final stderr = _MemorySink();
    final exit = runReusableParsingQaMacHandoffBrief(
      ['--root', root.path],
      stdout: stdout,
      stderr: stderr,
    );

    expect(exit, 0);
    expect(stderr.content, isEmpty);
    expect(stdout.content, contains('QA_REUSABLE_PARSING_MAC_HANDOFF_BRIEF'));

    final payload = _extractPayload(stdout.content);
    expect(payload['primaryBranch'], 'codex/reusable-parsing-qa-foundation');
    expect(payload['windowsExecutionCommit'], '2b52b6b');
    expect(payload['readyForMacMeasurementWave'], isTrue);
    expect(payload['readyToClaimNinetyPlus'], isFalse);
    expect(payload['nextTradesByRemainingGap'], ['hvac']);
    expect(payload['totalRemainingChecked'], 38);
    expect(
      payload['claimBlockingFindings'].toString(),
      contains('trade_not_ready:hvac'),
    );
    expect(payload['measurementCommandCount'], 2);
    expect(payload['rollupCommandCount'], 1);
    expect(
      payload['firstMeasurementCommand'].toString(),
      contains('work_supply_parser_qa_run_generated_fixtures.dart'),
    );
    expect(
      payload['macMiniExpectedOutputs'].toString(),
      contains('mac_hvac_core_generated_run_status_25.json'),
    );
    expect(
      payload['readFirst'].toString(),
      contains('docs/reusable_parsing_qa_handoff_marker.md'),
    );
    expect(
      payload['expectedLocalDocsRefreshFiles'].toString(),
      contains('docs/reusable_parsing_qa_handoff_index.md'),
    );
  });
}

Map<String, Object?> _extractPayload(String stdout) {
  const prefix = 'QA_REUSABLE_PARSING_MAC_HANDOFF_BRIEF ';
  final start = stdout.indexOf(prefix);
  expect(start, isNot(-1));
  final jsonText = stdout.substring(start + prefix.length).trim();
  return jsonDecode(jsonText) as Map<String, Object?>;
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
