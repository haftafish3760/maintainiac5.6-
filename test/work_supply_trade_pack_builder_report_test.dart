import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_export_writer.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_import_validator.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('exports requested trade packs', () async {
    final trade = Platform.environment['MAINTAINIAC_PACK_TRADE'] ?? 'Plumbing';
    final requestedTierId =
        Platform.environment['MAINTAINIAC_PACK_TIER'] ??
        WorkSupplyTradePackTier.full.id;
    final tierId = requestedTierId == 'full'
        ? WorkSupplyTradePackTier.full.id
        : requestedTierId;
    final all = Platform.environment['MAINTAINIAC_PACK_ALL'] == 'true';
    final outPath = Platform.environment['MAINTAINIAC_PACK_OUT'];
    final outDir = outPath == null
        ? await Directory.systemTemp.createTemp(
            'maintainiac_work_supply_trade_packs_',
          )
        : Directory(outPath);
    await outDir.create(recursive: true);

    final options = all
        ? buildAllWorkSupplyDownloadOptions()
        : buildWorkSupplyTradePackOptions(
            trade,
          ).where((option) => option.tier.id == tierId);
    expect(options, isNotEmpty);

    var totalBytes = 0;
    for (final option in options) {
      final fileSet = await WorkSupplyTradePackExportWriter(
        baseDirectory: outDir,
      ).writeTradePack(option: option);
      final validation = await const WorkSupplyTradePackImportValidator()
          .validateDirectory(Directory(fileSet.directoryPath));
      final byteCount = await _totalBytes(fileSet.files);
      totalBytes += byteCount;

      // ignore: avoid_print
      print(
        [
          validation.isReady ? 'READY' : 'FAILED',
          option.displayName,
          'items=${fileSet.manifest.itemCount}',
          'chunks=${fileSet.manifest.chunkCount}',
          'bytes=$byteCount',
          'size=${_byteSizeLabel(byteCount)}',
          'dir=${fileSet.directoryPath}',
        ].join(' | '),
      );
      for (final issue in validation.issues) {
        // ignore: avoid_print
        print('issue: $issue');
      }
      expect(validation.isReady, isTrue);
    }
    // ignore: avoid_print
    print('TOTAL_EXPORT_BYTES=$totalBytes (${_byteSizeLabel(totalBytes)})');
    // ignore: avoid_print
    print('OUTPUT_DIR=${outDir.path}');
  });
}

Future<int> _totalBytes(List<String> paths) async {
  var total = 0;
  for (final path in paths) {
    final file = File(path);
    if (await file.exists()) total += await file.length();
  }
  return total;
}

String _byteSizeLabel(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kib = bytes / 1024;
  if (kib < 1024) return '${kib.toStringAsFixed(1)} KB';
  return '${(kib / 1024).toStringAsFixed(1)} MB';
}
