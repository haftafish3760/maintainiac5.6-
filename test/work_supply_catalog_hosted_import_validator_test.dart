import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_hosted_export_writer.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_hosted_import_validator.dart';

void main() {
  test('hosted catalog validator accepts exported catalog package', () async {
    final result = await _writeExport('validator_ready');

    final validation = await const WorkSupplyHostedCatalogImportValidator()
        .validateDirectory(Directory(result.directoryPath));

    expect(validation.status, WorkSupplyHostedCatalogValidationStatus.ready);
    expect(validation.isReady, isTrue);
    expect(validation.checkedChunkCount, result.manifest.chunkCount);
    expect(validation.checkedItemCount, result.manifest.itemCount);
    expect(validation.issues, isEmpty);
    expect(
      validation.toHealthMap()['schema'],
      'work_supply_hosted_catalog_validation_v1',
    );
  });

  test('hosted catalog validator rejects missing manifest', () async {
    final directory = await Directory.systemTemp.createTemp(
      'maintainiac_missing_manifest_',
    );
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    final validation = await const WorkSupplyHostedCatalogImportValidator()
        .validateDirectory(directory);

    expect(
      validation.status,
      WorkSupplyHostedCatalogValidationStatus.missingManifest,
    );
    expect(validation.isReady, isFalse);
  });

  test('hosted catalog validator rejects missing chunk files', () async {
    final result = await _writeExport('validator_missing_chunk');
    await File(result.chunkPaths.first).delete();

    final validation = await const WorkSupplyHostedCatalogImportValidator()
        .validateDirectory(Directory(result.directoryPath));

    expect(
      validation.status,
      WorkSupplyHostedCatalogValidationStatus.missingChunk,
    );
    expect(validation.issues.single, contains('missing'));
  });

  test('hosted catalog validator rejects checksum mismatches', () async {
    final result = await _writeExport('validator_bad_checksum');
    final file = File(result.chunkPaths.first);
    await file.writeAsBytes(
      gzip.encode(utf8.encode('{"items":[]}')),
      flush: true,
    );

    final validation = await const WorkSupplyHostedCatalogImportValidator()
        .validateDirectory(Directory(result.directoryPath));

    expect(
      validation.status,
      WorkSupplyHostedCatalogValidationStatus.checksumMismatch,
    );
  });

  test(
    'hosted catalog validator rejects unsafe Firestore manifest shape',
    () async {
      final result = await _writeExport('validator_unsafe_shape');
      final manifestFile = File(result.manifestPath);
      final manifest =
          jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
      manifest['firestoreItemDocumentReadCount'] = 12000;
      await manifestFile.writeAsString(jsonEncode(manifest), flush: true);

      final validation = await const WorkSupplyHostedCatalogImportValidator()
          .validateDirectory(Directory(result.directoryPath));

      expect(
        validation.status,
        WorkSupplyHostedCatalogValidationStatus.unsafeFirestoreShape,
      );
      expect(validation.issues.join(' '), contains('Firestore'));
    },
  );

  test('hosted catalog validator rejects unsafe chunk paths', () async {
    final result = await _writeExport('validator_bad_path');
    final manifestFile = File(result.manifestPath);
    final manifest =
        jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
    final chunks = manifest['chunks'] as List<dynamic>;
    final firstChunk = chunks.first as Map<String, dynamic>;
    firstChunk['storagePath'] = '../escape.json.gz';
    await manifestFile.writeAsString(jsonEncode(manifest), flush: true);

    final validation = await const WorkSupplyHostedCatalogImportValidator()
        .validateDirectory(Directory(result.directoryPath));

    expect(
      validation.status,
      WorkSupplyHostedCatalogValidationStatus.invalidChunkPath,
    );
  });
}

Future<WorkSupplyHostedCatalogExportFileSet> _writeExport(String label) async {
  final base = await Directory.systemTemp.createTemp('maintainiac_$label');
  final result = await WorkSupplyHostedCatalogExportWriter(
    baseDirectory: base,
  ).writeHostedCatalogPack(generatedAt: DateTime.utc(2026, 6, 23, 12));
  addTearDown(() async {
    if (await base.exists()) await base.delete(recursive: true);
  });
  return result;
}
