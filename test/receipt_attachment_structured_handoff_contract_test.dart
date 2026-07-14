import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('structured OCR handoff does not require the legacy text callback', () async {
    final source = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart',
    ).readAsString();

    expect(
      source,
      contains(
        'widget.onImportedText == null &&\n            widget.onReceiptOcrReadyForReview == null',
      ),
    );
    expect(
      source,
      contains(
        '? onReceiptOcrReadyForReview(result)\n              : onImportedText!(result.appFillText)',
      ),
    );
  });
}
