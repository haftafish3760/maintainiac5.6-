import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/reusable_parsing_qa_handoff_status.dart';

void main() {
  test('handoff status reports aligned docs with head ahead of validated floor', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_reusable_handoff_status_',
    );
    addTearDown(() => root.deleteSync(recursive: true));

    _writeHandoffFixture(
      root,
      branch: 'codex/reusable-parsing-qa-foundation',
      validatedFloorCommit: 'abc1234',
      validatedFloorLabel:
          'Reusable parsing QA 2026-07-09 20:17 EDT: validated floor',
    );

    final stdout = _MemorySink();
    final stderr = _MemorySink();
    final exit = runReusableParsingQaHandoffStatus(
      ['--root', root.path],
      stdout: stdout,
      stderr: stderr,
    );

    expect(exit, 0);
    expect(stderr.content, isEmpty);

    final payload = _extractJsonPayload(stdout.content);
    expect(payload['primaryBranch'], 'codex/reusable-parsing-qa-foundation');
    expect(payload['validatedFloorCommit'], 'abc1234');
    expect(
      payload['validatedFloorLabel'],
      'Reusable parsing QA 2026-07-09 20:17 EDT: validated floor',
    );
    expect(payload['docsAligned'], isTrue);
    expect(payload['branchTipAheadOfValidatedFloor'], isTrue);
    expect(payload['currentBranch'], isNotEmpty);
    expect(payload['headCommit'], isNotEmpty);
    expect(
      payload['refreshCommand'],
      'dart run tool/reusable_parsing_qa_handoff_refresh.dart',
    );
    expect(payload['boundaryPath'], contains('reusable_parsing_qa_scope_boundary.md'));
    expect(payload['checkpointPath'], contains('reusable_parsing_qa_checkpoint.md'));
  });

  test('handoff status fails when marker and packet drift apart', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_reusable_handoff_status_drift_',
    );
    addTearDown(() => root.deleteSync(recursive: true));

    _writeHandoffFixture(
      root,
      branch: 'codex/reusable-parsing-qa-foundation',
      validatedFloorCommit: 'abc1234',
      validatedFloorLabel:
          'Reusable parsing QA 2026-07-09 20:17 EDT: validated floor',
    );

    final marker = File(
      '${root.path}/docs/reusable_parsing_qa_handoff_marker.md',
    );
    marker.writeAsStringSync(
      marker.readAsStringSync().replaceFirst('abc1234', 'zzz9999'),
    );

    final stdout = _MemorySink();
    final stderr = _MemorySink();
    final exit = runReusableParsingQaHandoffStatus(
      ['--root', root.path],
      stdout: stdout,
      stderr: stderr,
    );

    expect(exit, 1);
    expect(stderr.content, isEmpty);

    final payload = _extractJsonPayload(stdout.content);
    expect(payload['docsAligned'], isFalse);
    expect(payload['validatedFloorCommit'], 'abc1234');
  });
}

Map<String, Object?> _extractJsonPayload(String stdout) {
  const prefix = 'QA_REUSABLE_PARSING_HANDOFF_STATUS ';
  expect(stdout, contains(prefix));
  final start = stdout.indexOf(prefix);
  final jsonText = stdout.substring(start + prefix.length).trim();
  return jsonDecode(jsonText) as Map<String, Object?>;
}

void _writeHandoffFixture(
  Directory root, {
  required String branch,
  required String validatedFloorCommit,
  required String validatedFloorLabel,
}) {
  final docs = Directory('${root.path}/docs')..createSync(recursive: true);

  File('${docs.path}/reusable_parsing_qa_handoff_index.md').writeAsStringSync('''
# Reusable Parsing QA Handoff Index

- Branch: `$branch`
- Validated floor commit: `$validatedFloorCommit`
- The branch tip is authoritative once the Mac Mini confirms it is at or after the validated floor commit.
- Marker: `docs/reusable_parsing_qa_handoff_marker.md`
- Scope boundary: `docs/reusable_parsing_qa_scope_boundary.md`
- Runbook: `docs/reusable_parsing_qa_mac_runbook.md`
- Packet: `docs/reusable_parsing_qa_mac_handoff_packet.json`
''');

  File('${docs.path}/reusable_parsing_qa_handoff_marker.md').writeAsStringSync('''
# Reusable Parsing QA Handoff Marker

- Primary reusable branch: `$branch`
- Validated floor commit: `$validatedFloorCommit`
- Companion machine-readable packet: `docs/reusable_parsing_qa_mac_handoff_packet.json`
- Companion scope boundary map: `docs/reusable_parsing_qa_scope_boundary.md`
- Companion plain-English runbook: `docs/reusable_parsing_qa_mac_runbook.md`
- Treat the branch tip as authoritative.
''');

  File('${docs.path}/reusable_parsing_qa_scope_boundary.md').writeAsStringSync('''
# Reusable Parsing QA Scope Boundary

- Branch: `$branch`
- Validated floor commit: `$validatedFloorCommit`

## Reusable Parser QA Foundation

- `test/support/parser_qa_platform/`

## Inventory-Specific Windows Ownership

- `test/support/work_supply_parser_qa/`

## Mac Mini Measurement Outputs

- `build/parser_qa_pipeline/peh_core_claim_readiness.json`
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

1. Checkout `$branch`.
2. Confirm the branch is at or after validated floor commit `$validatedFloorCommit`.
3. Read `docs/reusable_parsing_qa_scope_boundary.md`.
4. Read `docs/reusable_parsing_qa_checkpoint.md`.
''');

  File('${docs.path}/reusable_parsing_qa_mac_handoff_packet.json')
      .writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'primaryBranch': branch,
          'baselineCommit': validatedFloorCommit,
          'baselineCommitLabel': validatedFloorLabel,
          'scopeBoundaryPath': 'docs/reusable_parsing_qa_scope_boundary.md',
          'checkpointJsonPath': 'docs/reusable_parsing_qa_checkpoint.json',
          'checkpointMarkdownPath': 'docs/reusable_parsing_qa_checkpoint.md',
          'windowsCheckpointSyncCommand':
              'dart run tool/reusable_parsing_qa_handoff_sync.dart --root .',
          'runbookPath': 'docs/reusable_parsing_qa_mac_runbook.md',
          'handoffMarkerPath': 'docs/reusable_parsing_qa_handoff_marker.md',
        }),
      );
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
