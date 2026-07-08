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
}
