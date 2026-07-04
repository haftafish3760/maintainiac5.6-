import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_image_processor.dart';

import 'helpers/receipt_image_test_fixtures.dart';

void main() {
  test(
    'receipt source prep preserves original-quality OCR source when cleanup is off',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'receipt_original_ocr_guard_',
      );
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final source = await writeReceiptFixtureImage(
        dir,
        'clean_receipt.jpg',
        receiptLikeImage(),
      );
      final sourceBytes = await source.readAsBytes();
      final report = await ReceiptImageProcessor.prepareReceiptSourceWithReport(
        path: source.path,
        cleanupSettings: const ReceiptImageCleanupSettings(
          autoCrop: false,
          autoStraighten: false,
          grayscale: false,
          contrastBoost: false,
          sharpening: false,
          shadowReduction: false,
          adaptiveExposure: false,
          orientationCorrection: false,
        ),
      );
      final ocrBytes = await File(report.ocrSourcePath).readAsBytes();

      expect(report.usedEnhancedOcrSource, isFalse);
      expect(report.ocrSourcePath, isNot(source.path));
      expect(ocrBytes, sourceBytes);
      expect(
        report.cleanupActions,
        contains('temporary_full_quality_source_preserved'),
      );
      expect(
        report.scannerDecisionCodes,
        containsAll([
          'orientation_skipped_setting_off',
          'crop_skipped_setting_off',
          'straighten_skipped_setting_off',
          'perspective_skipped_setting_off',
          'cleanup_skipped_setting_off',
          'ocr_source_full_quality_selected_quality_guard',
        ]),
      );
      expect(report.ocrQuality.reviewScore, report.originalQuality.reviewScore);
      expect(
        report.ocrQuality.textBandScore,
        report.originalQuality.textBandScore,
      );
      expect(report.toDiagnostics().toString(), isNot(contains(source.path)));
    },
  );

  test(
    'receipt source prep reports unreadable source family without crashing',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'receipt_unreadable_source_guard_',
      );
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final empty = File('${dir.path}/empty.jpg')..writeAsBytesSync(const []);
      final corrupt = File('${dir.path}/corrupt.jpg')
        ..writeAsBytesSync([0, 1, 2, 3, 4, 5, 255]);
      final wrongType = File('${dir.path}/not_an_image.txt')
        ..writeAsStringSync('TOTAL 12.34');
      final missingPath = '${dir.path}/deleted_before_ocr.jpg';

      final cases = {
        missingPath: (
          code: 'source_file_unavailable',
          action: 'source_file_unavailable_no_clear_ocr_source',
        ),
        empty.path: (
          code: 'decode_failed',
          action: 'decode_failed_no_clear_ocr_source',
        ),
        corrupt.path: (
          code: 'decode_failed',
          action: 'decode_failed_no_clear_ocr_source',
        ),
        wrongType.path: (
          code: 'decode_failed',
          action: 'decode_failed_no_clear_ocr_source',
        ),
      };

      for (final entry in cases.entries) {
        final report =
            await ReceiptImageProcessor.prepareReceiptSourceWithReport(
              path: entry.key,
            );
        final preview = await ReceiptImageProcessor.previewFile(
          path: entry.key,
          level: ReceiptDataSaverLevel.maximum,
        );
        final quality = await ReceiptImageProcessor.qualityCheckFile(entry.key);

        expect(report.ocrSourcePath, entry.key);
        expect(report.usedEnhancedOcrSource, isFalse);
        expect(report.scannerDecisionCodes, [entry.value.code]);
        expect(report.cleanupActions, [entry.value.action]);
        expect(
          report.cleanupActions.join('|'),
          isNot(contains('original_used')),
        );
        expect(report.originalQuality.isLikelyReadable, isFalse);
        expect(report.ocrQuality.isLikelyReadable, isFalse);
        expect(preview.estimatedBytes, greaterThanOrEqualTo(0));
        expect(preview.quality.isLikelyReadable, isFalse);
        expect(quality.isLikelyReadable, isFalse);
        expect(report.toDiagnostics().toString(), isNot(contains(entry.key)));
      }
    },
  );

  test(
    'receipt safe decoder rejects unreadable byte family without throwing',
    () {
      final cases = [
        Uint8List(0),
        Uint8List.fromList([0, 1, 2, 3, 4, 5, 255]),
        Uint8List.fromList('TOTAL 12.34'.codeUnits),
      ];

      for (final bytes in cases) {
        expect(ReceiptImageProcessor.decodeReceiptImageBytes(bytes), isNull);
      }
    },
  );
}
