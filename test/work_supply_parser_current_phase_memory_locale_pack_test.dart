import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_pack_payload.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_import_validator.dart';

void main() {
  group('inventory parser current-phase memory locale and pack behavior', () {
    test(
      'learned corrections override catalog guesses but stay review-only',
      () {
        final target = matchReceiptLineToCatalog(
          'HD 1/2 PEX CRIMP 90 BRASS',
          tradeScope: 'Plumbing',
          maxCandidates: 240,
        );
        expect(target, isNotNull);

        final memory = ReceiptParserLearningMemory()
          ..confirmCorrection(
            receiptLine: 'counter ticket line 17',
            item: target!.item,
          );

        final learned = matchReceiptLineToCatalog(
          'COUNTER TICKET LINE 17',
          memory: memory,
          tradeScope: 'Plumbing',
          maxCandidates: 240,
        );

        expect(learned, isNotNull);
        expect(learned!.item.id, target.item.id);
        expect(learned.source, ReceiptMatchSource.learnedCorrection);
        expect(learned.confidenceLevel, ReceiptConfidenceLevel.good);
        expect(learned.needsReview, isTrue);
        expect(learned.matchedTerms, contains('learned'));
      },
    );

    test('learned corrections tolerate trailing receipt prices', () {
      final target = matchReceiptLineToCatalog(
        'LOWES 3/4 PVC SCH 40 COUPLING',
        tradeScope: 'Plumbing',
        maxCandidates: 240,
      );
      expect(target, isNotNull);

      final memory = ReceiptParserLearningMemory()
        ..confirmCorrection(
          receiptLine: 'LOWES 3/4 PVC SCH 40 COUPLING',
          item: target!.item,
        );

      final learned = matchReceiptLineToCatalog(
        'LOWES 3/4 PVC SCH 40 COUPLING 2 48',
        memory: memory,
        tradeScope: 'Plumbing',
        maxCandidates: 240,
      );

      expect(learned, isNotNull);
      expect(learned!.item.id, target.item.id);
      expect(learned.source, ReceiptMatchSource.learnedCorrection);
      expect(learned.needsReview, isTrue);
    });

    test('es-US locale overlay recognizes Spanish trade wording', () {
      final spanish = matchReceiptLineToCatalog(
        'HD CODO PEX 90 LATON 1/2',
        localePackId: 'es-US',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );

      expect(spanish, isNotNull);
      expect(spanish!.item.trade, 'Plumbing');
      expect(spanish.item.name.toLowerCase(), contains('pex'));
      expect(spanish.item.name.toLowerCase(), contains('elbow'));
      expect(spanish.confidenceLevel, ReceiptConfidenceLevel.good);
      expect(spanish.needsReview, isTrue);
    });

    test('confidence labels and guidance stay stable for review routing', () {
      expect(receiptConfidenceLevelFor(0.99), ReceiptConfidenceLevel.good);
      expect(receiptConfidenceLevelFor(0.82), ReceiptConfidenceLevel.good);
      expect(receiptConfidenceLevelFor(0.81), ReceiptConfidenceLevel.okay);
      expect(receiptConfidenceLevelFor(0.62), ReceiptConfidenceLevel.okay);
      expect(receiptConfidenceLevelFor(0.61), ReceiptConfidenceLevel.poor);

      expect(receiptConfidenceLabel(ReceiptConfidenceLevel.good), 'Good');
      expect(receiptConfidenceLabel(ReceiptConfidenceLevel.okay), 'Review');
      expect(receiptConfidenceLabel(ReceiptConfidenceLevel.poor), 'Poor');
      expect(
        receiptConfidenceGuidance(ReceiptConfidenceLevel.okay).toLowerCase(),
        contains('review'),
      );
    });

    test(
      'pack validator rejects unsafe chunk paths before file access',
      () async {
        final directory = await _syntheticPackDirectory(
          chunkStoragePath: '../escape.json.gz',
        );

        final result = await const WorkSupplyTradePackImportValidator()
            .validateDirectory(directory);

        expect(
          result.status,
          WorkSupplyTradePackValidationStatus.invalidChunkPath,
        );
        expect(result.checkedChunkCount, 0);
        expect(result.issues.single, contains('unsafe'));
      },
    );

    test('pack validator rejects chunks missing parser metadata', () async {
      final directory = await _syntheticPackDirectory();
      final manifestFile = File('${directory.path}/manifest.json');
      final manifest = jsonDecode(await manifestFile.readAsString()) as Map;
      final chunk = (manifest['chunks'] as List).first as Map;
      final chunkFile = File('${directory.path}/${chunk['storagePath']}');
      final payload =
          jsonDecode(utf8.decode(gzip.decode(await chunkFile.readAsBytes())))
              as Map;
      final items = payload['items'] as List;
      final firstItem = Map<String, dynamic>.from(items.first as Map);
      firstItem['searchTerms'] = const <String>[];
      items[0] = firstItem;
      final jsonBytes = utf8.encode(jsonEncode(payload));
      await chunkFile.writeAsBytes(gzip.encode(jsonBytes), flush: true);
      chunk['sha256'] = sha256.convert(jsonBytes).toString();
      await manifestFile.writeAsString(jsonEncode(manifest), flush: true);

      final result = await const WorkSupplyTradePackImportValidator()
          .validateDirectory(directory);

      expect(
        result.status,
        WorkSupplyTradePackValidationStatus.missingParserMetadata,
      );
      expect(result.issues.single, contains('searchTerms'));
    });
  });
}

Future<Directory> _syntheticPackDirectory({
  String chunkStoragePath = 'chunks/core_0001.json.gz',
}) async {
  final base = await Directory.systemTemp.createTemp(
    'maintainiac_current_phase_synthetic_pack_',
  );
  addTearDown(() async {
    if (await base.exists()) await base.delete(recursive: true);
  });
  final payload = {
    'schemaVersion': workSupplyCatalogPackSchemaVersion,
    'items': [
      {
        'canonicalKey': 'plumbing.synthetic.pex.elbow.1_2',
        'searchTerms': ['pex', 'elbow', '1/2', 'brass'],
        'aliases': [
          {'value': '1/2 pex elbow', 'normalized': '1 2 pex elbow'},
        ],
      },
    ],
  };
  final jsonBytes = utf8.encode(jsonEncode(payload));
  final gzipBytes = gzip.encode(jsonBytes);
  if (!chunkStoragePath.contains('..')) {
    final chunk = File('${base.path}/$chunkStoragePath');
    await chunk.parent.create(recursive: true);
    await chunk.writeAsBytes(gzipBytes, flush: true);
  }
  final manifest = {
    'schemaVersion': 1,
    'packId': 'synthetic.plumbing.core.en-us',
    'packVersion': '2026.07.02',
    'generatedAtIso': '2026-07-02T12:00:00.000Z',
    'tradeName': 'Plumbing',
    'marketScope': 'residential',
    'tier': 'core',
    'localePackId': 'en-US',
    'countryCodes': ['US'],
    'displayName': 'Synthetic Plumbing Core Pack',
    'itemCount': 1,
    'chunkCount': 1,
    'firestoreManifestReadCount': 1,
    'firestoreItemDocumentReadCount': 0,
    'estimatedUncompressedBytes': jsonBytes.length,
    'estimatedCompressedBytes': gzipBytes.length,
    'chunks': [
      {
        'chunkId': 'core_0001',
        'itemCount': 1,
        'storagePath': chunkStoragePath,
        'contentEncoding': 'gzip',
        'uncompressedByteSize': jsonBytes.length,
        'estimatedCompressedByteSize': gzipBytes.length,
        'sha256': sha256.convert(jsonBytes).toString(),
      },
    ],
  };
  await File(
    '${base.path}/manifest.json',
  ).writeAsString(jsonEncode(manifest), flush: true);
  return base;
}
