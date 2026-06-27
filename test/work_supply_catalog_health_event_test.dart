import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_health_event.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_hosted_export_writer.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_hosted_import_validator.dart';

void main() {
  test(
    'catalog health event reports ready validation without item bodies',
    () async {
      final result = await _writeExport('catalog_health_ready');
      final validation = await const WorkSupplyHostedCatalogImportValidator()
          .validateDirectory(Directory(result.directoryPath));
      final event = WorkSupplyCatalogHealthEvent.fromValidation(validation);
      final map = event.toMap();
      final encoded = map.toString().toLowerCase();

      expect(map['event'], 'catalogPackReady');
      expect(map['featureArea'], 'inventory_catalog');
      expect(map['isReady'], isTrue);
      expect(map['itemCount'], result.manifest.itemCount);
      expect(map['chunkCount'], result.manifest.chunkCount);
      expect(map['firestoreItemDocumentReadCount'], 0);
      expect(encoded, isNot(contains('copper')));
      expect(encoded, isNot(contains('pvc')));
      expect(encoded, isNot(contains('items:')));
    },
  );

  test('catalog health event reports rejected validation safely', () async {
    final result = await _writeExport('catalog_health_rejected');
    await File(result.chunkPaths.first).delete();
    final validation = await const WorkSupplyHostedCatalogImportValidator()
        .validateDirectory(Directory(result.directoryPath));
    final event = WorkSupplyCatalogHealthEvent.fromValidation(validation);
    final map = event.toMap();

    expect(map['event'], 'catalogPackRejected');
    expect(map['isReady'], isFalse);
    expect(
      map['status'],
      WorkSupplyHostedCatalogValidationStatus.missingChunk.name,
    );
    expect(map['issueCount'], 1);
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
