import 'dart:convert';
import 'dart:io';

import 'work_supply_catalog_hosted_manifest.dart';
import 'work_supply_models.dart';

class WorkSupplyHostedCatalogExportFileSet {
  const WorkSupplyHostedCatalogExportFileSet({
    required this.directoryPath,
    required this.manifestPath,
    required this.chunkPaths,
    required this.manifest,
  });

  final String directoryPath;
  final String manifestPath;
  final List<String> chunkPaths;
  final WorkSupplyHostedCatalogManifest manifest;

  List<String> get files => [manifestPath, ...chunkPaths];
}

class WorkSupplyHostedCatalogExportWriter {
  const WorkSupplyHostedCatalogExportWriter({Directory? baseDirectory})
    : _baseDirectory = baseDirectory;

  final Directory? _baseDirectory;

  Future<WorkSupplyHostedCatalogExportFileSet> writeHostedCatalogPack({
    Iterable<WorkSupplyItem>? items,
    DateTime? generatedAt,
  }) async {
    final exportTime = generatedAt ?? DateTime.now().toUtc();
    final directory = await _createExportDirectory(exportTime);
    final manifest = buildWorkSupplyHostedCatalogManifest(
      items: items,
      generatedAt: exportTime,
    );
    final chunkPayloads = buildWorkSupplyHostedCatalogChunkPayloads(
      items: items,
    );
    final payloadByChunkId = {
      for (final payload in chunkPayloads) payload.manifest.chunkId: payload,
    };

    final chunkPaths = <String>[];
    for (final chunk in manifest.chunks) {
      final payload = payloadByChunkId[chunk.chunkId];
      if (payload == null) {
        throw StateError(
          'Missing hosted catalog payload for ${chunk.chunkId}.',
        );
      }
      if (payload.sha256Hex != chunk.sha256) {
        throw StateError('Checksum mismatch while exporting ${chunk.chunkId}.');
      }
      final gzipBytes = gzip.encode(payload.jsonBytes);
      final destination = File('${directory.path}/${chunk.storagePath}');
      await destination.parent.create(recursive: true);
      await destination.writeAsBytes(gzipBytes, flush: true);
      chunkPaths.add(destination.path);
    }

    final manifestFile = File('${directory.path}/manifest.json');
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toMap()),
      flush: true,
    );

    return WorkSupplyHostedCatalogExportFileSet(
      directoryPath: directory.path,
      manifestPath: manifestFile.path,
      chunkPaths: List.unmodifiable(chunkPaths),
      manifest: manifest,
    );
  }

  Future<Directory> _createExportDirectory(DateTime exportedAt) async {
    final base = _baseDirectory ?? Directory.systemTemp;
    final stamp = exportedAt.toIso8601String().replaceAll(
      RegExp(r'[^0-9A-Za-z]+'),
      '_',
    );
    final directory = Directory(
      '${base.path}/maintainiac_work_supply_catalog_$stamp',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
