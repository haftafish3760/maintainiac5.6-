import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/reusable_parsing_qa_handoff_refresh.dart';

void main() {
  test('handoff refresh rewrites packet, marker, runbook, and index together', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_reusable_handoff_refresh_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    final docs = Directory('${root.path}/docs')..createSync(recursive: true);
    File(
      '${docs.path}/reusable_parsing_qa_mac_handoff_packet.json',
    ).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'primaryBranch': 'old-branch',
        'baselineCommit': 'old1234',
        'baselineCommitFull': 'old1234full',
        'baselineCommitLabel': 'old label',
        'scopeBoundaryPath': 'docs/reusable_parsing_qa_scope_boundary.md',
        'checkpointJsonPath': 'docs/reusable_parsing_qa_checkpoint.json',
        'checkpointMarkdownPath': 'docs/reusable_parsing_qa_checkpoint.md',
        'windowsCheckpointSyncCommand':
            'dart run tool/reusable_parsing_qa_handoff_sync.dart',
        'handoffMarkerPath': 'docs/reusable_parsing_qa_handoff_marker.md',
        'runbookPath': 'docs/reusable_parsing_qa_mac_runbook.md',
      }),
    );
    File(
      '${root.path}/build/parser_qa_pipeline/peh_core_measurement_gap.json',
    )
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'readyForMacMeasurementWave': true,
          'totalRemainingChecked': 38,
          'nextTradesByRemainingGap': ['hvac'],
          'tradeGaps': [
            {'trade': 'hvac', 'remainingChecked': 38},
          ],
        }),
      );
    File(
      '${root.path}/build/parser_qa_pipeline/peh_core_claim_readiness.json',
    )
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'readyToClaimNinetyPlus': false,
          'blockingFindings': ['trade_not_ready:hvac', 'mac_wave_not_merge_ready'],
          'nextActions': ['Keep the hvac Mac wave running.'],
        }),
      );
    File(
      '${root.path}/build/parser_qa_pipeline/peh_core_mac_handoff_packet.json',
    )
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'selectedTrades': ['hvac'],
          'inventoryExecutionBranch':
              'codex/inventory-parser-backup-20260702-2056',
          'inventoryExecutionCommit': 'deadbee',
          'measurementCommandCount': 2,
          'rollupCommandCount': 1,
          'measurementCommands': [
            {
              'trade': 'hvac',
              'command': [
                'dart',
                'run',
                'tool/work_supply_parser_qa_run_generated_fixtures.dart',
                '--fixture',
                'build/parser_qa_generated/work_supply_parser/hvac/residential/core/en-US/generated_fixtures.json',
              ],
            },
            {
              'trade': 'hvac',
              'command': [
                'dart',
                'run',
                'tool/work_supply_parser_qa_run_generated_fixtures.dart',
                '--fixture',
                'build/parser_qa_generated/work_supply_parser/hvac/residential/core/es-US/generated_fixtures.json',
              ],
            },
          ],
          'rollupCommands': [
            {
              'trade': 'hvac',
              'command': [
                'dart',
                'run',
                'tool/work_supply_parser_qa_generated_run_status.dart',
                '--output',
                'build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json',
              ],
            },
          ],
          'refreshCommand': [
            'dart',
            'run',
            'tool/work_supply_parser_qa_peh_core_post_mac_refresh.dart',
            '--root',
            '.',
            '--hvac-status',
            'build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json',
          ],
          'expectedOutputs': [
            'build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json',
            'build/parser_qa_pipeline/peh_core_mac_wave_status.json',
            'build/parser_qa_pipeline/peh_core_merged_status_rollup.json',
            'build/parser_qa_pipeline/peh_core_claim_readiness.json',
          ],
        }),
      );

    final stdout = _MemorySink();
    final exit = runReusableParsingQaHandoffRefresh(
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
        'Reusable parsing QA 2026-07-09 21:00 EDT: refresh handoff artifacts',
        '--updated-at',
        '2026-07-09 21:00 EDT',
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_REUSABLE_PARSING_HANDOFF_REFRESH'));

    final packet =
        jsonDecode(
              File('${docs.path}/reusable_parsing_qa_mac_handoff_packet.json')
                  .readAsStringSync(),
            )
            as Map<String, Object?>;
    final marker = File(
      '${docs.path}/reusable_parsing_qa_handoff_marker.md',
    ).readAsStringSync();
    final boundary = File(
      '${docs.path}/reusable_parsing_qa_scope_boundary.md',
    ).readAsStringSync();
    final runbook = File(
      '${docs.path}/reusable_parsing_qa_mac_runbook.md',
    ).readAsStringSync();
    final index = File(
      '${docs.path}/reusable_parsing_qa_handoff_index.md',
    ).readAsStringSync();

    expect(packet['baselineCommit'], 'abc1234');
    expect(packet['baselineCommitFull'], 'abc1234fullsha');
    expect(
      packet['baselineCommitLabel'],
      'Reusable parsing QA 2026-07-09 21:00 EDT: refresh handoff artifacts',
    );
    expect(packet['generatedAtEdt'], '2026-07-09 21:00 EDT');
    expect(
      packet['currentExecutionBranch'],
      'codex/inventory-parser-backup-20260702-2056',
    );
    expect(packet['currentExecutionCommit'], 'deadbee');
    expect(
      packet['scopeBoundaryPath'],
      'docs/reusable_parsing_qa_scope_boundary.md',
    );
    expect(
      packet['checkpointJsonPath'],
      'docs/reusable_parsing_qa_checkpoint.json',
    );
    expect(
      packet['checkpointMarkdownPath'],
      'docs/reusable_parsing_qa_checkpoint.md',
    );
    expect(
      '${packet['windowsCheckpointSyncCommand']}',
      contains('reusable_parsing_qa_handoff_sync.dart'),
    );
    expect(
      (packet['reusableFoundationPaths'] as List<Object?>),
      contains('test/support/parser_qa_platform/'),
    );
    expect(
      (packet['reusableFoundationPaths'] as List<Object?>),
      contains('tool/reusable_parsing_qa_handoff_sync.dart'),
    );
    expect(
      (packet['reusableFoundationPaths'] as List<Object?>),
      contains('tool/reusable_parsing_qa_handoff_summary.dart'),
    );
    expect(
      (packet['inventorySpecificWindowsPaths'] as List<Object?>),
      contains('test/support/work_supply_parser_qa/'),
    );
    expect(
      packet['artifactInputs'],
      isA<Map<String, Object?>>(),
    );
    expect(
      '${(packet['artifactInputs'] as Map<String, Object?>)['claimReadiness']}',
      'build/parser_qa_pipeline/peh_core_claim_readiness.json',
    );
    expect(
      '${(packet['currentMeasurementState'] as Map<String, Object?>)['nextTradeByGap']}',
      'hvac',
    );
    expect(
      '${(packet['currentMeasurementState'] as Map<String, Object?>)['totalRemainingChecked']}',
      '38',
    );
    expect(
      packet['claimBlockingFindings'].toString(),
      contains('trade_not_ready:hvac'),
    );
    expect(
      packet['claimNextActions'].toString(),
      contains('Keep the hvac Mac wave running.'),
    );
    expect(packet['selectedTrades'], ['hvac']);
    expect(packet['measurementCommandCount'], 2);
    expect(packet['rollupCommandCount'], 1);
    expect(
      packet['macMiniExpectedOutputs'],
      [
        'build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json',
        'build/parser_qa_pipeline/peh_core_mac_wave_status.json',
        'build/parser_qa_pipeline/peh_core_merged_status_rollup.json',
        'build/parser_qa_pipeline/peh_core_claim_readiness.json',
      ],
    );
    expect(
      '${(packet['macMiniNextCommands'] as List<Object?>).first}',
      contains('generated_fixtures'),
    );
    expect((packet['macMiniNextCommands'] as List<Object?>).length, 4);

    expect(marker, contains('Validated floor commit: `abc1234`'));
    expect(
      marker,
      contains('Companion scope boundary map:'),
    );
    expect(
      marker,
      contains('Companion next-action checkpoint:'),
    );
    expect(
      marker,
      contains('reusable_parsing_qa_handoff_sync.dart'),
    );
    expect(
      marker,
      contains('expectedLocalDocsRefreshDirty: true'),
    );
    expect(boundary, contains('Validated floor commit: `abc1234`'));
    expect(
      boundary,
      contains('## Reusable Parser QA Foundation'),
    );
    expect(
      boundary,
      contains('## Merchant Extraction Boundary'),
    );
    expect(
      boundary,
      contains('merchant-aware parser behavior'),
    );
    expect(
      runbook,
      contains('branch is at or after validated floor commit `abc1234`'),
    );
    expect(
      runbook,
      contains('docs/reusable_parsing_qa_scope_boundary.md'),
    );
    expect(
      runbook,
      contains('docs/reusable_parsing_qa_checkpoint.md'),
    );
    expect(
      runbook,
      contains('reusable_parsing_qa_handoff_summary.dart'),
    );
    expect(index, contains('- Validated floor commit: `abc1234`'));
    expect(index, contains('- Branch: `codex/reusable-parsing-qa-foundation`'));
    expect(index, contains('docs/reusable_parsing_qa_scope_boundary.md'));
    expect(index, contains('docs/reusable_parsing_qa_checkpoint.md'));
    expect(index, contains('reusable_parsing_qa_handoff_summary.dart'));
    expect(index, contains('expectedLocalDocsRefreshDirty: true'));
    expect(
      boundary,
      contains('tool/reusable_parsing_qa_handoff_summary.dart'),
    );
    expect(
      runbook,
      contains('Roll up the active Mac measurement wave results.'),
    );
    expect(
      runbook,
      contains('## Merchant Extraction Ownership'),
    );
    expect(
      runbook,
      contains('separate merchant-extraction buildout'),
    );
    expect(
      runbook,
      contains('expectedLocalDocsRefreshDirty: true'),
    );
    expect(
      runbook,
      contains('docs/reusable_parsing_qa_checkpoint.json'),
    );
    expect(
      runbook,
      isNot(contains('mac_electrical_core_generated_run_status_25.json')),
    );
    expect(
      boundary,
      isNot(contains('mac_electrical_core_generated_run_status_25.json')),
    );
  }, timeout: const Timeout(Duration(seconds: 10)));
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
