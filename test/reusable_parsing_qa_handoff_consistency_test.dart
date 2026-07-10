import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reusable parsing QA handoff files stay aligned', () {
    final marker = File(
      'docs/reusable_parsing_qa_handoff_marker.md',
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
      '- Current reusable-foundation commit: `',
    );
    final runbookCommit = _extractSingleLineValue(
      runbook,
      '2. Confirm the branch is at or after commit `',
    );
    final indexBranch = _extractSingleLineValue(index, '- Branch: `');
    final indexCommit = _extractSingleLineValue(index, '- Commit: `');

    expect(packet['primaryBranch'], markerBranch);
    expect(packet['primaryBranch'], indexBranch);
    expect(packet['baselineCommit'], markerCommit);
    expect(packet['baselineCommit'], runbookCommit);
    expect(packet['baselineCommit'], indexCommit);

    expect(
      index,
      contains('docs/reusable_parsing_qa_handoff_marker.md'),
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
      contains('Companion plain-English runbook:'),
    );
    expect(
      packet['runbookPath'],
      'docs/reusable_parsing_qa_mac_runbook.md',
    );
    expect(
      packet['handoffMarkerPath'],
      'docs/reusable_parsing_qa_handoff_marker.md',
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
