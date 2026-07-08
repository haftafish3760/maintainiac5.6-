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

    if (outputFile.existsSync()) {
      outputFile.deleteSync();
    }

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
    expect(text, contains('- Flutter devices snapshot: '));
    expect(text, contains('- ADB devices snapshot: '));
    expect(text, contains('- Xcode devices snapshot: '));

    outputFile.deleteSync();
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
    expect(script, contains('flutter devices'));
    expect(script, contains('adb devices -l'));
    expect(script, contains('xcrun xctrace list devices'));
    expect(script, contains('Refusing to overwrite existing result note'));
    expect(script, isNot(contains('flutter run')));
    expect(script, isNot(contains('flutter install')));
    expect(script, isNot(contains('adb shell input')));
    expect(script, isNot(contains('uiautomator')));
  });
}
