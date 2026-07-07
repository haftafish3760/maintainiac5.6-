import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'changed-route coverage gate passes against repository scripts',
    () async {
      final result = await Process.run('dart', [
        'tool/receipt_camera_changed_route_coverage_gate.dart',
      ]);

      expect(result.stderr.toString(), isEmpty);
      expect(result.exitCode, 0);
      expect(
        result.stdout.toString(),
        contains('Receipt camera changed-route coverage gate passed'),
      );
    },
  );

  test('changed-route coverage gate reports missing milestone route', () async {
    final dir = await Directory.systemTemp.createTemp(
      'receipt_changed_route_gate_',
    );
    addTearDown(() => dir.delete(recursive: true));

    final changedGate = File('${dir.path}/changed_gate.sh');
    final fastGuard = File('${dir.path}/fast_guard.sh');
    changedGate.writeAsStringSync(
      File('tool/receipt_camera_changed_gate.sh')
          .readAsStringSync()
          .replaceFirst('tool/receipt_external_dataset_gate.dart', ''),
    );
    fastGuard.writeAsStringSync(
      File('tool/receipt_fast_guard_gate.sh').readAsStringSync(),
    );

    final result = await Process.run('dart', [
      'tool/receipt_camera_changed_route_coverage_gate.dart',
      changedGate.path,
      fastGuard.path,
    ]);

    expect(result.exitCode, 1);
    expect(
      result.stderr.toString(),
      contains(
        'MISSING_CHANGED_GATE_ROUTE tool/receipt_external_dataset_gate.dart',
      ),
    );
  });

  test('changed-route coverage gate reports missing fast-guard smoke', () async {
    final dir = await Directory.systemTemp.createTemp(
      'receipt_changed_route_gate_',
    );
    addTearDown(() => dir.delete(recursive: true));

    final changedGate = File('${dir.path}/changed_gate.sh');
    final fastGuard = File('${dir.path}/fast_guard.sh');
    changedGate.writeAsStringSync(
      File('tool/receipt_camera_changed_gate.sh').readAsStringSync(),
    );
    fastGuard.writeAsStringSync(
      File('tool/receipt_fast_guard_gate.sh').readAsStringSync().replaceFirst(
        "RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST='tool/receipt_external_dataset_gate.dart' \\\n"
            '  bash tool/receipt_camera_changed_gate.sh --print-mode >/dev/null',
        '',
      ),
    );

    final result = await Process.run('dart', [
      'tool/receipt_camera_changed_route_coverage_gate.dart',
      changedGate.path,
      fastGuard.path,
    ]);

    expect(result.exitCode, 1);
    expect(
      result.stderr.toString(),
      contains(
        'MISSING_FAST_GUARD_ROUTE_SMOKE tool/receipt_external_dataset_gate.dart',
      ),
    );
  });
}
