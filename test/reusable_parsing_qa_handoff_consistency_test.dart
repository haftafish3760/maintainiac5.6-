import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reusable parsing QA handoff files stay aligned', () {
    final marker = File(
      'docs/reusable_parsing_qa_handoff_marker.md',
    ).readAsStringSync();
    final boundary = File(
      'docs/reusable_parsing_qa_scope_boundary.md',
    ).readAsStringSync();
    final checkpoint = File(
      'docs/reusable_parsing_qa_checkpoint.md',
    ).readAsStringSync();
    final packet = jsonDecode(
      File('docs/reusable_parsing_qa_mac_handoff_packet.json')
          .readAsStringSync(),
    ) as Map<String, Object?>;
    final runbook = File(
      'docs/reusable_parsing_qa_mac_runbook.md',
    ).readAsStringSync();
    final index = File(
      'docs/reusable_parsing_qa_handoff_index.md',
    ).readAsStringSync();

    final markerBranch = _extractSingleLineValue(
      marker,
      '- Primary reusable branch: `',
    );
    final markerCommit = _extractSingleLineValue(
      marker,
      '- Validated floor commit: `',
    );
    final runbookCommit = _extractSingleLineValue(
      runbook,
      '2. Confirm the branch is at or after validated floor commit `',
    );
    final indexBranch = _extractSingleLineValue(index, '- Branch: `');
    final indexCommit = _extractSingleLineValue(
      index,
      '- Validated floor commit: `',
    );

    expect(packet['primaryBranch'], markerBranch);
    expect(packet['primaryBranch'], indexBranch);
    expect(packet['baselineCommit'], markerCommit);
    expect(packet['baselineCommit'], runbookCommit);
    expect(packet['baselineCommit'], indexCommit);
    expect(packet['currentExecutionBranch'], isNotEmpty);
    expect(packet['currentExecutionCommit'], isNotEmpty);

    expect(
      index,
      contains('docs/reusable_parsing_qa_handoff_marker.md'),
    );
    expect(
      index,
      contains('docs/reusable_parsing_qa_scope_boundary.md'),
    );
    expect(
      index,
      contains('docs/reusable_parsing_qa_checkpoint.md'),
    );
    expect(
      index,
      contains('docs/reusable_parsing_qa_mac_runbook.md'),
    );
    expect(
      index,
      contains('docs/reusable_parsing_qa_mac_handoff_packet.json'),
    );

    expect(
      marker,
      contains('Companion machine-readable packet:'),
    );
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
      contains('Companion plain-English runbook:'),
    );
    expect(
      boundary,
      contains('Validated floor commit: `$markerCommit`'),
    );
    expect(
      boundary,
      contains('## Reusable Parser QA Foundation'),
    );
    expect(
      boundary,
      contains('## Inventory-Specific Windows Ownership'),
    );
    expect(
      boundary,
      contains('## Mac Mini Measurement Outputs'),
    );
    expect(
      checkpoint,
      contains('## Windows Next'),
    );
    expect(
      checkpoint,
      contains('## Mac Mini Next'),
    );
    expect(
      checkpoint,
      contains('Windows execution commit: `'),
    );
    expect(
      packet['runbookPath'],
      'docs/reusable_parsing_qa_mac_runbook.md',
    );
    expect(
      packet['handoffMarkerPath'],
      'docs/reusable_parsing_qa_handoff_marker.md',
    );
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
      (packet['inventorySpecificWindowsPaths'] as List<Object?>),
      contains('test/support/work_supply_parser_qa/'),
    );
    expect(
      (packet['macMiniExpectedOutputs'] as List<Object?>),
      contains('build/parser_qa_pipeline/peh_core_claim_readiness.json'),
    );
    expect(
      marker,
      contains('Treat the branch tip as authoritative.'),
    );
    expect(
      runbook,
      contains('validated floor commit'),
    );
    expect(
      index,
      contains('branch tip is authoritative'),
    );
  });
}

String _extractSingleLineValue(String source, String prefix) {
  final start = source.indexOf(prefix);
  expect(start, isNot(-1), reason: 'Missing prefix: $prefix');
  final valueStart = start + prefix.length;
  final valueEnd = source.indexOf('`', valueStart);
  expect(valueEnd, isNot(-1), reason: 'Missing closing backtick for $prefix');
  return source.substring(valueStart, valueEnd);
}
