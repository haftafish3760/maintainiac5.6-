import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('final stitching timeout keeps ordered clear sections usable', () {
    final result = ReceiptStitchResult.fallback(
      inputPaths: const ['/tmp/clear-first.jpg', '/tmp/clear-second.jpg'],
      warning: 'Putting these photos together took too long.',
      fallbackReasonCode: 'stitch_timeout',
    );

    expect(result.usedFallback, isTrue);
    expect(result.ocrSourcePaths, result.inputPaths);
    expect(result.hasValidOcrSourceContract, isTrue);
    expect(
      result.userFallbackReasonLabel,
      'Putting photos together took too long',
    );
    expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
  });

  test('receipt review turns a late final stitch into a bounded fallback',
      () async {
    final source = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
    ).readAsString();

    expect(source, contains('final stitchFuture = _finalStitchResultForOcr('));
    expect(source, contains('const Duration(seconds: 15)'));
    expect(source, contains("fallbackReasonCode: 'stitch_timeout'"));
    expect(source, contains('_deleteStitchPreviewPath(lateStitch.stitchedPath)'));
    expect(
      source,
      contains('Receipt details will use them from top to bottom.'),
    );
  });
}
