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

    Process.runSync('git', ['init'], workingDirectory: root.path);
    Process.runSync(
      'git',
      ['config', 'user.email', 'qa@example.com'],
      workingDirectory: root.path,
    );
    Process.runSync(
      'git',
      ['config', 'user.name', 'QA Bot'],
      workingDirectory: root.path,
    );
    File('${root.path}/README.txt').writeAsStringSync('brief fixture');
    File('${root.path}/.gitignore').writeAsStringSync('build/\n');
    Process.runSync('git', ['add', '.'], workingDirectory: root.path);
    Process.runSync('git', ['commit', '-m', 'fixture'], workingDirectory: root.path);
    Process.runSync(
      'git',
      ['checkout', '-B', 'codex/inventory-parser-backup-20260702-2056'],
      workingDirectory: root.path,
    );

    final headShort =
        Process.runSync(
          'git',
          ['rev-parse', '--short', 'HEAD'],
          workingDirectory: root.path,
        ).stdout
            .toString()
            .trim();

    _writeJson('${root.path}/docs/reusable_parsing_qa_checkpoint.json', {
      'primaryBranch': 'codex/reusable-parsing-qa-foundation',
      'validatedFloorCommit': '8e9771d',
      'validatedFloorLabel':
          'Reusable parsing QA 2026-07-09 09:20 PM EDT: relax stale packet assertion',
      'windowsWorkingBranch': 'codex/inventory-parser-backup-20260702-2056',
      'windowsExecutionCommit': headShort,
      'readyForMacMeasurementWave': true,
      'readyToClaimNinetyPlus': false,
      'nextTradesByRemainingGap': ['hvac'],
      'totalRemainingChecked': 38,
      'expectedLocalDocsRefreshFiles': [
        'docs/reusable_parsing_qa_checkpoint.json',
        'docs/reusable_parsing_qa_checkpoint.md',
        'docs/reusable_parsing_qa_handoff_index.md',
        'docs/reusable_parsing_qa_handoff_marker.md',
        'docs/reusable_parsing_qa_mac_handoff_packet.json',
        'docs/reusable_parsing_qa_mac_runbook.md',
        'docs/reusable_parsing_qa_scope_boundary.md',
      ],
      'generatedAtEdt': '2026-07-09 11:25 PM EDT',
    });
    File('${root.path}/docs/reusable_parsing_qa_checkpoint.md')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('''
# Reusable Parsing QA Checkpoint

## Windows Next

- Keep Windows ownership on inventory-specific Work Supplies parser/code hardening.

## Mac Mini Next

- Run the Mac PEH measurement wave commands from the packet.

## First Mac Measurement Command

`dart run tool/work_supply_parser_qa_run_generated_fixtures.dart`
''');
    File('${root.path}/docs/reusable_parsing_qa_handoff_marker.md')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('''
# Reusable Parsing QA Handoff Marker

- Primary reusable branch: `codex/reusable-parsing-qa-foundation`
- Validated floor commit: `8e9771d`
- Companion machine-readable packet: `docs/reusable_parsing_qa_mac_handoff_packet.json`
- Companion scope boundary map: `docs/reusable_parsing_qa_scope_boundary.md`
- Companion next-action checkpoint: `docs/reusable_parsing_qa_checkpoint.md`
- Companion plain-English runbook: `docs/reusable_parsing_qa_mac_runbook.md`
- Treat the branch tip as authoritative.
''');
    File('${root.path}/docs/reusable_parsing_qa_handoff_index.md')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('''
# Reusable Parsing QA Handoff Index

- Branch: `codex/reusable-parsing-qa-foundation`
- Validated floor commit: `8e9771d`
- The branch tip is authoritative.
- docs/reusable_parsing_qa_handoff_marker.md
- docs/reusable_parsing_qa_scope_boundary.md
- docs/reusable_parsing_qa_checkpoint.md
- docs/reusable_parsing_qa_mac_runbook.md
- docs/reusable_parsing_qa_mac_handoff_packet.json
''');
    File('${root.path}/docs/reusable_parsing_qa_scope_boundary.md')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('''
# Reusable Parsing QA Scope Boundary

Validated floor commit: `8e9771d`

## Reusable Parser QA Foundation

- `test/support/parser_qa_platform/`

## Inventory-Specific Windows Ownership

- `test/support/work_supply_parser_qa/`

## Mac Mini Measurement Outputs

- `build/parser_qa_pipeline/peh_core_claim_readiness.json`
''');
    File('${root.path}/docs/reusable_parsing_qa_mac_runbook.md')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('''
# Reusable Parsing QA Mac Mini Runbook

2. Confirm the branch is at or after validated floor commit `8e9771d`.
7. `dart run tool/reusable_parsing_qa_handoff_status.dart --root .`
8. `dart run tool/reusable_parsing_qa_handoff_summary.dart --root .`
9. `dart run tool/reusable_parsing_qa_mac_handoff_brief.dart --root .`
''');

    _writeJson('${root.path}/docs/reusable_parsing_qa_mac_handoff_packet.json', {
      'primaryBranch': 'codex/reusable-parsing-qa-foundation',
      'baselineCommit': '8e9771d',
      'baselineCommitLabel':
          'Reusable parsing QA 2026-07-09 09:20 PM EDT: relax stale packet assertion',
      'scopeBoundaryPath': 'docs/reusable_parsing_qa_scope_boundary.md',
      'checkpointJsonPath': 'docs/reusable_parsing_qa_checkpoint.json',
      'checkpointMarkdownPath': 'docs/reusable_parsing_qa_checkpoint.md',
      'windowsCheckpointSyncCommand':
          'dart run tool/reusable_parsing_qa_handoff_sync.dart --root .',
      'runbookPath': 'docs/reusable_parsing_qa_mac_runbook.md',
      'handoffMarkerPath': 'docs/reusable_parsing_qa_handoff_marker.md',
      'artifactInputs': {
        'claimReadiness': 'build/parser_qa_pipeline/peh_core_claim_readiness.json',
      },
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
        'nextTradesByRemainingGap': ['hvac'],
        'totalRemainingChecked': 38,
      },
    });
    _writeJson('${root.path}/build/parser_qa_pipeline/peh_core_mac_handoff_packet.json', {
      'reusableBaselineBranch': 'codex/reusable-parsing-qa-foundation',
      'reusableValidatedFloorCommit': '8e9771d',
      'inventoryExecutionBranch': 'codex/inventory-parser-backup-20260702-2056',
      'inventoryExecutionCommit': headShort,
      'branch': 'codex/inventory-parser-backup-20260702-2056',
      'commit': headShort,
      'readyForMacMeasurementWave': true,
      'readyToClaimNinetyPlus': false,
      'totalRemainingChecked': 38,
      'nextTradesByRemainingGap': ['hvac'],
    });
    final script = File(
      '${root.path}/build/parser_qa_pipeline/peh_core_mac_handoff.sh',
    )..parent.createSync(recursive: true);
    script.writeAsStringSync('''
#!/usr/bin/env bash
# Branch: codex/inventory-parser-backup-20260702-2056
# Commit: $headShort
''');

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
    expect(payload['windowsExecutionCommit'], headShort);
    expect(payload['currentBranchHeadCommit'], isNotEmpty);
    expect(payload['currentBranchHeadCommitFull'], isNotEmpty);
    expect(payload['docsOnlyExecutionDriftAccepted'], isFalse);
    expect(payload['statusExit'], 0);
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
