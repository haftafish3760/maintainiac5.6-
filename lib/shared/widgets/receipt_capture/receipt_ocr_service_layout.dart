part of 'receipt_ocr_service.dart';

ReceiptOcrPage _receiptOcrLayoutPageFromRecognizedText(
  String attachmentId,
  RecognizedText recognized,
) {
  return ReceiptOcrPage(
    attachmentId: attachmentId,
    blocks: [
      for (final block in recognized.blocks)
        ReceiptOcrBlock(
          text: block.text,
          bounds: _receiptOcrBounds(block.boundingBox),
          lines: [
            for (final line in block.lines)
              ReceiptOcrLine(
                text: line.text,
                bounds: _receiptOcrBounds(line.boundingBox),
                tokens: [
                  for (final token in line.elements)
                    ReceiptOcrToken(
                      text: token.text,
                      bounds: _receiptOcrBounds(token.boundingBox),
                    ),
                ],
              ),
          ],
        ),
    ],
  );
}

ReceiptOcrBounds? _receiptOcrBounds(Rect? bounds) {
  if (bounds == null) return null;
  return ReceiptOcrBounds(
    left: bounds.left,
    top: bounds.top,
    right: bounds.right,
    bottom: bounds.bottom,
  );
}
