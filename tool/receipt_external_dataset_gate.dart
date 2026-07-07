import 'dart:convert';
import 'dart:io';

const _manifestPath = 'test/fixtures/receipt_qa/external_dataset_manifest.json';
const _gitignorePath = '.gitignore';
const _schema = 'maintainiac_receipt_external_dataset_manifest_v1';
const _storageRoot = '.external_datasets/receipts';
const _approvedStatuses = {
  'approved_metadata_only',
  'candidate_requires_license_review',
};
const _approvedLicenses = {
  'Apache-2.0',
  'CC-BY-4.0',
  'dataset_card_review_required',
};

void main() {
  final failures = <String>[];
  final manifestFile = File(_manifestPath);
  final gitignoreFile = File(_gitignorePath);

  if (!manifestFile.existsSync()) {
    failures.add('Missing receipt external dataset manifest: $_manifestPath');
  }
  if (!gitignoreFile.existsSync()) {
    failures.add('Missing gitignore for local-only dataset protection.');
  }
  if (failures.isEmpty) {
    _checkGitignore(gitignoreFile, failures);
    _checkManifest(manifestFile, failures);
    _checkTrackedDatasetFiles(failures);
  }

  if (failures.isNotEmpty) {
    stderr.writeln('Receipt external dataset gate failed:');
    for (final failure in failures) {
      stderr.writeln('- $failure');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('Receipt external dataset gate: PASS manifest=$_schema');
}

void _checkGitignore(File gitignoreFile, List<String> failures) {
  final gitignore = gitignoreFile.readAsStringSync();
  if (!gitignore.contains('.external_datasets/')) {
    failures.add(
      'Raw receipt datasets must stay ignored at .external_datasets/.',
    );
  }
}

void _checkManifest(File manifestFile, List<String> failures) {
  final decoded = jsonDecode(manifestFile.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    failures.add('External dataset manifest root must be an object.');
    return;
  }
  _expect(decoded, 'schema', _schema, failures);

  final rawPolicy = _mapAt(decoded, 'rawDatasetPolicy', failures);
  _expect(rawPolicy, 'storageRoot', _storageRoot, failures);
  _expect(rawPolicy, 'committedToGit', false, failures);
  _expect(rawPolicy, 'gitignoreRequired', true, failures);
  _expectListContains(rawPolicy, 'allowedUse', [
    'camera_ocr_fixture_generation',
    'parser_regression_discovery',
    'stitching_and_upload_flow_validation',
  ], failures);
  _expectListContains(rawPolicy, 'blockedUse', [
    'shipping_raw_third_party_images',
    'committing_unredacted_receipts',
    'training_without_license_review',
  ], failures);

  final datasets = decoded['approvedDatasets'];
  if (datasets is! List || datasets.isEmpty) {
    failures.add('Manifest must list approved/candidate receipt datasets.');
    return;
  }
  final ids = <String>{};
  for (final entry in datasets) {
    if (entry is! Map<String, Object?>) {
      failures.add('Every dataset entry must be an object.');
      continue;
    }
    final id = entry['id'];
    if (id is! String || id.isEmpty) {
      failures.add('Every dataset entry needs a non-empty id.');
    } else if (!ids.add(id)) {
      failures.add('Duplicate dataset id: $id');
    }
    final license = entry['license'];
    if (license is! String || !_approvedLicenses.contains(license)) {
      failures.add('Dataset $id has unapproved or missing license: $license');
    }
    final status = entry['status'];
    if (status is! String || !_approvedStatuses.contains(status)) {
      failures.add('Dataset $id has unapproved status: $status');
    }
    final localPath = entry['localPath'];
    if (localPath is! String || !localPath.startsWith(_storageRoot)) {
      failures.add('Dataset $id must stay under $_storageRoot.');
    } else if (localPath.contains('..') || localPath.contains('//')) {
      failures.add('Dataset $id localPath must not contain traversal.');
    }
    final source = entry['source'];
    if (source is! String ||
        !(source.startsWith('https://huggingface.co/datasets/') ||
            source.startsWith('https://github.com/'))) {
      failures.add('Dataset $id must use an approved source URL.');
    }
    if (entry['rawImagesCommittedToGit'] != false) {
      failures.add('Dataset $id must explicitly keep raw images out of Git.');
    }
    if (entry['attributionRequired'] != true) {
      failures.add('Dataset $id must explicitly require attribution tracking.');
    }
    _expectListContains(entry, 'requiredBeforeImport', [
      'downloaded_locally',
      'license_file_present',
      'attribution_notes_present',
      'no_raw_images_committed',
      'fixture_outputs_redacted_or_synthetic',
    ], failures);
  }

  _expectListContains(decoded, 'summaryReportExcludes', [
    'rawText',
    'ocrText',
    'receiptImagePath',
    'sourceImageBytes',
    'cardNumber',
    'customerName',
    'streetAddress',
  ], failures);
}

void _checkTrackedDatasetFiles(List<String> failures) {
  final result = Process.runSync('git', [
    'ls-files',
    '--',
    '.external_datasets',
  ]);
  if (result.exitCode != 0) {
    failures.add('Unable to inspect tracked external dataset files.');
    return;
  }
  final tracked = result.stdout.toString().trim();
  if (tracked.isNotEmpty) {
    failures.add('Raw external dataset files are tracked: $tracked');
  }
}

Map<String, Object?> _mapAt(
  Map<String, Object?> parent,
  String key,
  List<String> failures,
) {
  final value = parent[key];
  if (value is Map<String, Object?>) return value;
  failures.add('Expected object at `$key`.');
  return const {};
}

void _expect(
  Map<String, Object?> parent,
  String key,
  Object? expected,
  List<String> failures,
) {
  if (parent[key] != expected) {
    failures.add('Expected `$key` to be `$expected`, got `${parent[key]}`.');
  }
}

void _expectListContains(
  Map<String, Object?> parent,
  String key,
  List<String> required,
  List<String> failures,
) {
  final value = parent[key];
  if (value is! List) {
    failures.add('Expected list at `$key`.');
    return;
  }
  for (final item in required) {
    if (!value.contains(item)) {
      failures.add('List `$key` missing `$item`.');
    }
  }
}
