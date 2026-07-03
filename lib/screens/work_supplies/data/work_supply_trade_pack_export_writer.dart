import 'dart:convert';
import 'dart:io';

import 'work_supply_trade_pack_manifest.dart';
import 'work_supply_trade_pack_tiers.dart';

class WorkSupplyTradePackExportFileSet {
  const WorkSupplyTradePackExportFileSet({
    required this.directoryPath,
    required this.manifestPath,
    required this.chunkPaths,
    required this.manifest,
  });

  final String directoryPath;
  final String manifestPath;
  final List<String> chunkPaths;
  final WorkSupplyTradePackManifest manifest;

  List<String> get files => [manifestPath, ...chunkPaths];
}

class WorkSupplyTradePackExportWriter {
  const WorkSupplyTradePackExportWriter({Directory? baseDirectory})
    : _baseDirectory = baseDirectory;

  final Directory? _baseDirectory;

  Future<WorkSupplyTradePackExportFileSet> writeTradePack({
    required WorkSupplyTradePackOption option,
    DateTime? generatedAt,
  }) async {
    final exportTime = generatedAt ?? DateTime.now().toUtc();
    final directory = await _createExportDirectory(option, exportTime);
    final payloads = buildWorkSupplyTradePackChunkPayloads(option);
    final manifest = buildWorkSupplyTradePackManifestForPayloads(
      option,
      payloads,
      generatedAt: exportTime,
    );
    final payloadByChunkId = {
      for (final payload in payloads) payload.manifest.chunkId: payload,
    };

    final chunkPaths = <String>[];
    for (final chunk in manifest.chunks) {
      final payload = payloadByChunkId[chunk.chunkId];
      if (payload == null) {
        throw StateError('Missing trade pack payload for ${chunk.chunkId}.');
      }
      if (payload.sha256Hex != chunk.sha256) {
        throw StateError('Checksum mismatch while exporting ${chunk.chunkId}.');
      }
      final destination = File('${directory.path}/${chunk.storagePath}');
      await destination.parent.create(recursive: true);
      await destination.writeAsBytes(
        gzip.encode(payload.jsonBytes),
        flush: true,
      );
      chunkPaths.add(destination.path);
    }

    final manifestFile = File('${directory.path}/manifest.json');
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toMap()),
      flush: true,
    );

    return WorkSupplyTradePackExportFileSet(
      directoryPath: directory.path,
      manifestPath: manifestFile.path,
      chunkPaths: List.unmodifiable(chunkPaths),
      manifest: manifest,
    );
  }

  Future<Directory> _createExportDirectory(
    WorkSupplyTradePackOption option,
    DateTime exportedAt,
  ) async {
    final base = _baseDirectory ?? Directory.systemTemp;
    final stamp = exportedAt.toIso8601String().replaceAll(
      RegExp(r'[^0-9A-Za-z]+'),
      '_',
    );
    final directory = Directory(
      '${base.path}/maintainiac_${workSupplyTradePackOptionKey(option)}_$stamp',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
