import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('real-device result gate passes the active template', () async {
    final runDir = await Directory.systemTemp.createTemp(
      'receipt_real_device_gate_empty_',
    );
    addTearDown(() async {
      if (runDir.existsSync()) {
        await runDir.delete(recursive: true);
      }
    });

    final result = await Process.run('dart', [
      'tool/receipt_real_device_result_gate.dart',
    ], environment: {
      'RECEIPT_REAL_DEVICE_RUNS_DIR': runDir.path,
    });

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

  test('real-device result gate rejects run notes with missing snapshot files', () async {
    final runDir = await Directory.systemTemp.createTemp(
      'receipt_real_device_gate_missing_',
    );
    addTearDown(() async {
      if (runDir.existsSync()) {
        await runDir.delete(recursive: true);
      }
    });

    final runFile = File('${runDir.path}/9999-12-31-missing-snapshot-test.md');
    runFile.writeAsStringSync(_runNote(
      metadataSummary: '/tmp/does-not-exist-summary.txt',
      flutterLog: '/tmp/does-not-exist-flutter.txt',
      adbLog: '/tmp/does-not-exist-adb.txt',
      xcodeLog: '/tmp/does-not-exist-xcode.txt',
    ));

    final result = await Process.run('dart', [
      'tool/receipt_real_device_result_gate.dart',
    ], environment: {
      'RECEIPT_REAL_DEVICE_RUNS_DIR': runDir.path,
    });

    expect(result.exitCode, 1);
    expect(
      result.stderr.toString(),
      contains('points to a missing snapshot file for Metadata snapshot summary'),
    );
  });

  test('real-device result gate accepts run notes with existing snapshot files', () async {
    final runDir = await Directory.systemTemp.createTemp(
      'receipt_real_device_gate_present_',
    );
    addTearDown(() async {
      if (runDir.existsSync()) {
        await runDir.delete(recursive: true);
      }
    });

    final tempDir = await Directory.systemTemp.createTemp(
      'receipt_real_device_gate_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final summary = File('${tempDir.path}/summary.txt')..writeAsStringSync('ok');
    final flutter = File('${tempDir.path}/flutter_devices.txt')
      ..writeAsStringSync('ok');
    final adb = File('${tempDir.path}/adb_devices.txt')..writeAsStringSync('ok');
    final xcode = File('${tempDir.path}/xcrun_devices.txt')
      ..writeAsStringSync('ok');

    final runFile = File('${runDir.path}/9999-12-31-existing-snapshot-test.md');
    runFile.writeAsStringSync(_runNote(
      metadataSummary: summary.path,
      flutterLog: flutter.path,
      adbLog: adb.path,
      xcodeLog: xcode.path,
    ));

    final result = await Process.run('dart', [
      'tool/receipt_real_device_result_gate.dart',
    ], environment: {
      'RECEIPT_REAL_DEVICE_RUNS_DIR': runDir.path,
    });

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains('Receipt real-device result gate: template=ok'),
    );
  });
}

String _runNote({
  required String metadataSummary,
  required String flutterLog,
  required String adbLog,
  required String xcodeLog,
}) {
  return '''
# Receipt Real-Device Result Template

## Session Metadata

- Date: TEST
- Branch: TEST
- Commit: TEST
- Build type: TEST
- Tester: TEST
- Devices: TEST
- Receipt set: TEST

## Environment And Device Matrix

- Metadata snapshot summary: `$metadataSummary`
- Flutter devices snapshot log: `$flutterLog`
- ADB devices snapshot log: `$adbLog`
- Xcode devices snapshot log: `$xcodeLog`

- Older Android: NOT RUN
- Current Android: NOT RUN
- Additional Android: NOT RUN
- iPhone: NOT RUN

## Flow Results

### Flow 1: Single Photo Receipt
- Status: NOT RUN

### Flow 2: Long Receipt Multi-Photo
- Status: NOT RUN

### Flow 3: Save-Space Preview
- Status: NOT RUN

### Flow 4: App-Assisted Filled Receipt Review
- Status: NOT RUN

### Flow 5: Manual Or No-Assist Receipt
- Status: NOT RUN

### Flow 6: Interruption And Recovery
- Status: NOT RUN

## Failure Reports

- None.

## Privacy And Diagnostics Check

- Help Improve Receipt Camera defaulted off: NOT RUN

## Exit Summary

- Remaining risks: NOT RUN
''';
}
