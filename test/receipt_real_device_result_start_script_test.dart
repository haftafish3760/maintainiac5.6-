import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('real-device result start script creates a structured run note', () async {
    final slug = 'script-test';
    final date = DateTime.now();
    final stamp =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final outputPath = 'docs/receipt_real_device_runs/$stamp-$slug.md';
    final outputFile = File(outputPath);
    File? snapshotSummaryFile;

    if (outputFile.existsSync()) {
      outputFile.deleteSync();
    }
    addTearDown(() {
      if (outputFile.existsSync()) {
        outputFile.deleteSync();
      }
      final summary = snapshotSummaryFile;
      if (summary != null && summary.existsSync()) {
        summary.parent.listSync().whereType<File>().forEach((file) {
          file.deleteSync();
        });
        summary.parent.deleteSync();
      }
    });

    final result = await Process.run('bash', [
      'tool/receipt_real_device_result_start.sh',
      slug,
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout.toString(), contains(outputPath));
    expect(outputFile.existsSync(), isTrue);

    final text = outputFile.readAsStringSync();
    expect(text, contains('## Session Metadata'));
    expect(text, contains('## Environment And Device Matrix'));
    expect(text, contains('- Date: '));
    expect(text, contains('- Branch: '));
    expect(text, contains('- Commit: '));
    expect(text, contains('- Workspace: `'));
    expect(text, contains('- Metadata snapshot summary: `'));
    expect(text, contains('- Flutter devices snapshot log: `'));
    expect(text, contains('- ADB devices snapshot log: `'));
    expect(text, contains('- Xcode devices snapshot log: `'));
    expect(text, contains('- Flutter devices snapshot: '));
    expect(text, contains('- ADB devices snapshot: '));
    expect(text, contains('- Xcode devices snapshot: '));
    expect(text, isNot(contains('Found 4 connected devices:')));
    expect(text, isNot(contains('Checking for wireless devices...')));
    expect(text, isNot(contains('robbie’s iPhone')));
    expect(
      text,
      contains('- Flutter devices snapshot: captured;'),
    );
    expect(
      text,
      contains('- Xcode devices snapshot: captured;'),
    );
    expect(
      text,
      isNot(contains('- Xcode devices snapshot: captured; inspect linked log `')),
    );

    final snapshotSummaryMatch = RegExp(
      r'- Metadata snapshot summary: `([^`]+)`',
    ).firstMatch(text);
    expect(snapshotSummaryMatch, isNotNull);

    final snapshotSummaryPath = snapshotSummaryMatch!.group(1)!;
    snapshotSummaryFile = File(snapshotSummaryPath);
    expect(snapshotSummaryFile.existsSync(), isTrue);
    expect(
      snapshotSummaryFile.readAsStringSync(),
      contains('purpose=metadata_only_no_install_no_ui_navigation'),
    );
    expect(
      RegExp(r'^- Metadata snapshot summary:', multiLine: true)
          .allMatches(text)
          .length,
      1,
    );
    expect(
      RegExp(r'^- Flutter devices snapshot log:', multiLine: true)
          .allMatches(text)
          .length,
      1,
    );
    expect(
      RegExp(r'^- ADB devices snapshot log:', multiLine: true)
          .allMatches(text)
          .length,
      1,
    );
    expect(
      RegExp(r'^- Xcode devices snapshot log:', multiLine: true)
          .allMatches(text)
          .length,
      1,
    );
  });

  test('real-device result start script stays metadata-only and non-interactive', () {
    final script = File(
      'tool/receipt_real_device_result_start.sh',
    ).readAsStringSync();

    expect(
      script,
      contains('Creates a privacy-safe real-device receipt-camera result note'),
    );
    expect(
      script,
      contains('This script records metadata only. It does not install, launch, tap,'),
    );
    expect(script, contains('docs/receipt_real_device_result_template.md'));
    expect(script, contains('docs/receipt_real_device_runs'));
    expect(script, contains('tool/receipt_camera_real_device_snapshot.sh'));
    expect(script, contains('summarize_log('));
    expect(script, contains('captured; inspect linked log'));
    expect(script, contains('captured; no devices listed'));
    expect(script, contains('missing snapshot log; inspect setup'));
    expect(script, contains('Refusing to overwrite existing result note'));
    expect(script, isNot(contains('flutter run')));
    expect(script, isNot(contains('flutter install')));
    expect(script, isNot(contains('adb shell input')));
    expect(script, isNot(contains('uiautomator')));
  });
}
