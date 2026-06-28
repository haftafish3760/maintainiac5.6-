import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_export_writer.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_import_validator.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('validator accepts exported parser-ready trade pack', () async {
    final base = await Directory.systemTemp.createTemp(
      'maintainiac_trade_pack_validator_test_',
    );
    addTearDown(() async {
      if (await base.exists()) await base.delete(recursive: true);
    });
    final option = buildWorkSupplyTradePackOptions(
      'Plumbing',
    ).firstWhere((candidate) => candidate.tier == WorkSupplyTradePackTier.core);
    final fileSet = await WorkSupplyTradePackExportWriter(baseDirectory: base)
        .writeTradePack(
          option: option,
          generatedAt: DateTime.utc(2026, 6, 27, 12),
        );

    final result = await const WorkSupplyTradePackImportValidator()
        .validateDirectory(Directory(fileSet.directoryPath));

    expect(result.isReady, isTrue);
    expect(result.checkedChunkCount, fileSet.manifest.chunkCount);
    expect(result.checkedItemCount, fileSet.manifest.itemCount);
    expect(result.issues, isEmpty);
  });

  test('validator rejects per-item Firestore shaped manifest', () async {
    final base = await Directory.systemTemp.createTemp(
      'maintainiac_trade_pack_unsafe_manifest_test_',
    );
    addTearDown(() async {
      if (await base.exists()) await base.delete(recursive: true);
    });
    final option = buildWorkSupplyTradePackOptions(
      'Electrical',
    ).firstWhere((candidate) => candidate.tier == WorkSupplyTradePackTier.full);
    final fileSet = await WorkSupplyTradePackExportWriter(baseDirectory: base)
        .writeTradePack(
          option: option,
          generatedAt: DateTime.utc(2026, 6, 27, 12),
        );
    final manifestFile = File(fileSet.manifestPath);
    final manifest = jsonDecode(await manifestFile.readAsString()) as Map;
    manifest['firestoreItemDocumentReadCount'] = 2000;
    await manifestFile.writeAsString(jsonEncode(manifest));

    final result = await const WorkSupplyTradePackImportValidator()
        .validateDirectory(Directory(fileSet.directoryPath));

    expect(
      result.status,
      WorkSupplyTradePackValidationStatus.unsafeFirestoreShape,
    );
    expect(result.issues.single, contains('per-item Firestore reads'));
  });
}
