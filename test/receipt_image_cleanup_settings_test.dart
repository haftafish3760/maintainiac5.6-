import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_image_processor.dart';

import 'helpers/receipt_image_test_fixtures.dart';

void main() {
  test(
    'prepared saved-proof preview matches the final backup pipeline',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'receipt_prepared_preview_',
      );
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final source = await writeReceiptFixtureImage(
        dir,
        'receipt_on_counter.jpg',
        receiptOnCounterImage(),
      );

      final preview = await ReceiptImageProcessor.previewPreparedBackupFile(
        path: source.path,
        level: ReceiptDataSaverLevel.maximum,
      );
      final prepared = await ReceiptImageProcessor.prepareForOcrAndBackup(
        path: source.path,
        level: ReceiptDataSaverLevel.maximum,
      );
      final backupQuality = await ReceiptImageProcessor.qualityCheckFile(
        prepared.backupPath,
      );

      expect(prepared.ocrSourcePath, isNot(prepared.backupPath));
      expect(preview.level, ReceiptDataSaverLevel.maximum);
      expect(preview.estimatedBytes, await File(prepared.backupPath).length());
      expect(preview.quality.width, backupQuality.width);
      expect(preview.quality.height, backupQuality.height);
      expect(
        (preview.quality.reviewScore - backupQuality.reviewScore).abs(),
        lessThanOrEqualTo(1),
      );
      expect(
        prepared.quality.reviewScore,
        greaterThanOrEqualTo(backupQuality.reviewScore),
      );
    },
  );

  test(
    'prepared backup preview cleans temporary OCR source artifacts',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'receipt_prepared_cleanup_',
      );
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final source = await writeReceiptFixtureImage(
        dir,
        'receipt_on_counter.jpg',
        receiptOnCounterImage(),
      );
      final enhancedBefore = tempReceiptArtifactPaths('enhanced');

      final preview = await ReceiptImageProcessor.previewPreparedBackupFile(
        path: source.path,
        level: ReceiptDataSaverLevel.strong,
      );
      final backupPath = await ReceiptImageProcessor.optimizePreparedBackupFile(
        path: source.path,
        level: ReceiptDataSaverLevel.strong,
      );
      addTearDown(() async {
        final backup = File(backupPath);
        if (await backup.exists()) await backup.delete();
      });

      final leakedEnhanced = tempReceiptArtifactPaths(
        'enhanced',
      ).difference(enhancedBefore);
      expect(preview.estimatedBytes, greaterThan(0));
      expect(await File(backupPath).exists(), isTrue);
      expect(backupPath, contains('maintaniac_receipt_optimized_'));
      expect(leakedEnhanced, isEmpty);
    },
  );

  test('native cleanup diagnostics become OCR prep settings', () {
    final settings = ReceiptImageCleanupSettings.fromDiagnostics({
      'autoCropSuggestionEnabled': false,
      'perspectiveCorrectionEnabled': 0,
      'grayscalePreviewEnabled': 'false',
      'contrastBoostEnabled': 'true',
      'sharpeningEnabled': 1,
      'shadowReductionEnabled': 'no',
      'adaptiveThresholdEnabled': 'yes',
      'orientationCorrectionEnabled': false,
    });

    expect(settings.autoCrop, isFalse);
    expect(settings.autoStraighten, isFalse);
    expect(settings.grayscale, isFalse);
    expect(settings.contrastBoost, isTrue);
    expect(settings.sharpening, isTrue);
    expect(settings.shadowReduction, isFalse);
    expect(settings.adaptiveExposure, isTrue);
    expect(settings.orientationCorrection, isFalse);
    expect(
      settings.enabledDiagnosticLabels,
      containsAll({'contrast_boost_enabled', 'adaptive_exposure_enabled'}),
    );
    expect(
      settings.enabledDiagnosticLabels,
      isNot(contains('auto_crop_enabled')),
    );
  });

  test(
    'receipt prep can preserve original-quality source when cleanup is off',
    () async {
      final dir = await Directory.systemTemp.createTemp('receipt_cleanup_off_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final source = await writeReceiptFixtureImage(
        dir,
        'receipt_on_counter.jpg',
        receiptOnCounterImage(),
      );

      const cleanupOff = ReceiptImageCleanupSettings(
        autoCrop: false,
        autoStraighten: false,
        grayscale: false,
        contrastBoost: false,
        sharpening: false,
        shadowReduction: false,
        adaptiveExposure: false,
        orientationCorrection: false,
      );
      final report = await ReceiptImageProcessor.prepareReceiptSourceWithReport(
        path: source.path,
        cleanupSettings: cleanupOff,
      );

      expect(report.ocrSourcePath, isNot(source.path));
      expect(await File(report.ocrSourcePath).exists(), isTrue);
      expect(report.usedEnhancedOcrSource, isFalse);
      expect(
        report.cleanupActions,
        contains('temporary_full_quality_source_preserved'),
      );
      expect(
        report.scannerDecisionCodes,
        containsAll({
          'orientation_skipped_setting_off',
          'crop_skipped_setting_off',
          'straighten_skipped_setting_off',
          'perspective_skipped_setting_off',
          'cleanup_skipped_setting_off',
          'ocr_source_full_quality_selected_quality_guard',
        }),
      );
      expect(report.cleanupActions, isNot(contains('scanner_cleanup')));
      expect(report.cleanupActions, isNot(contains('auto_crop_enabled')));
      expect(report.toDiagnostics().toString(), isNot(contains(source.path)));
      expect(report.toDiagnostics().toString(), isNot(contains('receiptText')));
    },
  );

  test('receipt prep can auto-orient an obvious sideways receipt', () async {
    final dir = await Directory.systemTemp.createTemp('receipt_auto_orient_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    final sideways = img.copyRotate(receiptLikeImage(), angle: 90);
    final source = await writeReceiptFixtureImage(
      dir,
      'sideways_receipt.jpg',
      sideways,
    );

    const orientationOnly = ReceiptImageCleanupSettings(
      autoCrop: false,
      autoStraighten: false,
      grayscale: false,
      contrastBoost: false,
      sharpening: false,
      shadowReduction: false,
      adaptiveExposure: false,
      orientationCorrection: true,
    );
    final report = await ReceiptImageProcessor.prepareReceiptSourceWithReport(
      path: source.path,
      cleanupSettings: orientationOnly,
    );
    final preparedImage = img.decodeImage(
      await File(report.ocrSourcePath).readAsBytes(),
    );

    expect(preparedImage, isNotNull);
    expect(preparedImage!.height, greaterThan(preparedImage.width));
    expect(report.cleanupActions, contains('auto_orient'));
    expect(report.cleanupActions, contains('orientation_cleanup_enabled'));
    expect(
      report.scannerDecisionCodes,
      contains('orientation_applied_portrait_receipt'),
    );
    expect(report.usedEnhancedOcrSource, isTrue);
    expect(report.toDiagnostics().toString(), isNot(contains(source.path)));
  });
}
