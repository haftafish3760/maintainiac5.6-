import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_image_processor.dart';

import 'helpers/receipt_image_test_fixtures.dart';

void main() {
  test('receipt data saver levels are receipt backup choices', () {
    expect(ReceiptDataSaverLevel.values.map((level) => level.label), [
      'Original',
      'High Quality',
      'Normal',
      'Low Storage',
      'Tiny Proof',
    ]);
    expect(ReceiptDataSaverLevel.original.usesGrayscale, isFalse);
    expect(ReceiptDataSaverLevel.light.usesGrayscale, isFalse);
    expect(ReceiptDataSaverLevel.balanced.usesGrayscale, isTrue);
    expect(ReceiptDataSaverLevel.strong.usesGrayscale, isTrue);
    expect(ReceiptDataSaverLevel.maximum.usesGrayscale, isTrue);
    expect(
      ReceiptDataSaverLevel.balanced.description,
      contains('saved proof image'),
    );
    expect(
      ReceiptDataSaverLevel.maximum.description,
      contains('Smallest saved proof image'),
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
        img.encodeJpg(receiptLikeImage(), quality: 96),
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

  test(
    'receipt quality check catches dark, glare, and blank captures',
    () async {
      final dir = await Directory.systemTemp.createTemp('receipt_quality_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final readable = await writeReceiptFixtureImage(
        dir,
        'readable.jpg',
        receiptLikeImage(),
      );
      final dark = await writeReceiptFixtureImage(
        dir,
        'dark.jpg',
        darkReceiptLikeImage(),
      );
      final glare = await writeReceiptFixtureImage(
        dir,
        'glare.jpg',
        glareReceiptLikeImage(),
      );
      final blank = await writeReceiptFixtureImage(
        dir,
        'blank.jpg',
        blankReceiptImage(),
      );

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

      final faded = await writeReceiptFixtureImage(
        dir,
        'faded.jpg',
        fadedReceiptLikeImage(),
      );
      final thermal = await writeReceiptFixtureImage(
        dir,
        'thermal.jpg',
        thermalReceiptLikeImage(),
      );
      final shadow = await writeReceiptFixtureImage(
        dir,
        'shadow.jpg',
        shadowedReceiptLikeImage(),
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

    final source = await writeReceiptFixtureImage(
      dir,
      'receipt.jpg',
      receiptLikeImage(),
    );
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
    'saved-copy preview uses the final adaptive compression result',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'receipt_preview_size_',
      );
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final noisy = img.Image(width: 1800, height: 2500);
      for (var y = 0; y < noisy.height; y++) {
        for (var x = 0; x < noisy.width; x++) {
          final value = (x * 37 + y * 19 + x * y) & 0xff;
          noisy.setPixelRgb(
            x,
            y,
            value,
            (value * 13) & 0xff,
            (value * 29) & 0xff,
          );
        }
      }
      final source = await writeReceiptFixtureImage(dir, 'noisy.jpg', noisy);

      final preview = await ReceiptImageProcessor.previewFile(
        path: source.path,
        level: ReceiptDataSaverLevel.maximum,
      );
      final savedCopy = await ReceiptImageProcessor.optimizeFile(
        path: source.path,
        level: ReceiptDataSaverLevel.maximum,
      );
      addTearDown(() async {
        final saved = File(savedCopy);
        if (await saved.exists()) await saved.delete();
      });

      expect(preview.estimatedBytes, await File(savedCopy).length());
      expect(
        preview.estimatedBytes,
        lessThanOrEqualTo(
          ReceiptDataSaverLevel.maximum.proofTargetSizePolicy.maxBytes,
        ),
      );
    },
  );

  test(
    'receipt preparation keeps OCR source separate from backup copy',
    () async {
      final dir = await Directory.systemTemp.createTemp('receipt_ocr_backup_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final source = await writeReceiptFixtureImage(
        dir,
        'receipt.jpg',
        receiptLikeImage(),
      );
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
          'receiptImageProcessingVersion',
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
      expect(
        prepared.ocrStoragePolicyCode,
        'ocr_clear_source_before_saved_proof_copy',
      );
      expect(
        prepared.ocrStoragePolicyLabel,
        contains('Receipt details use the prepared clear photo'),
      );
      expect(
        prepared.toStorageContractDiagnostics(),
        containsPair('ocrUsesPreparedSourceBeforeSavedProof', true),
      );
      expect(
        prepared.toStorageContractDiagnostics(),
        containsPair('ocrUsesSavedProofFallback', false),
      );
      expect(
        prepared.toStorageContractDiagnostics(),
        containsPair('dataSaverLevel', ReceiptDataSaverLevel.maximum.name),
      );
      expect(
        prepared.toStorageContractDiagnostics(),
        containsPair('usesSeparateBackupCopy', true),
      );
      expect(
        prepared.toStorageContractDiagnostics(),
        containsPair(
          'receiptImageProcessingVersion',
          ReceiptImagePreparationReport.currentProcessingVersion,
        ),
      );
      expect(
        prepared.toStorageContractDiagnostics().toString(),
        isNot(contains(source.path)),
      );
      expect(
        prepared.toStorageContractDiagnostics().toString(),
        isNot(contains('LOWE')),
      );
      expect(prepared.quality.reviewScore, greaterThan(0));
    },
  );
}
