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
        'handoffMarkerPath': 'docs/reusable_parsing_qa_handoff_marker.md',
        'runbookPath': 'docs/reusable_parsing_qa_mac_runbook.md',
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
      (packet['reusableFoundationPaths'] as List<Object?>),
      contains('test/support/parser_qa_platform/'),
    );
    expect(
      (packet['inventorySpecificWindowsPaths'] as List<Object?>),
      contains('test/support/work_supply_parser_qa/'),
    );

    expect(marker, contains('Validated floor commit: `abc1234`'));
    expect(
      marker,
      contains('Companion scope boundary map:'),
    );
    expect(
      marker,
      contains('Companion next-action checkpoint:'),
    );
    expect(boundary, contains('Validated floor commit: `abc1234`'));
    expect(
      boundary,
      contains('## Reusable Parser QA Foundation'),
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
    expect(index, contains('- Validated floor commit: `abc1234`'));
    expect(index, contains('- Branch: `codex/reusable-parsing-qa-foundation`'));
    expect(index, contains('docs/reusable_parsing_qa_scope_boundary.md'));
    expect(index, contains('docs/reusable_parsing_qa_checkpoint.md'));
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
