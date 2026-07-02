import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _auditTimeout = Timeout(Duration(minutes: 2));

void main() {
  test(
    'receipt source audit stays scoped to receipt camera and OCR files',
    () async {
      final result = await Process.run('dart', [
        'run',
        'tool/maintainiac_source_audit.dart',
        '--max-line-length=220',
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('scope=receipt'));
      expect(
        result.stdout,
        contains('PASS: no source files exceed 500 lines.'),
      );
      expect(result.stdout, isNot(contains('work_supply_catalog_test.dart')));
      expect(result.stdout, isNot(contains('global_odometer_test.dart')));
    },
    timeout: _auditTimeout,
  );

  test(
    'receipt test audit excludes unrelated inventory and odometer tests',
    () async {
      final result = await Process.run('dart', [
        'run',
        'tool/maintainiac_source_audit.dart',
        '--tests-only',
        '--max-line-length=220',
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(
        result.stdout,
        contains('PASS: no source files exceed 500 lines.'),
      );
      expect(result.stdout, isNot(contains('work_supply_catalog_test.dart')));
      expect(result.stdout, isNot(contains('global_odometer_test.dart')));
    },
    timeout: _auditTimeout,
  );
}
