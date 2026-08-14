import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'receipt stitch runtime trace covers evidence registration and result',
    () async {
      final orderEvidence = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_order_evidence.dart',
      ).readAsString();
      final imageProcessor = await File(
        'lib/shared/widgets/receipt_capture/receipt_image_processor.dart',
      ).readAsString();
      final preview = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_preview_async.dart',
      ).readAsString();
      final finalStitch = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_exit_stitch_actions.dart',
      ).readAsString();
      final saveActions = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
      ).readAsString();

      expect(orderEvidence, contains("'stitch_evidence_ready'"));
      expect(orderEvidence, contains('item.positionedLines.length'));
      expect(orderEvidence, contains('evidenceStopwatch.elapsedMilliseconds'));
      expect(imageProcessor, contains("'stitch_registration_ready'"));
      expect(imageProcessor, contains('resolvedNativeProposals.length'));
      expect(imageProcessor, contains("'stitch_finished'"));
      expect(imageProcessor, contains('result.fallbackReasonCode'));
      expect(preview, contains('traceId: _receiptStitchTraceId'));
      expect(finalStitch, contains('copyForFinalOcr'));
      expect(saveActions, contains("'receipt_photo_preparation_started'"));
      expect(
        saveActions,
        contains("'receipt_photo_preparation_ready_for_review'"),
      );
      expect(saveActions, contains('preparationStopwatch.elapsedMilliseconds'));
    },
  );

  test('receipt stitch trace does not send content or file paths', () async {
    final sources = await Future.wait([
      File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_order_evidence.dart',
      ).readAsString(),
      File(
        'lib/shared/widgets/receipt_capture/receipt_image_processor.dart',
      ).readAsString(),
      File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
      ).readAsString(),
    ]);
    final traceCalls = RegExp(
      r'traceReceiptPipelineStage\([\s\S]*?\n\s*\);',
    ).allMatches(sources.join('\n')).map((match) => match.group(0)!).join('\n');

    expect(traceCalls, isNot(contains('line.text')));
    expect(traceCalls, isNot(contains("'receiptText':")));
    expect(traceCalls, isNot(contains("'ocrText':")));
    expect(traceCalls, isNot(contains("'lineText':")));
    expect(traceCalls, isNot(contains('inputPath')));
    expect(traceCalls, isNot(contains('outputPath')));
    expect(traceCalls, isNot(contains('stitchedPath')));
    expect(traceCalls, isNot(contains('ocrSourcePaths')));
  });
}
