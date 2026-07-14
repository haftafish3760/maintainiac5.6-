import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'local dataset audit passes when optional datasets are absent',
    () async {
      final result = await Process.run('dart', [
        'tool/receipt_external_dataset_local_audit.dart',
      ]);

      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(
        result.stdout.toString(),
        contains('Receipt external dataset local audit: PASS'),
      );
    },
  );

  test('strict dataset audit requires a local benchmark dataset', () async {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_dataset_strict_audit_',
    );
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    final manifest = File('${root.path}/manifest.json');
    manifest.writeAsStringSync(
      jsonEncode({
        'approvedDatasets': [
          {
            'id': 'sample_receipts',
            'localPath': '.external_datasets/receipts/sample_receipts',
          },
        ],
      }),
    );

    final result = await Process.run(
      'dart',
      ['tool/receipt_external_dataset_local_audit.dart'],
      environment: {
        'RECEIPT_EXTERNAL_DATASET_REPO_ROOT': root.path,
        'RECEIPT_EXTERNAL_DATASET_MANIFEST_PATH': manifest.path,
        'RECEIPT_EXTERNAL_DATASET_REQUIRE_PRESENT': 'true',
      },
    );

    expect(result.exitCode, 1);
    expect(
      result.stderr.toString(),
      contains('Real receipt benchmark evidence'),
    );
  });

  test(
    'local dataset audit requires license and attribution when present',
    () async {
      final root = Directory.systemTemp.createTempSync(
        'maintainiac_dataset_audit_',
      );
      addTearDown(() {
        if (root.existsSync()) root.deleteSync(recursive: true);
      });

      final manifest = File('${root.path}/manifest.json');
      manifest.writeAsStringSync(
        jsonEncode({
          'approvedDatasets': [
            {
              'id': 'sample_receipts',
              'localPath': '.external_datasets/receipts/sample_receipts',
            },
          ],
        }),
      );
      final dataset = Directory(
        '${root.path}/.external_datasets/receipts/sample_receipts',
      )..createSync(recursive: true);

      final missing = await _runAudit(root, manifest);
      expect(missing.exitCode, 1);
      expect(missing.stderr.toString(), contains('without a license file'));
      expect(missing.stderr.toString(), contains('without attribution notes'));

      File('${dataset.path}/LICENSE.txt').writeAsStringSync('test license');
      File('${dataset.path}/ATTRIBUTION.md').writeAsStringSync('test source');

      final fixed = await _runAudit(root, manifest);
      expect(fixed.exitCode, 0, reason: fixed.stderr.toString());
      expect(
        fixed.stdout.toString(),
        contains('present_local_dataset_count=1'),
      );
    },
  );
}

Future<ProcessResult> _runAudit(Directory root, File manifest) {
  return Process.run(
    'dart',
    ['tool/receipt_external_dataset_local_audit.dart'],
    environment: {
      'RECEIPT_EXTERNAL_DATASET_REPO_ROOT': root.path,
      'RECEIPT_EXTERNAL_DATASET_MANIFEST_PATH': manifest.path,
    },
  );
}
