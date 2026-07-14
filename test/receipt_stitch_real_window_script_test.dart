import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory scratch;
  late File sourceImage;
  late File secondSourceImage;
  late String flutterPath;

  setUp(() async {
    scratch = await Directory.systemTemp.createTemp('receipt_real_window_');
    sourceImage = File('${scratch.path}/receipt.jpg');
    await sourceImage.writeAsString('receipt-source');
    secondSourceImage = File('${scratch.path}/receipt-next.jpg');
    await secondSourceImage.writeAsString('receipt-next-source');
    final bin = Directory('${scratch.path}/bin');
    await bin.create();
    final flutter = File('${bin.path}/flutter');
    await flutter.writeAsString('#!/usr/bin/env bash\nexit 0\n');
    await Process.run('chmod', ['+x', flutter.path]);
    flutterPath = flutter.path;
  });

  tearDown(() => scratch.delete(recursive: true));

  test('section-stack probe accepts an injectable Flutter command', () async {
    final result = await _runScript('tool/receipt_stitch_real_probe.sh', [
      sourceImage.path,
      secondSourceImage.path,
    ], flutterPath);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('Receipt stitch source integrity: PASS'));
    expect(await sourceImage.readAsString(), 'receipt-source');
    expect(await secondSourceImage.readAsString(), 'receipt-next-source');
  });

  test(
    'real-window scripts accept valid settings and preserve the source',
    () async {
      final probe = await _runScript(
        'tool/receipt_stitch_real_window_probe.sh',
        [sourceImage.path, '900', '620'],
        flutterPath,
      );
      expect(probe.exitCode, 0, reason: '${probe.stdout}\n${probe.stderr}');
      expect(probe.stdout, contains('Receipt stitch source integrity: PASS'));

      final matrix = await _runScript(
        'tool/receipt_stitch_real_window_matrix.sh',
        [sourceImage.path, '900:620'],
        flutterPath,
      );
      expect(matrix.exitCode, 0, reason: '${matrix.stdout}\n${matrix.stderr}');
      expect(matrix.stdout, contains('Receipt stitch source integrity: PASS'));
      expect(await sourceImage.readAsString(), 'receipt-source');
    },
  );

  test('real-window scripts reject malformed crop settings', () async {
    final badHeight = await _runScript(
      'tool/receipt_stitch_real_window_probe.sh',
      [sourceImage.path, 'wide'],
      flutterPath,
    );
    expect(badHeight.exitCode, 64);
    expect(
      badHeight.stderr,
      contains('Window height must be a positive integer'),
    );

    final badMatrix = await _runScript(
      'tool/receipt_stitch_real_window_matrix.sh',
      [sourceImage.path, '900:900'],
      flutterPath,
    );
    expect(badMatrix.exitCode, 64);
    expect(badMatrix.stderr, contains('stride less than height'));
  });
}

Future<ProcessResult> _runScript(
  String script,
  List<String> arguments,
  String flutterPath,
) {
  return Process.run(
    'bash',
    [script, ...arguments],
    environment: {'FLUTTER_BIN': flutterPath},
    workingDirectory: Directory.current.path,
  );
}
