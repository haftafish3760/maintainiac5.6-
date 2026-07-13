part of '../../receipts/receipt_ocr_contract.dart';

/// Provider-neutral OCR layout. OCR providers may omit bounds or confidence;
/// consumers must preserve that uncertainty rather than inventing values.
class ReceiptOcrDocument {
  const ReceiptOcrDocument({this.pages = const []});

  const ReceiptOcrDocument.empty() : pages = const [];

  final List<ReceiptOcrPage> pages;

  bool get hasLayout => pages.any((page) => page.blocks.isNotEmpty);
  int get lineCount => pages.fold(0, (sum, page) => sum + page.lines.length);
}

class ReceiptOcrPage {
  const ReceiptOcrPage({
    required this.attachmentId,
    this.blocks = const [],
    this.confidence,
  });

  final String attachmentId;
  final List<ReceiptOcrBlock> blocks;
  final double? confidence;

  List<ReceiptOcrLine> get lines => [
    for (final block in blocks) ...block.lines,
  ];
}

class ReceiptOcrBlock {
  const ReceiptOcrBlock({
    required this.text,
    this.bounds,
    this.confidence,
    this.lines = const [],
  });

  final String text;
  final ReceiptOcrBounds? bounds;
  final double? confidence;
  final List<ReceiptOcrLine> lines;
}

class ReceiptOcrLine {
  const ReceiptOcrLine({
    required this.text,
    this.bounds,
    this.confidence,
    this.tokens = const [],
  });

  final String text;
  final ReceiptOcrBounds? bounds;
  final double? confidence;
  final List<ReceiptOcrToken> tokens;
}

class ReceiptOcrToken {
  const ReceiptOcrToken({required this.text, this.bounds, this.confidence});

  final String text;
  final ReceiptOcrBounds? bounds;
  final double? confidence;
}

class ReceiptOcrBounds {
  const ReceiptOcrBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;
}
