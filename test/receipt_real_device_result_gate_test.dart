import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('real-device result gate passes the active template', () async {
    final result = await Process.run('dart', [
      'tool/receipt_real_device_result_gate.dart',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout,
      contains('Receipt real-device result gate: template=ok'),
    );
  });

  test('real-device result template protects privacy and flow coverage', () {
    final template = File(
      'docs/receipt_real_device_result_template.md',
    ).readAsStringSync();

    expect(template, contains('## Session Metadata'));
    expect(template, contains('## Environment And Device Matrix'));
    expect(template, contains('- Metadata snapshot summary:'));
    expect(template, contains('- Flutter devices snapshot log:'));
    expect(template, contains('- ADB devices snapshot log:'));
    expect(template, contains('- Xcode devices snapshot log:'));
    expect(template, contains('## Flow Results'));
    expect(template, contains('### Flow 1: Single Photo Receipt'));
    expect(template, contains('### Flow 6: Interruption And Recovery'));
    expect(template, contains('## Failure Reports'));
    expect(template, contains('## Privacy And Diagnostics Check'));
    expect(template, contains('## Exit Summary'));
    expect(template, contains('Do not paste full receipt text.'));
    expect(template, contains('Do not paste receipt images into this note.'));
    expect(template, contains('mark it `NOT RUN`'));
    expect(template, contains('docs/receipt_real_device_runs/YYYY-MM-DD-device-batch.md'));
  });
}
