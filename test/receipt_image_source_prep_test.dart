import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_image_processor.dart';

import 'helpers/receipt_image_test_fixtures.dart';

void main() {
  test('receipt source prep creates cropped enhanced OCR copy', () async {
    final dir = await Directory.systemTemp.createTemp('receipt_prep_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    final source = File('${dir.path}/counter_receipt.jpg');
    await source.writeAsBytes(
      img.encodeJpg(receiptOnCounterImage(), quality: 96),
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
      img.encodeJpg(tinyCornerReceiptLikeImage(), quality: 96),
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
      img.encodeJpg(leftEdgeReceiptLikeImage(), quality: 96),
      flush: true,
    );

    final report = await ReceiptImageProcessor.prepareReceiptSourceWithReport(
      path: source.path,
      cleanupSettings: const ReceiptImageCleanupSettings(autoStraighten: true),
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

  test('receipt source prep reports scanner cleanup decisions', () async {
    final dir = await Directory.systemTemp.createTemp('receipt_prep_report_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    final source = await writeReceiptFixtureImage(
      dir,
      'counter_receipt.jpg',
      receiptOnCounterImage(),
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
    expect(report.ocrSourceLabel, contains('receipt photo'));
    expect(report.ocrSourceLabel, isNot(contains('OCR')));
    expect(report.toDiagnostics().toString(), isNot(contains(source.path)));
  });

  test(
    'receipt source prep straightens skewed horizontal text bands',
    () async {
      final dir = await Directory.systemTemp.createTemp('receipt_straighten_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final source = await writeReceiptFixtureImage(
        dir,
        'skewed_receipt.jpg',
        skewedReceiptOnCounterImage(),
      );
      final report = await ReceiptImageProcessor.prepareReceiptSourceWithReport(
        path: source.path,
        cleanupSettings: const ReceiptImageCleanupSettings(
          autoCrop: false,
          autoStraighten: true,
          grayscale: false,
          contrastBoost: false,
          sharpening: false,
          shadowReduction: false,
          adaptiveExposure: false,
        ),
      );

      expect(
        report.scannerDecisionCodes,
        contains('straighten_applied_text_bands'),
      );
      expect(report.cleanupActions, contains('auto_straighten'));
      expect(report.usedEnhancedOcrSource, isTrue);
      expect(await File(report.ocrSourcePath).exists(), isTrue);
    },
  );

  test('receipt source prep rectifies a safe receipt quadrilateral', () async {
    final dir = await Directory.systemTemp.createTemp('receipt_perspective_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final source = await writeReceiptFixtureImage(
      dir,
      'perspective_receipt.jpg',
      perspectiveReceiptOnCounterImage(),
    );
    final report = await ReceiptImageProcessor.prepareReceiptSourceWithReport(
      path: source.path,
      cleanupSettings: const ReceiptImageCleanupSettings(
        autoCrop: false,
        autoStraighten: true,
        grayscale: false,
        contrastBoost: false,
        sharpening: false,
        shadowReduction: false,
        adaptiveExposure: false,
      ),
    );

    expect(
      report.scannerDecisionCodes,
      contains('perspective_applied_safe_quad'),
    );
    expect(report.cleanupActions, contains('perspective_correction'));
    expect(report.usedEnhancedOcrSource, isTrue);
    final prepared = img.decodeImage(
      await File(report.ocrSourcePath).readAsBytes(),
    );
    expect(prepared, isNotNull);
    expect(prepared!.width, greaterThanOrEqualTo(900));
    expect(prepared.height, greaterThan(prepared.width));
    for (final pixel in [
      prepared.getPixel(8, 8),
      prepared.getPixel(prepared.width - 9, 8),
      prepared.getPixel(8, prepared.height - 9),
      prepared.getPixel(prepared.width - 9, prepared.height - 9),
    ]) {
      expect(pixel.r + pixel.g + pixel.b, greaterThan(570));
    }
  });
}
