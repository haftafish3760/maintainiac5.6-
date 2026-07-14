import 'dart:convert';
import 'dart:io';

const _defaultManifestPath =
    'test/fixtures/receipt_qa/external_dataset_manifest.json';
const _storageRoot = '.external_datasets/receipts';

void main() {
  final manifestPath =
      Platform.environment['RECEIPT_EXTERNAL_DATASET_MANIFEST_PATH'] ??
      _defaultManifestPath;
  final repoRoot =
      Platform.environment['RECEIPT_EXTERNAL_DATASET_REPO_ROOT'] ??
      Directory.current.path;
  final requirePresent =
      Platform.environment['RECEIPT_EXTERNAL_DATASET_REQUIRE_PRESENT'] ==
      'true';
  final failures = <String>[];
  final manifestFile = File(manifestPath);

  if (!manifestFile.existsSync()) {
    failures.add('Missing receipt external dataset manifest: $manifestPath');
  } else {
    final presentCount = _auditManifest(
      manifestFile,
      Directory(repoRoot),
      failures,
    );
    if (requirePresent && presentCount == 0) {
      failures.add(
        'No local receipt dataset is present. Real receipt benchmark evidence is required for this gate.',
      );
    }
  }

  if (failures.isNotEmpty) {
    stderr.writeln('Receipt external dataset local audit failed:');
    for (final failure in failures) {
      stderr.writeln('- $failure');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('Receipt external dataset local audit: PASS');
}

int _auditManifest(
  File manifestFile,
  Directory repoRoot,
  List<String> failures,
) {
  final decoded = jsonDecode(manifestFile.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    failures.add('External dataset manifest root must be an object.');
    return 0;
  }
  final datasets = decoded['approvedDatasets'];
  if (datasets is! List) {
    failures.add('Manifest approvedDatasets must be a list.');
    return 0;
  }

  var presentCount = 0;
  for (final entry in datasets) {
    if (entry is! Map<String, Object?>) {
      failures.add('Every dataset entry must be an object.');
      continue;
    }
    final id = entry['id'];
    final localPath = entry['localPath'];
    if (id is! String || id.isEmpty) {
      failures.add('Every dataset entry needs a non-empty id.');
      continue;
    }
    if (localPath is! String || !localPath.startsWith(_storageRoot)) {
      failures.add('Dataset $id must stay under $_storageRoot.');
      continue;
    }
    if (localPath.contains('..') || localPath.contains('//')) {
      failures.add('Dataset $id localPath must not contain traversal.');
      continue;
    }

    final directory = Directory('${repoRoot.path}/$localPath');
    if (!directory.existsSync()) continue;
    presentCount += 1;
    _auditLocalDataset(id, directory, failures);
  }

  stdout.writeln('present_local_dataset_count=$presentCount');
  return presentCount;
}

void _auditLocalDataset(String id, Directory directory, List<String> failures) {
  final entries = directory
      .listSync(recursive: false, followLinks: false)
      .map((entry) => entry.uri.pathSegments.last.toLowerCase())
      .toSet();
  final hasLicense = entries.any(
    (name) =>
        name == 'license' ||
        name == 'license.txt' ||
        name == 'license.md' ||
        name == 'copying',
  );
  final hasAttribution = entries.any(
    (name) =>
        name == 'attribution.md' ||
        name == 'attribution.txt' ||
        name == 'notice' ||
        name == 'notice.md' ||
        name == 'notice.txt',
  );

  if (!hasLicense) {
    failures.add('Dataset $id is present locally without a license file.');
  }
  if (!hasAttribution) {
    failures.add('Dataset $id is present locally without attribution notes.');
  }
}
