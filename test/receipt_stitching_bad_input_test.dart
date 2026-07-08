import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_stitching_image_helpers.dart';

void main() {
  test('keeps ordered OCR sources when a stitch input cannot decode', () async {
    final valid = await writeTempReceiptStitchingImage(
      receiptStitchingSection(seed: 621, topTextOffset: 0),
      'bad_input_valid_section',
    );
    final empty = File(
      '${Directory.systemTemp.path}/maintainiac_receipt_stitch_empty.jpg',
    );
    await empty.writeAsBytes(const [], flush: true);

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [valid.path, empty.path],
    );

    expect(result.usedFallback, isTrue);
    expect(result.didStitch, isFalse);
    expect(result.fallbackReasonCode, 'decode_failed');
    expect(result.userFallbackReasonLabel, 'One photo could not be read');
    expect(result.ocrSourcePaths, [valid.path, empty.path]);
    expect(result.hasValidOcrSourceContract, isFalse);
    expect(result.ocrSourceContractCode, 'fallback_unreadable_input_source');
    expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
  });

  test('keeps ordered OCR sources when a stitch input is missing', () async {
    final valid = await writeTempReceiptStitchingImage(
      receiptStitchingSection(seed: 622, topTextOffset: 0),
      'bad_input_existing_section',
    );
    final missing =
        '${Directory.systemTemp.path}/maintainiac_receipt_stitch_missing.jpg';
    await File(missing).delete().catchError((_) => File(missing));

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [valid.path, missing],
    );

    expect(result.usedFallback, isTrue);
    expect(result.didStitch, isFalse);
    expect(result.fallbackReasonCode, 'decode_failed');
    expect(result.ocrSourcePaths, [valid.path, missing]);
    expect(result.hasValidOcrSourceContract, isFalse);
    expect(result.ocrSourceContractCode, 'fallback_unreadable_input_source');
    expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
  });

  test('keeps ordered OCR sources when a stitch input is corrupted', () async {
    final valid = await writeTempReceiptStitchingImage(
      receiptStitchingSection(seed: 623, topTextOffset: 0),
      'bad_input_corrupt_valid_section',
    );
    final corrupted = File(
      '${Directory.systemTemp.path}/maintainiac_receipt_stitch_corrupt.jpg',
    );
    await corrupted.writeAsBytes(
      const [0xFF, 0xD8, 0x00, 0x11, 0x22, 0x33, 0x44],
      flush: true,
    );

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [valid.path, corrupted.path],
    );

    expectBadInputFallback(result, [valid.path, corrupted.path]);
  });

  test('keeps ordered OCR sources when a stitch input is the wrong type', () async {
    final valid = await writeTempReceiptStitchingImage(
      receiptStitchingSection(seed: 624, topTextOffset: 0),
      'bad_input_wrong_type_valid_section',
    );
    final wrongType = File(
      '${Directory.systemTemp.path}/maintainiac_receipt_stitch_wrong_type.txt',
    );
    await wrongType.writeAsString('not a receipt image', flush: true);

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [valid.path, wrongType.path],
    );

    expectBadInputFallback(result, [valid.path, wrongType.path]);
  });

  test('keeps non-local stitch input paths review blocked', () async {
    final valid = await writeTempReceiptStitchingImage(
      receiptStitchingSection(seed: 625, topTextOffset: 0),
      'bad_input_non_local_valid_section',
    );
    const nonLocalPath = 'https://example.test/receipt-section.jpg';

    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: [valid.path, nonLocalPath],
    );

    expect(result.usedFallback, isTrue);
    expect(result.didStitch, isFalse);
    expect(result.ocrSourcePaths, [valid.path, nonLocalPath]);
    expect(result.hasValidOcrSourceContract, isFalse);
    expect(result.ocrSourceContractCode, 'fallback_invalid_input_sources');
    expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
    expect(
      result.assistedReadinessCode,
      'stitch_contract_review_required',
    );
  });
}

void expectBadInputFallback(ReceiptStitchResult result, List<String> paths) {
  expect(result.usedFallback, isTrue);
  expect(result.didStitch, isFalse);
  expect(result.fallbackReasonCode, 'decode_failed');
  expect(result.userFallbackReasonLabel, 'One photo could not be read');
  expect(result.ocrSourcePaths, paths);
  expect(result.hasValidOcrSourceContract, isFalse);
  expect(result.ocrSourceContractCode, 'fallback_unreadable_input_source');
  expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
}
