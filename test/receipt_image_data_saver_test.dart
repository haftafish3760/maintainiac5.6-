import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_image_processor.dart';

void main() {
  test('receipt data saver levels are receipt backup choices', () {
    expect(ReceiptDataSaverLevel.values.map((level) => level.label), [
      'Original',
      'High Quality',
      'Normal',
      'Low Storage',
      'Tiny Backup',
    ]);
    expect(ReceiptDataSaverLevel.original.usesGrayscale, isFalse);
    expect(ReceiptDataSaverLevel.light.usesGrayscale, isFalse);
    expect(ReceiptDataSaverLevel.balanced.usesGrayscale, isTrue);
    expect(ReceiptDataSaverLevel.strong.usesGrayscale, isTrue);
    expect(ReceiptDataSaverLevel.maximum.usesGrayscale, isTrue);
    expect(
      ReceiptDataSaverLevel.balanced.description,
      contains('backup image'),
    );
    expect(
      ReceiptDataSaverLevel.maximum.description,
      contains('Smallest backup image'),
    );
  });

  test(
    'receipt data saver creates progressively smaller receipt copies',
    () async {
      final dir = await Directory.systemTemp.createTemp('receipt_data_saver_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final source = File('${dir.path}/receipt.jpg');
      await source.writeAsBytes(
        img.encodeJpg(_receiptLikeImage(), quality: 96),
        flush: true,
      );
      final originalBytes = await source.length();

      final balanced = await ReceiptImageProcessor.optimizeFile(
        path: source.path,
        level: ReceiptDataSaverLevel.balanced,
      );
      final maximum = await ReceiptImageProcessor.optimizeFile(
        path: source.path,
        level: ReceiptDataSaverLevel.maximum,
      );

      expect(balanced, isNot(source.path));
      expect(maximum, isNot(source.path));
      expect(await File(balanced).length(), lessThan(originalBytes));
      expect(
        await File(maximum).length(),
        lessThan(await File(balanced).length()),
      );

      final preview = await ReceiptImageProcessor.previewFile(
        path: source.path,
        level: ReceiptDataSaverLevel.maximum,
      );
      expect(preview.level, ReceiptDataSaverLevel.maximum);
      expect(preview.estimatedBytes, lessThan(originalBytes));
    },
  );

  test('receipt image processor creates straightened copies', () async {
    final dir = await Directory.systemTemp.createTemp('receipt_straighten_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    final source = File('${dir.path}/crooked_receipt.jpg');
    await source.writeAsBytes(
      img.encodeJpg(_receiptLikeImage(), quality: 96),
      flush: true,
    );

    final straightened = await ReceiptImageProcessor.rotateFile(
      path: source.path,
      degrees: 1.5,
    );
    final rotated = await ReceiptImageProcessor.rotateFile(
      path: source.path,
      degrees: 90,
    );

    expect(straightened, isNot(source.path));
    expect(rotated, isNot(source.path));
    expect(File(straightened).existsSync(), isTrue);
    expect(File(rotated).existsSync(), isTrue);
    final rotatedImage = img.decodeImage(await File(rotated).readAsBytes());
    expect(rotatedImage, isNotNull);
    expect(rotatedImage!.width, 1800);
    expect(rotatedImage.height, 1200);
  });

  test('receipt source prep creates cropped enhanced OCR copy', () async {
    final dir = await Directory.systemTemp.createTemp('receipt_prep_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    final source = File('${dir.path}/counter_receipt.jpg');
    await source.writeAsBytes(
      img.encodeJpg(_receiptOnCounterImage(), quality: 96),
      flush: true,
    );

    final preparedPath = await ReceiptImageProcessor.prepareReceiptSourceFile(
      path: source.path,
    );
    final prepared = img.decodeImage(await File(preparedPath).readAsBytes());
    final originalQuality = await ReceiptImageProcessor.qualityCheckFile(
      source.path,
    );
    final preparedQuality = await ReceiptImageProcessor.qualityCheckFile(
      preparedPath,
    );

    expect(preparedPath, isNot(source.path));
    expect(prepared, isNotNull);
    expect(prepared!.width, lessThanOrEqualTo(1800));
    expect(prepared.height, lessThanOrEqualTo(2400));
    expect(
      preparedQuality.reviewScore,
      greaterThanOrEqualTo(originalQuality.reviewScore),
    );
    expect(
      preparedQuality.textBandScore,
      greaterThanOrEqualTo(originalQuality.textBandScore),
    );
  });

  test('receipt source prep avoids unsafe off-center auto crop', () async {
    final dir = await Directory.systemTemp.createTemp('receipt_crop_guard_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    final source = File('${dir.path}/tiny_corner_receipt.jpg');
    await source.writeAsBytes(
      img.encodeJpg(_tinyCornerReceiptLikeImage(), quality: 96),
      flush: true,
    );

    final report = await ReceiptImageProcessor.prepareReceiptSourceWithReport(
      path: source.path,
    );
    final prepared = img.decodeImage(
      await File(report.ocrSourcePath).readAsBytes(),
    );

    expect(prepared, isNotNull);
    expect(prepared!.width, 1800);
    expect(prepared.height, 2400);
    expect(
      report.scannerDecisionCodes,
      contains('crop_skipped_bounds_too_small'),
    );
    expect(
      report.toDiagnostics()['scannerDecisionCodes'],
      contains('crop_skipped_bounds_too_small'),
    );
    expect(report.toDiagnostics().toString(), isNot(contains(source.path)));
  });

  test('receipt source prep explains off-center crop rejection', () async {
    final dir = await Directory.systemTemp.createTemp('receipt_crop_offset_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    final source = File('${dir.path}/left_edge_receipt.jpg');
    await source.writeAsBytes(
      img.encodeJpg(_leftEdgeReceiptLikeImage(), quality: 96),
      flush: true,
    );

    final report = await ReceiptImageProcessor.prepareReceiptSourceWithReport(
      path: source.path,
    );

    expect(
      report.scannerDecisionCodes,
      contains('crop_skipped_bounds_off_center_x'),
    );
    expect(
      report.scannerDecisionCodes,
      contains('perspective_skipped_bounds_off_center_x'),
    );
    expect(report.toDiagnostics().toString(), isNot(contains(source.path)));
    expect(report.toDiagnostics().toString(), isNot(contains('receiptText')));
  });

  test(
    'receipt quality check catches dark, glare, and blank captures',
    () async {
      final dir = await Directory.systemTemp.createTemp('receipt_quality_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final readable = await _writeImage(
        dir,
        'readable.jpg',
        _receiptLikeImage(),
      );
      final dark = await _writeImage(dir, 'dark.jpg', _darkReceiptLikeImage());
      final glare = await _writeImage(
        dir,
        'glare.jpg',
        _glareReceiptLikeImage(),
      );
      final blank = await _writeImage(dir, 'blank.jpg', _blankImage());

      final readableQuality = await ReceiptImageProcessor.qualityCheckFile(
        readable.path,
      );
      final darkQuality = await ReceiptImageProcessor.qualityCheckFile(
        dark.path,
      );
      final glareQuality = await ReceiptImageProcessor.qualityCheckFile(
        glare.path,
      );
      final blankQuality = await ReceiptImageProcessor.qualityCheckFile(
        blank.path,
      );

      expect(readableQuality.isLikelyReadable, isTrue);
      expect(readableQuality.reviewScore, greaterThan(darkQuality.reviewScore));
      expect(readableQuality.textBandScore, greaterThan(6));
      expect(darkQuality.isTooDark, isTrue);
      expect(darkQuality.primaryIssueLabel, 'too dark');
      expect(glareQuality.isTooBright, isTrue);
      expect(glareQuality.qualityWarnings.join(' '), contains('bright'));
      expect(blankQuality.isLikelyReadable, isFalse);
      expect(blankQuality.isMissingTextBands, isTrue);
    },
  );

  test(
    'receipt enhancement improves faded thermal and shadowed receipts',
    () async {
      final dir = await Directory.systemTemp.createTemp('receipt_hard_photos_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final faded = await _writeImage(
        dir,
        'faded.jpg',
        _fadedReceiptLikeImage(),
      );
      final thermal = await _writeImage(
        dir,
        'thermal.jpg',
        _thermalReceiptLikeImage(),
      );
      final shadow = await _writeImage(
        dir,
        'shadow.jpg',
        _shadowedReceiptLikeImage(),
      );

      for (final source in [faded, thermal, shadow]) {
        final before = await ReceiptImageProcessor.qualityCheckFile(
          source.path,
        );
        final preparedPath =
            await ReceiptImageProcessor.prepareReceiptSourceFile(
              path: source.path,
            );
        final after = await ReceiptImageProcessor.qualityCheckFile(
          preparedPath,
        );

        expect(preparedPath, isNot(source.path));
        expect(after.reviewScore, greaterThanOrEqualTo(before.reviewScore));
        expect(after.textBandScore, greaterThanOrEqualTo(before.textBandScore));
        expect(after.contrast, greaterThanOrEqualTo(before.contrast * .72));
      }
    },
  );

  test('saved-copy preview quality is measured from the saved copy', () async {
    final dir = await Directory.systemTemp.createTemp('receipt_preview_copy_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    final source = await _writeImage(dir, 'receipt.jpg', _receiptLikeImage());
    final preview = await ReceiptImageProcessor.previewFile(
      path: source.path,
      level: ReceiptDataSaverLevel.maximum,
    );
    final savedCopy = await ReceiptImageProcessor.optimizeFile(
      path: source.path,
      level: ReceiptDataSaverLevel.maximum,
    );
    final savedQuality = await ReceiptImageProcessor.qualityCheckFile(
      savedCopy,
    );

    expect(preview.estimatedBytes, lessThan(await source.length()));
    expect(preview.quality.width, savedQuality.width);
    expect(preview.quality.height, savedQuality.height);
    expect(preview.quality.reviewScore, savedQuality.reviewScore);
  });

  test(
    'receipt preparation keeps OCR source separate from backup copy',
    () async {
      final dir = await Directory.systemTemp.createTemp('receipt_ocr_backup_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final source = await _writeImage(dir, 'receipt.jpg', _receiptLikeImage());
      final prepared = await ReceiptImageProcessor.prepareForOcrAndBackup(
        path: source.path,
        level: ReceiptDataSaverLevel.maximum,
      );

      expect(prepared.ocrSourcePath, isNotEmpty);
      expect(prepared.backupPath, isNotEmpty);
      expect(prepared.usesSeparateBackupCopy, isTrue);
      expect(prepared.preparation.sourcePath, source.path);
      expect(prepared.preparation.ocrSourcePath, prepared.ocrSourcePath);
      expect(prepared.preparation.improvedReviewScore, isTrue);
      expect(prepared.preparation.improvedTextBands, isTrue);
      expect(
        prepared.preparation.toDiagnostics().keys,
        containsAll({
          'usedEnhancedOcrSource',
          'cleanupActions',
          'originalReviewScore',
          'ocrReviewScore',
          'originalTextBandScore',
          'ocrTextBandScore',
        }),
      );
      expect(
        prepared.preparation.toDiagnostics().toString(),
        isNot(contains('LOWE')),
      );
      expect(
        prepared.preparation.toDiagnostics().toString(),
        isNot(contains('receiptText')),
      );
      expect(await File(prepared.ocrSourcePath).exists(), isTrue);
      expect(await File(prepared.backupPath).exists(), isTrue);
      expect(
        await File(prepared.backupPath).length(),
        lessThanOrEqualTo(await File(prepared.ocrSourcePath).length()),
      );
      expect(prepared.quality.reviewScore, greaterThan(0));
    },
  );

  test('receipt source prep reports scanner cleanup decisions', () async {
    final dir = await Directory.systemTemp.createTemp('receipt_prep_report_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    final source = await _writeImage(
      dir,
      'counter_receipt.jpg',
      _receiptOnCounterImage(),
    );

    final report = await ReceiptImageProcessor.prepareReceiptSourceWithReport(
      path: source.path,
    );

    expect(report.sourcePath, source.path);
    expect(report.ocrSourcePath, isNot(source.path));
    expect(await File(report.ocrSourcePath).exists(), isTrue);
    expect(report.originalQuality.reviewScore, greaterThan(0));
    expect(
      report.ocrQuality.reviewScore,
      greaterThanOrEqualTo(report.originalQuality.reviewScore),
    );
    expect(
      report.ocrQuality.textBandScore,
      greaterThanOrEqualTo(report.originalQuality.textBandScore),
    );
    expect(report.cleanupActions, isNotEmpty);
    expect(
      report.cleanupActions,
      anyOf(contains('auto_crop'), contains('scanner_cleanup')),
    );
    expect(report.ocrSourceLabel, contains('OCR source'));
    expect(report.toDiagnostics().toString(), isNot(contains(source.path)));
  });

  test(
    'prepared saved-proof preview matches the final backup pipeline',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'receipt_prepared_preview_',
      );
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final source = await _writeImage(
        dir,
        'receipt_on_counter.jpg',
        _receiptOnCounterImage(),
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

      final source = await _writeImage(
        dir,
        'receipt_on_counter.jpg',
        _receiptOnCounterImage(),
      );
      final enhancedBefore = _tempReceiptArtifactPaths('enhanced');

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

      final leakedEnhanced = _tempReceiptArtifactPaths(
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

      final source = await _writeImage(
        dir,
        'receipt_on_counter.jpg',
        _receiptOnCounterImage(),
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
      expect(report.cleanupActions, contains('original_quality_preserved'));
      expect(
        report.scannerDecisionCodes,
        containsAll({
          'orientation_skipped_setting_off',
          'crop_skipped_setting_off',
          'straighten_skipped_setting_off',
          'perspective_skipped_setting_off',
          'cleanup_skipped_setting_off',
          'ocr_source_original_selected_quality_guard',
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

    final sideways = img.copyRotate(_receiptLikeImage(), angle: 90);
    final source = await _writeImage(dir, 'sideways_receipt.jpg', sideways);

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

Future<File> _writeImage(Directory dir, String name, img.Image image) async {
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(img.encodeJpg(image, quality: 96), flush: true);
  return file;
}

Set<String> _tempReceiptArtifactPaths(String prefix) {
  final needle = 'maintaniac_receipt_${prefix}_';
  return Directory.systemTemp
      .listSync()
      .whereType<File>()
      .map((file) => file.path)
      .where((path) => path.contains(needle))
      .toSet();
}

img.Image _receiptLikeImage() {
  final image = img.Image(width: 1200, height: 1800);
  img.fill(image, color: img.ColorRgb8(246, 245, 238));
  for (var y = 80; y < 1700; y += 44) {
    img.drawLine(
      image,
      x1: 70,
      y1: y,
      x2: 1120,
      y2: y + (y % 3),
      color: img.ColorRgb8(20, 20, 20),
      thickness: 2,
    );
    for (var x = 90; x < 1080; x += 46) {
      if ((x + y) % 5 == 0) continue;
      img.fillRect(
        image,
        x1: x,
        y1: y + 9,
        x2: x + 22,
        y2: y + 20,
        color: img.ColorRgb8(35 + ((x + y) % 50), 35, 35),
      );
    }
  }
  return image;
}

img.Image _receiptOnCounterImage() {
  final image = img.Image(width: 1800, height: 2400);
  img.fill(image, color: img.ColorRgb8(76, 72, 68));
  final receipt = _receiptLikeImage();
  img.compositeImage(image, receipt, dstX: 300, dstY: 280);
  return image;
}

img.Image _tinyCornerReceiptLikeImage() {
  final image = img.Image(width: 1800, height: 2400);
  img.fill(image, color: img.ColorRgb8(64, 61, 58));
  final receipt = img.copyResize(_receiptLikeImage(), width: 360);
  img.compositeImage(image, receipt, dstX: 60, dstY: 90);
  return image;
}

img.Image _leftEdgeReceiptLikeImage() {
  final image = img.Image(width: 1800, height: 2400);
  img.fill(image, color: img.ColorRgb8(64, 61, 58));
  final receipt = img.copyResize(_receiptLikeImage(), width: 760);
  img.compositeImage(image, receipt, dstX: 0, dstY: 320);
  return image;
}

img.Image _darkReceiptLikeImage() {
  final image = _receiptLikeImage();
  for (final pixel in image) {
    pixel
      ..r = (pixel.r * .18).round()
      ..g = (pixel.g * .18).round()
      ..b = (pixel.b * .18).round();
  }
  return image;
}

img.Image _glareReceiptLikeImage() {
  final image = _receiptLikeImage();
  img.fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: image.width,
    y2: image.height,
    color: img.ColorRgb8(250, 250, 246),
  );
  for (var y = 120; y < 1680; y += 64) {
    img.drawLine(
      image,
      x1: 80,
      y1: y,
      x2: 1120,
      y2: y,
      color: img.ColorRgb8(248, 248, 248),
      thickness: 1,
    );
  }
  return image;
}

img.Image _fadedReceiptLikeImage() {
  final image = _receiptLikeImage();
  for (final pixel in image) {
    final luma = (pixel.r * .299 + pixel.g * .587 + pixel.b * .114);
    final faded = (210 + (luma - 128) * .22).round().clamp(0, 255);
    pixel
      ..r = faded
      ..g = faded
      ..b = faded;
  }
  return image;
}

img.Image _thermalReceiptLikeImage() {
  final image = _receiptLikeImage();
  for (final pixel in image) {
    final luma = (pixel.r * .299 + pixel.g * .587 + pixel.b * .114);
    final warm = (190 + (luma - 128) * .34).round().clamp(0, 255);
    pixel
      ..r = (warm + 18).clamp(0, 255)
      ..g = (warm + 6).clamp(0, 255)
      ..b = (warm - 12).clamp(0, 255);
  }
  return image;
}

img.Image _shadowedReceiptLikeImage() {
  final image = _receiptLikeImage();
  for (final pixel in image) {
    final vertical = pixel.y / image.height;
    final horizontal = pixel.x / image.width;
    final shadow = (.42 + vertical * .42 + horizontal * .18).clamp(.38, 1.05);
    pixel
      ..r = (pixel.r * shadow).round().clamp(0, 255)
      ..g = (pixel.g * shadow).round().clamp(0, 255)
      ..b = (pixel.b * shadow).round().clamp(0, 255);
  }
  return image;
}

img.Image _blankImage() {
  final image = img.Image(width: 1200, height: 1800);
  img.fill(image, color: img.ColorRgb8(244, 244, 240));
  return image;
}
