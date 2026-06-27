import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'work_supply_catalog_hosted_manifest.dart';

enum WorkSupplyHostedCatalogValidationStatus {
  ready,
  missingManifest,
  invalidManifest,
  unsafeFirestoreShape,
  missingChunk,
  invalidChunkPath,
  unreadableChunk,
  checksumMismatch,
  itemCountMismatch,
}

class WorkSupplyHostedCatalogValidationResult {
  const WorkSupplyHostedCatalogValidationResult({
    required this.status,
    required this.manifest,
    required this.checkedChunkCount,
    required this.checkedItemCount,
    required this.issues,
  });

  final WorkSupplyHostedCatalogValidationStatus status;
  final WorkSupplyHostedCatalogManifest? manifest;
  final int checkedChunkCount;
  final int checkedItemCount;
  final List<String> issues;

  bool get isReady => status == WorkSupplyHostedCatalogValidationStatus.ready;

  Map<String, Object?> toHealthMap() {
    return {
      'schema': 'work_supply_hosted_catalog_validation_v1',
      'status': status.name,
      'isReady': isReady,
      'packId': manifest?.packId,
      'packVersion': manifest?.packVersion,
      'checkedChunkCount': checkedChunkCount,
      'checkedItemCount': checkedItemCount,
      'issues': issues,
      'firestoreManifestReadCount': manifest?.firestoreManifestReadCount,
      'firestoreItemDocumentReadCount':
          manifest?.firestoreItemDocumentReadCount,
    };
  }
}

class WorkSupplyHostedCatalogImportValidator {
  const WorkSupplyHostedCatalogImportValidator();

  Future<WorkSupplyHostedCatalogValidationResult> validateDirectory(
    Directory directory,
  ) async {
    final manifestFile = File('${directory.path}/manifest.json');
    if (!await manifestFile.exists()) {
      return const WorkSupplyHostedCatalogValidationResult(
        status: WorkSupplyHostedCatalogValidationStatus.missingManifest,
        manifest: null,
        checkedChunkCount: 0,
        checkedItemCount: 0,
        issues: ['manifest.json is missing.'],
      );
    }

    final WorkSupplyHostedCatalogManifest manifest;
    try {
      final decoded =
          jsonDecode(await manifestFile.readAsString())
              as Map<dynamic, dynamic>;
      manifest = WorkSupplyHostedCatalogManifest.fromMap(decoded);
    } catch (_) {
      return const WorkSupplyHostedCatalogValidationResult(
        status: WorkSupplyHostedCatalogValidationStatus.invalidManifest,
        manifest: null,
        checkedChunkCount: 0,
        checkedItemCount: 0,
        issues: ['manifest.json could not be parsed.'],
      );
    }

    final manifestIssues = _manifestIssues(manifest);
    if (manifestIssues.isNotEmpty) {
      return WorkSupplyHostedCatalogValidationResult(
        status: WorkSupplyHostedCatalogValidationStatus.unsafeFirestoreShape,
        manifest: manifest,
        checkedChunkCount: 0,
        checkedItemCount: 0,
        issues: manifestIssues,
      );
    }

    var checkedChunks = 0;
    var checkedItems = 0;
    for (final chunk in manifest.chunks) {
      final pathIssue = _chunkPathIssue(manifest, chunk);
      if (pathIssue != null) {
        return WorkSupplyHostedCatalogValidationResult(
          status: WorkSupplyHostedCatalogValidationStatus.invalidChunkPath,
          manifest: manifest,
          checkedChunkCount: checkedChunks,
          checkedItemCount: checkedItems,
          issues: [pathIssue],
        );
      }

      final chunkFile = File('${directory.path}/${chunk.storagePath}');
      if (!await chunkFile.exists()) {
        return WorkSupplyHostedCatalogValidationResult(
          status: WorkSupplyHostedCatalogValidationStatus.missingChunk,
          manifest: manifest,
          checkedChunkCount: checkedChunks,
          checkedItemCount: checkedItems,
          issues: ['Chunk file is missing: ${chunk.storagePath}.'],
        );
      }

      final List<int> jsonBytes;
      try {
        jsonBytes = gzip.decode(await chunkFile.readAsBytes());
      } catch (_) {
        return WorkSupplyHostedCatalogValidationResult(
          status: WorkSupplyHostedCatalogValidationStatus.unreadableChunk,
          manifest: manifest,
          checkedChunkCount: checkedChunks,
          checkedItemCount: checkedItems,
          issues: ['Chunk file is not valid gzip: ${chunk.storagePath}.'],
        );
      }

      final actualSha = sha256.convert(jsonBytes).toString();
      if (actualSha != chunk.sha256) {
        return WorkSupplyHostedCatalogValidationResult(
          status: WorkSupplyHostedCatalogValidationStatus.checksumMismatch,
          manifest: manifest,
          checkedChunkCount: checkedChunks,
          checkedItemCount: checkedItems,
          issues: ['Checksum mismatch: ${chunk.chunkId}.'],
        );
      }

      final Map<String, dynamic> payload;
      try {
        payload = jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
      } catch (_) {
        return WorkSupplyHostedCatalogValidationResult(
          status: WorkSupplyHostedCatalogValidationStatus.unreadableChunk,
          manifest: manifest,
          checkedChunkCount: checkedChunks,
          checkedItemCount: checkedItems,
          issues: ['Chunk JSON could not be parsed: ${chunk.chunkId}.'],
        );
      }
      final items = payload['items'];
      if (items is! List || items.length != chunk.itemCount) {
        return WorkSupplyHostedCatalogValidationResult(
          status: WorkSupplyHostedCatalogValidationStatus.itemCountMismatch,
          manifest: manifest,
          checkedChunkCount: checkedChunks,
          checkedItemCount: checkedItems,
          issues: ['Item count mismatch: ${chunk.chunkId}.'],
        );
      }
      checkedChunks++;
      checkedItems += items.length;
    }

    if (checkedChunks != manifest.chunkCount ||
        checkedItems != manifest.itemCount) {
      return WorkSupplyHostedCatalogValidationResult(
        status: WorkSupplyHostedCatalogValidationStatus.itemCountMismatch,
        manifest: manifest,
        checkedChunkCount: checkedChunks,
        checkedItemCount: checkedItems,
        issues: ['Manifest totals do not match checked chunk totals.'],
      );
    }

    return WorkSupplyHostedCatalogValidationResult(
      status: WorkSupplyHostedCatalogValidationStatus.ready,
      manifest: manifest,
      checkedChunkCount: checkedChunks,
      checkedItemCount: checkedItems,
      issues: const [],
    );
  }

  List<String> _manifestIssues(WorkSupplyHostedCatalogManifest manifest) {
    final issues = <String>[];
    if (manifest.schemaVersion != 1) issues.add('Unsupported schema version.');
    if (manifest.packId.trim().isEmpty) issues.add('Pack ID is missing.');
    if (manifest.packVersion.trim().isEmpty) {
      issues.add('Pack version is missing.');
    }
    if (!manifest.isFirestoreReadSafe) {
      issues.add('Manifest is not Firestore read safe.');
    }
    if (manifest.chunkCount <= 0 ||
        manifest.chunks.length != manifest.chunkCount) {
      issues.add('Manifest chunk count is invalid.');
    }
    return issues;
  }

  String? _chunkPathIssue(
    WorkSupplyHostedCatalogManifest manifest,
    WorkSupplyHostedCatalogChunkManifest chunk,
  ) {
    if (chunk.storagePath.contains('..') ||
        chunk.storagePath.startsWith('/') ||
        chunk.storagePath.startsWith(r'\')) {
      return 'Chunk path is unsafe: ${chunk.storagePath}.';
    }
    if (!chunk.storagePath.startsWith(manifest.storagePrefix)) {
      return 'Chunk path is outside the storage prefix: ${chunk.storagePath}.';
    }
    if (!chunk.storagePath.endsWith('.json.gz')) {
      return 'Chunk path must end in .json.gz: ${chunk.storagePath}.';
    }
    if (chunk.contentEncoding != 'gzip') {
      return 'Chunk encoding must be gzip: ${chunk.chunkId}.';
    }
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(chunk.sha256)) {
      return 'Chunk checksum is invalid: ${chunk.chunkId}.';
    }
    return null;
  }
}
