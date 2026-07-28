import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt OCR uses bounded device-aware timeout recovery', () async {
    final source = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart',
    ).readAsString();

    expect(source, contains('Duration _receiptOcrTimeout('));
    expect(source, contains('ReceiptCapabilityTier.heavyweight => 20'));
    expect(source, contains('ReceiptCapabilityTier.medium => 25'));
    expect(source, contains('ReceiptCapabilityTier.light => 30'));
    expect(source, contains('final pipelineTimeout = _receiptOcrTimeout('));
    expect(
      source,
      contains('final remaining = pipelineTimeout - traceStopwatch.elapsed;'),
    );
    expect(source, contains('if (remaining <= Duration.zero) {'));
    expect(
      source,
      contains("'Receipt detail preparation exceeded the shared deadline.'"),
    );
    expect(source, contains('.timeout('));
    expect(source, contains('on TimeoutException'));
    expect(source, contains('Review the photos and retry'));
  });
}
