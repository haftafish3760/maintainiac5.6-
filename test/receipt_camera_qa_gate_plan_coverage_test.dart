import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('camera QA printed plans only reference existing tests', () async {
    final missingPaths = <String>[];

    for (final mode in [
      'phase2',
      'phase3',
      'phase4',
      'phase5',
      'phase6',
      'phase7',
      'quick',
      'stitch',
      'milestone',
      'full',
    ]) {
      final result = await Process.run('bash', [
        'tool/receipt_camera_qa_gate.sh',
        '--print-plan',
        mode,
      ]);
      expect(result.exitCode, 0, reason: result.stderr.toString());

      final lines = result.stdout
          .toString()
          .split('\n')
          .where(
            (line) =>
                line.startsWith('phase2 ') ||
                line.startsWith('phase3 ') ||
                line.startsWith('phase4 ') ||
                line.startsWith('phase5 ') ||
                line.startsWith('phase6 ') ||
                line.startsWith('phase7 ') ||
                line.startsWith('quick ') ||
                line.startsWith('stitch ') ||
                line.startsWith('milestone ') ||
                line.startsWith('full '),
          );
      for (final line in lines) {
        final path = line.split(' ').last;
        if (!File(path).existsSync()) {
          missingPaths.add('$mode: $path');
        }
      }
    }

    expect(missingPaths, isEmpty);
  });

  test('full camera QA plan covers every camera native stitch and OCR test', () async {
    final result = await Process.run('bash', [
      'tool/receipt_camera_qa_gate.sh',
      '--print-plan',
      'full',
    ]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    final planned = result.stdout
        .toString()
        .split('\n')
        .where(
          (line) =>
              line.startsWith('quick ') ||
              line.startsWith('milestone ') ||
              line.startsWith('full '),
        )
        .map((line) => line.split(' ').last)
        .toSet();

    final diskTests = Directory('test')
        .listSync()
        .whereType<File>()
        .map((file) => file.path)
        .where(
          (path) =>
              path.contains('/receipt_camera_') ||
              path.contains('/receipt_native_') ||
              path.contains('/receipt_stitch') ||
              path.contains('/receipt_photo_review_retake_order') ||
              path.contains('/receipt_ocr_source'),
        )
        .where((path) => path.endsWith('.dart'))
        .map((path) => path.replaceFirst('${Directory.current.path}/', ''))
        .toSet();

    expect(planned, containsAll(diskTests));
  });

  test('full camera QA plan includes every focused stitch test', () async {
    Future<Set<String>> plannedTestsFor(String mode) async {
      final result = await Process.run('bash', [
        'tool/receipt_camera_qa_gate.sh',
        '--print-plan',
        mode,
      ]);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      return result.stdout
          .toString()
          .split('\n')
          .where(
            (line) =>
                line.startsWith('quick ') ||
                line.startsWith('stitch ') ||
                line.startsWith('milestone ') ||
                line.startsWith('full '),
          )
          .map((line) => line.split(' ').last)
          .toSet();
    }

    final stitchPlan = await plannedTestsFor('stitch');
    final fullPlan = await plannedTestsFor('full');

    expect(fullPlan, containsAll(stitchPlan));
  });
}
