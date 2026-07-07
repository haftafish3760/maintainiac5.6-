import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt external dataset manifest is local-only and privacy-safe', () {
    final manifestFile = File(
      'test/fixtures/receipt_qa/external_dataset_manifest.json',
    );
    expect(manifestFile.existsSync(), isTrue);

    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, Object?>;
    expect(
      manifest['schema'],
      'maintainiac_receipt_external_dataset_manifest_v1',
    );

    final policy = manifest['rawDatasetPolicy']! as Map<String, Object?>;
    expect(policy['storageRoot'], '.external_datasets/receipts');
    expect(policy['committedToGit'], isFalse);
    expect(policy['gitignoreRequired'], isTrue);
    expect(
      policy['blockedUse'],
      containsAll([
        'shipping_raw_third_party_images',
        'committing_unredacted_receipts',
        'training_without_license_review',
      ]),
    );

    final datasets = manifest['approvedDatasets']! as List<Object?>;
    expect(datasets, isNotEmpty);
    final ids = <String>{};
    for (final entry in datasets.cast<Map<String, Object?>>()) {
      expect(ids.add(entry['id']! as String), isTrue);
      expect(
        (entry['localPath']! as String),
        startsWith('.external_datasets/'),
      );
      expect(
        entry['requiredBeforeImport'],
        containsAll([
          'downloaded_locally',
          'license_file_present',
          'no_raw_images_committed',
          'fixture_outputs_redacted_or_synthetic',
        ]),
      );
    }

    expect(
      manifest['summaryReportExcludes'],
      containsAll([
        'rawText',
        'ocrText',
        'receiptImagePath',
        'sourceImageBytes',
        'cardNumber',
        'customerName',
        'streetAddress',
      ]),
    );
  });

  test('receipt external dataset gate is executable', () async {
    final result = await Process.run('dart', [
      'tool/receipt_external_dataset_gate.dart',
    ]);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(
      result.stdout.toString(),
      contains('Receipt external dataset gate: PASS'),
    );
  });
}
