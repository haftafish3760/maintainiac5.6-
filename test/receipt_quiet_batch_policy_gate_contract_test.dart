import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quiet batch policy gate protects non-monitoring workflow', () {
    final gate = File(
      'tool/receipt_quiet_batch_policy_gate.dart',
    ).readAsStringSync();
    final fastGate = File('tool/receipt_fast_guard_gate.sh').readAsStringSync();

    expect(gate, contains('tool/receipt_quiet_batch.sh'));
    expect(gate, contains('tool/receipt_quiet_batch_status.sh'));
    expect(gate, contains('tool/receipt_start_quiet_quality_gate.sh'));
    expect(gate, contains('runner_started'));
    expect(gate, contains('runner_finished'));
    expect(gate, contains('args_literal="args=("'));
    expect(gate, contains(r'"\${args[@]}"'));
    expect(gate, contains('screen -dmS'));
    expect(gate, contains('launchctl submit'));
    expect(
      gate,
      contains('sed \'\' tool/receipt_quality_gate.sh > "\$payload"'),
    );
    expect(
      gate,
      contains('sed \'\' tool/receipt_ocr_pipeline_run.sh > "\$payload"'),
    );
    expect(gate, contains('command_line="/bin/bash \$(printf'));
    expect(gate, contains('/bin/bash -lc "\$command_line"'));
    expect(gate, contains('rm -rf "\$root"'));
    expect(gate, contains('status helper must not read or stream run.log'));
    expect(gate, contains('quality gate launcher must use quiet batch'));
    expect(gate, contains('quality gate launcher must not stream logs'));
    expect(
      fastGate,
      contains('dart tool/receipt_quiet_batch_policy_gate.dart'),
    );
    expect(fastGate, contains('tool/receipt_quiet_batch_policy_gate.dart'));
  });
}
