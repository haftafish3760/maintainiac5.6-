import 'dart:convert';
import 'dart:io';

const _sourceReviewBytes = 5 * 1024 * 1024;
const _sourceBlockBytes = 10 * 1024 * 1024;
const _androidInstallCandidateBlockBytes = 100 * 1024 * 1024;
const _iosInstallCandidateBlockBytes = 100 * 1024 * 1024;

const _dartGroups = <String, List<String>>{
  'receipt_capture_dart': ['lib/shared/widgets/receipt_capture'],
  'shared_receipt_contracts': ['lib/shared/receipts'],
};

const _excludedDartPathFragments = <String>['receipt_pdf'];

const _androidArtifactPaths = <String>[
  'build/app/outputs/flutter-apk/app-debug.apk',
  'build/app/outputs/flutter-apk/app-release.apk',
  'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk',
  'build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk',
  'build/app/outputs/flutter-apk/app-x86_64-release.apk',
  'build/app/outputs/bundle/release/app-release.aab',
  'build/app/outputs/apk/debug/app-debug.apk',
  'build/app/outputs/apk/release/app-arm64-v8a-release.apk',
  'build/app/outputs/apk/release/app-armeabi-v7a-release.apk',
  'build/app/outputs/apk/release/app-x86_64-release.apk',
];

const _iosArtifactPaths = <String>['build/ios/Runner-size-probe.ipa', 'build/ios/maintainiac-size-probe.ipa'];

void main(List<String> args) {
  final jsonMode = args.contains('--json');
  final groups = <_FootprintGroup>[
    ..._dartGroups.entries.map((entry) => _FootprintGroup(name: entry.key, files: _dartFilesUnder(entry.value).toList())),
    _FootprintGroup(
      name: 'android_native_receipt_camera',
      files: _nativeFilesUnder('android/app/src/main/kotlin/com/maintainiac', extension: '.kt').toList(),
    ),
    _FootprintGroup(
      name: 'ios_native_receipt_camera',
      files: _nativeFilesUnder('ios/Runner', extension: '.swift').toList(),
    ),
  ];

  final allFiles = <String, File>{};
  for (final group in groups) {
    for (final file in group.files) {
      allFiles[file.path] = file;
    }
  }
  final totalBytes = allFiles.values.fold<int>(0, (total, file) => total + file.lengthSync());
  final androidArtifacts = _existingFiles(_androidArtifactPaths);
  final iosArtifacts = _existingFiles(_iosArtifactPaths);

  if (jsonMode) {
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert({
        'scope': 'receipt_camera_ocr_source',
        'excludes': ['tests', 'docs', 'pdf_receipt_import_viewer', 'generated_inventory_catalog_data', 'compiled_packaging_overhead_from_source_total'],
        'excludedPathFragments': _excludedDartPathFragments,
        'source': {
          'totalBytes': totalBytes,
          'totalLabel': _formatBytes(totalBytes),
          'thresholdStatus': _thresholdStatus(totalBytes, reviewBytes: _sourceReviewBytes, blockBytes: _sourceBlockBytes),
          'reviewThresholdBytes': _sourceReviewBytes,
          'blockThresholdBytes': _sourceBlockBytes,
          'fileCount': allFiles.length,
          'groups': {
            for (final group in groups) group.name: {'bytes': group.totalBytes, 'label': _formatBytes(group.totalBytes), 'fileCount': group.files.length},
          },
        },
        'artifacts': {
          'android': _artifactMaps(androidArtifacts),
          'ios': _artifactMaps(iosArtifacts),
          'androidInstallCandidateBlockBytes': _androidInstallCandidateBlockBytes,
          'iosInstallCandidateBlockBytes': _iosInstallCandidateBlockBytes,
          'androidInstallCandidateStatus': _artifactThresholdMaps(androidArtifacts, blockBytes: _androidInstallCandidateBlockBytes),
          'iosInstallCandidateStatus': _artifactThresholdMaps(iosArtifacts, blockBytes: _iosInstallCandidateBlockBytes),
        },
      }),
    );
  } else {
    _writeHumanReport(groups: groups, totalBytes: totalBytes, totalFileCount: allFiles.length, androidArtifacts: androidArtifacts, iosArtifacts: iosArtifacts);
  }

  _applySourceThresholds(totalBytes);
  _applyArtifactThresholds(androidArtifacts, blockBytes: _androidInstallCandidateBlockBytes);
  _applyArtifactThresholds(iosArtifacts, blockBytes: _iosInstallCandidateBlockBytes);
}

void _writeHumanReport({required List<_FootprintGroup> groups, required int totalBytes, required int totalFileCount, required List<File> androidArtifacts, required List<File> iosArtifacts}) {
  stdout.writeln('Receipt camera/OCR source footprint audit');
  stdout.writeln(
    'Scope excludes tests, docs, generated inventory/catalog data, and final '
    'compiled APK/IPA packaging overhead. PDF receipt import/viewer helpers '
    'are outside this camera/OCR source total.',
  );
  for (final group in groups) {
    stdout.writeln(
      '${group.name}: ${group.files.length} files, '
      '${_formatBytes(group.totalBytes)}',
    );
  }
  stdout.writeln(
    'total_receipt_camera_ocr_source: $totalFileCount files, '
    '${_formatBytes(totalBytes)}',
  );
  _writeAndroidArtifactSummary(androidArtifacts);
  _writeIosArtifactSummary(iosArtifacts);
}

void _applySourceThresholds(int totalBytes) {
  if (totalBytes >= _sourceBlockBytes) {
    stderr.writeln(
      'Receipt camera/OCR source footprint is over the '
      '${_formatBytes(_sourceBlockBytes)} source block threshold.',
    );
    exitCode = 1;
  } else if (totalBytes >= _sourceReviewBytes) {
    stderr.writeln(
      'Receipt camera/OCR source footprint is over the '
      '${_formatBytes(_sourceReviewBytes)} source review point.',
    );
  }
}

void _applyArtifactThresholds(List<File> artifacts, {required int blockBytes}) {
  for (final artifact in artifacts) {
    if (!_isInstallCandidateArtifact(artifact.path)) continue;
    final bytes = artifact.lengthSync();
    if (bytes < blockBytes) continue;
    stderr.writeln(
      'Receipt camera/OCR install candidate ${artifact.path} is over the '
      '${_formatBytes(blockBytes)} artifact block threshold.',
    );
    exitCode = 1;
  }
}

void _writeAndroidArtifactSummary(List<File> artifacts) {
  if (artifacts.isEmpty) {
    stdout.writeln(
      'android_build_artifacts: none found; run an Android build before using '
      'this audit for phone install-size evidence.',
    );
    return;
  }

  stdout.writeln('android_build_artifacts: ${artifacts.length} existing APK/AAB files found');
  for (final file in artifacts) {
    stdout.writeln('artifact ${file.path}: ${_formatBytes(file.lengthSync())}');
  }
}

void _writeIosArtifactSummary(List<File> artifacts) {
  if (artifacts.isEmpty) {
    stdout.writeln(
      'ios_build_artifacts: none found; run an iOS archive/export before using '
      'this audit for phone install-size evidence.',
    );
    return;
  }

  stdout.writeln('ios_build_artifacts: ${artifacts.length} existing IPA files found');
  for (final file in artifacts) {
    stdout.writeln('artifact ${file.path}: ${_formatBytes(file.lengthSync())}');
  }
}

List<File> _existingFiles(List<String> paths) => paths.map(File.new).where((file) => file.existsSync()).toList();

List<Map<String, Object>> _artifactMaps(List<File> artifacts) {
  return [
    for (final file in artifacts) {'path': file.path, 'bytes': file.lengthSync(), 'label': _formatBytes(file.lengthSync())},
  ];
}

List<Map<String, Object>> _artifactThresholdMaps(List<File> artifacts, {required int blockBytes}) {
  return [
    for (final file in artifacts)
      if (_isInstallCandidateArtifact(file.path)) {'path': file.path, 'bytes': file.lengthSync(), 'blockThresholdBytes': blockBytes, 'status': file.lengthSync() >= blockBytes ? 'block' : 'ok'},
  ];
}

String _thresholdStatus(int bytes, {required int reviewBytes, required int blockBytes}) {
  if (bytes >= blockBytes) return 'block';
  if (bytes >= reviewBytes) return 'review';
  return 'ok';
}

bool _isInstallCandidateArtifact(String path) {
  if (path.contains('/debug/')) return false;
  if (path.endsWith('app-debug.apk')) return false;
  if (path.endsWith('app-release.apk')) return false;
  return path.endsWith('-release.apk') || path.endsWith('.aab') || path.endsWith('.ipa');
}

Iterable<File> _dartFilesUnder(List<String> roots) sync* {
  for (final rootPath in roots) {
    final root = Directory(rootPath);
    if (!root.existsSync()) continue;
    for (final entity in root.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        if (_isExcludedDartSource(entity.path)) continue;
        yield entity;
      }
    }
  }
}

Iterable<File> _nativeFilesUnder(String rootPath, {required String extension}) sync* {
  final root = Directory(rootPath);
  if (!root.existsSync()) return;
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith(extension)) continue;
    final name = entity.uri.pathSegments.last;
    if (name.startsWith('ReceiptCamera')) {
      yield entity;
      continue;
    }
    final source = entity.readAsStringSync();
    if (source.contains('ReceiptCamera') || source.contains('receipt_camera')) {
      yield entity;
    }
  }
}

bool _isExcludedDartSource(String path) {
  return _excludedDartPathFragments.any(path.contains);
}

String _formatBytes(int bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb >= 10) return '${mb.toStringAsFixed(1)} MB';
  if (mb >= 1) return '${mb.toStringAsFixed(2)} MB';
  final kb = bytes / 1024;
  return '${kb.toStringAsFixed(kb >= 10 ? 0 : 1)} KB';
}

class _FootprintGroup {
  const _FootprintGroup({required this.name, required this.files});

  final String name;
  final List<File> files;

  int get totalBytes => files.fold<int>(0, (total, file) => total + file.lengthSync());
}
