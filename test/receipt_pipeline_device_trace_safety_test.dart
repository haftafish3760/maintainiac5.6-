import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt trace requires an explicit device serial', () async {
    final result = await Process.run('bash', [
      'tool/receipt_pipeline_device_trace.sh',
    ]);

    expect(result.exitCode, 64);
    expect(result.stderr, contains('never guesses or defaults a phone'));
  });

  test('receipt trace refuses a connected non-S24 phone', () async {
    final fixture = await _FakeAdbFixture.create(model: 'SM-S938U');
    addTearDown(fixture.dispose);

    final result = await Process.run(
      'bash',
      ['tool/receipt_pipeline_device_trace.sh', 'test-serial'],
      environment: {...Platform.environment, 'ADB': fixture.path},
    );

    expect(result.exitCode, 1);
    expect(result.stderr, contains('Refusing receipt pipeline trace'));
    expect(result.stderr, contains('SM-S938U'));
    expect(await fixture.log.readAsString(), isNot(contains('pidof')));
  });

  test('receipt trace permits only the verified S24 target', () async {
    final fixture = await _FakeAdbFixture.create(model: 'SM-S928U');
    addTearDown(fixture.dispose);

    final result = await Process.run(
      'bash',
      ['tool/receipt_pipeline_device_trace.sh', 'test-serial'],
      environment: {...Platform.environment, 'ADB': fixture.path},
    );

    expect(result.exitCode, 0);
    expect(result.stdout, contains('MAINTAINIAC_RECEIPT_TRACE'));
    expect(await fixture.log.readAsString(), contains('pidof'));
  });
}

class _FakeAdbFixture {
  const _FakeAdbFixture(this.directory, this.path, this.log);

  final Directory directory;
  final String path;
  final File log;

  static Future<_FakeAdbFixture> create({required String model}) async {
    final directory = await Directory.systemTemp.createTemp(
      'receipt-trace-adb-',
    );
    final log = File('${directory.path}/calls.log');
    final executable = File('${directory.path}/adb');
    await executable.writeAsString('''#!/usr/bin/env bash
echo "\$*" >> "${log.path}"
if [[ "\$1" == "devices" ]]; then
  printf 'List of devices attached\\ntest-serial\\tdevice\\n'
elif [[ "\$*" == *"getprop ro.product.model"* ]]; then
  echo "$model"
elif [[ "\$*" == *"pidof -s com.maintainiac"* ]]; then
  echo 1234
elif [[ "\$*" == *"logcat -d"* ]]; then
  echo 'MAINTAINIAC_RECEIPT_TRACE stitch_status=stitched'
fi
''');
    await Process.run('chmod', ['+x', executable.path]);
    return _FakeAdbFixture(directory, executable.path, log);
  }

  Future<void> dispose() => directory.delete(recursive: true);
}
