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
        contains('PASS: no source files exceed 600 lines.'),
      );
      expect(result.stdout, isNot(contains('work_supply_catalog_test.dart')));
      expect(result.stdout, isNot(contains('global_odometer_test.dart')));
    },
    timeout: _auditTimeout,
  );

  test(
    'source audit ignores generated catalog data unless explicitly requested',
    () async {
      final tempRoot = Directory.systemTemp.createTempSync(
        'maintainiac_source_audit_',
      );
      addTearDown(() => tempRoot.deleteSync(recursive: true));

      final generatedDir = Directory(
        '${tempRoot.path}/lib/screens/work_supplies/data/catalog/hvac',
      )..createSync(recursive: true);
      final handwrittenDir = Directory(
        '${tempRoot.path}/lib/screens/work_supplies/data',
      )..createSync(recursive: true);

      File(
        '${generatedDir.path}/generated_hvac_service_catalog.dart',
      ).writeAsStringSync(List.filled(520, 'const generated = 1;').join('\n'));
      File(
        '${handwrittenDir.path}/work_supply_receipt_parser.dart',
      ).writeAsStringSync('const handwritten = true;\n');

      final defaultResult = await Process.run('dart', [
        'run',
        'tool/maintainiac_source_audit.dart',
        '${tempRoot.path}/lib/screens/work_supplies/data',
        '--max-line-length=220',
      ]);

      expect(
        defaultResult.exitCode,
        0,
        reason: '${defaultResult.stdout}\n${defaultResult.stderr}',
      );
      expect(defaultResult.stdout, contains('generatedCatalogFilesSkipped=1'));
      expect(
        defaultResult.stdout,
        isNot(contains('generated_hvac_service_catalog.dart')),
      );

      final includedResult = await Process.run('dart', [
        'run',
        'tool/maintainiac_source_audit.dart',
        '${tempRoot.path}/lib/screens/work_supplies/data',
        '--include-generated-catalog-data',
        '--max-line-length=220',
      ]);

      expect(includedResult.exitCode, 1);
      expect(
        includedResult.stdout,
        contains('generated_hvac_service_catalog.dart'),
      );
    },
    timeout: _auditTimeout,
  );

  test(
    'source audit ignores vendored native plugin symlink sources',
    () async {
      final tempRoot = Directory.systemTemp.createTempSync(
        'maintainiac_source_audit_symlink_',
      );
      addTearDown(() => tempRoot.deleteSync(recursive: true));

      final symlinkDir = Directory('${tempRoot.path}/ios/.symlinks/plugins')
        ..createSync(recursive: true);
      File(
        '${symlinkDir.path}/oversized_plugin.swift',
      ).writeAsStringSync(List.filled(520, 'let generated = true').join('\n'));
      File('${tempRoot.path}/app.swift').writeAsStringSync('let app = true\n');

      final result = await Process.run('dart', [
        'run',
        'tool/maintainiac_source_audit.dart',
        tempRoot.path,
        '--max-line-length=220',
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, isNot(contains('oversized_plugin.swift')));
    },
    timeout: _auditTimeout,
  );
}
