import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/reusable_parsing_qa_handoff_summary.dart';

void main() {
  test('handoff summary reports a clean handoff with explicit blockers', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_reusable_handoff_summary_',
    );
    addTearDown(() => root.deleteSync(recursive: true));

    _writeHandoffFixture(root);

    final stdout = _MemorySink();
    final stderr = _MemorySink();
    final exit = runReusableParsingQaHandoffSummary(
      ['--root', root.path],
      stdout: stdout,
      stderr: stderr,
    );

    expect(exit, 0);
    expect(stderr.content, isEmpty);

    final payload = _extractJsonPayload(stdout.content);
    expect(payload['handoffClean'], isTrue);
    expect(payload['docsAligned'], isTrue);
    expect(payload['parityOk'], isTrue);
    expect(payload['totalRemainingChecked'], 38);
    expect(payload['nextTradesByRemainingGap'].toString(), contains('hvac'));
    expect(payload['claimBlockingFindings'].toString(), contains('trade_not_ready:hvac'));
    expect(payload['measurementCommandCount'], 4);
  });
}

Map<String, Object?> _extractJsonPayload(String stdout) {
  const prefix = 'QA_REUSABLE_PARSING_HANDOFF_SUMMARY ';
  expect(stdout, contains(prefix));
  final start = stdout.indexOf(prefix);
  final jsonText = stdout.substring(start + prefix.length).trim();
  return jsonDecode(jsonText) as Map<String, Object?>;
}

void _writeHandoffFixture(Directory root) {
  final docs = Directory('${root.path}/docs')..createSync(recursive: true);

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
  File('${root.path}/README.txt').writeAsStringSync('handoff fixture');
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

  File('${docs.path}/reusable_parsing_qa_handoff_index.md').writeAsStringSync('''
# Reusable Parsing QA Handoff Index

- Branch: `codex/reusable-parsing-qa-foundation`
- Validated floor commit: `abc1234`
- Scope boundary: `docs/reusable_parsing_qa_scope_boundary.md`
''');

  File('${docs.path}/reusable_parsing_qa_handoff_marker.md').writeAsStringSync('''
# Reusable Parsing QA Handoff Marker

- Primary reusable branch: `codex/reusable-parsing-qa-foundation`
- Validated floor commit: `abc1234`
''');

  File('${docs.path}/reusable_parsing_qa_scope_boundary.md').writeAsStringSync('''
# Reusable Parsing QA Scope Boundary

Validated floor commit: `abc1234`
''');

  File('${docs.path}/reusable_parsing_qa_checkpoint.md').writeAsStringSync('''
# Reusable Parsing QA Checkpoint

## Windows Next

- Keep Windows ownership on inventory-specific Work Supplies parser/code hardening.

## Mac Mini Next

- Run the Mac PEH measurement wave commands from the packet.
''');

  File('${docs.path}/reusable_parsing_qa_mac_runbook.md').writeAsStringSync('''
# Reusable Parsing QA Mac Runbook

2. Confirm the branch is at or after validated floor commit `abc1234`.
''');

  _writeJson('${docs.path}/reusable_parsing_qa_checkpoint.json', {
    'primaryBranch': 'codex/reusable-parsing-qa-foundation',
    'validatedFloorCommit': 'abc1234',
    'validatedFloorLabel': 'Reusable parsing QA validated floor',
    'windowsWorkingBranch': 'codex/inventory-parser-backup-20260702-2056',
    'readyForMacMeasurementWave': true,
    'readyToClaimNinetyPlus': false,
    'totalRemainingChecked': 38,
    'nextTradesByRemainingGap': ['hvac'],
  });

  _writeJson('${docs.path}/reusable_parsing_qa_mac_handoff_packet.json', {
    'primaryBranch': 'codex/reusable-parsing-qa-foundation',
    'baselineCommit': 'abc1234',
    'baselineCommitLabel': 'Reusable parsing QA validated floor',
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
    'currentMeasurementState': {
      'nextTradeByGap': 'hvac',
      'nextTradesByRemainingGap': ['hvac'],
      'totalRemainingChecked': 38,
    },
    'claimBlockingFindings': ['trade_not_ready:hvac'],
    'claimNextActions': ['Keep the hvac Mac wave running.'],
    'macMiniNextCommands': [
      ['dart', 'run', 'tool/work_supply_parser_qa_run_generated_fixtures.dart'],
    ],
  });

  _writeJson('${root.path}/build/parser_qa_pipeline/peh_core_mac_handoff_packet.json', {
    'reusableBaselineBranch': 'codex/reusable-parsing-qa-foundation',
    'reusableValidatedFloorCommit': 'abc1234',
    'inventoryExecutionBranch': 'codex/inventory-parser-backup-20260702-2056',
    'inventoryExecutionCommit': headShort,
    'branch': 'codex/inventory-parser-backup-20260702-2056',
    'commit': headShort,
    'readyForMacMeasurementWave': true,
    'readyToClaimNinetyPlus': false,
    'totalRemainingChecked': 38,
    'nextTradesByRemainingGap': ['hvac'],
    'claimBlockingFindings': ['trade_not_ready:hvac'],
    'measurementCommandCount': 4,
    'rollupCommandCount': 2,
  });

  final script = File(
    '${root.path}/build/parser_qa_pipeline/peh_core_mac_handoff.sh',
  )..parent.createSync(recursive: true);
  script.writeAsStringSync('''
#!/usr/bin/env bash
# Branch: codex/inventory-parser-backup-20260702-2056
# Commit: $headShort
''');
}

void _writeJson(String path, Map<String, Object?> value) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(value));
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
