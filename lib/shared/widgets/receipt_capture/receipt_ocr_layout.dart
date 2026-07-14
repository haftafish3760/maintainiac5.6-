part of '../../receipts/receipt_ocr_contract.dart';

/// Provider-neutral OCR layout. OCR providers may omit bounds or confidence;
/// consumers must preserve that uncertainty rather than inventing values.
class ReceiptOcrDocument {
  const ReceiptOcrDocument({
    this.pages = const [],
    this.engineIdentity = 'unknown',
    this.processingVersion = 'unknown',
  });

  const ReceiptOcrDocument.empty()
    : pages = const [],
      engineIdentity = 'unknown',
      processingVersion = 'unknown';

  final List<ReceiptOcrPage> pages;
  final String engineIdentity;
  final String processingVersion;

  bool get hasLayout => pages.any((page) => page.blocks.isNotEmpty);
  int get lineCount => pages.fold(0, (sum, page) => sum + page.lines.length);
  List<ReceiptOcrRow> get reconstructedRows => reconstructReceiptOcrRows(this);
}

class ReceiptOcrPage {
  const ReceiptOcrPage({
    required this.attachmentId,
    this.pageIndex = 0,
    this.blocks = const [],
    this.confidence,
    this.sourceImageReference,
    this.orientationDegrees,
  });

  final String attachmentId;
  final int pageIndex;
  final List<ReceiptOcrBlock> blocks;
  final double? confidence;
  final String? sourceImageReference;
  final int? orientationDegrees;

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

  String get sourceText => text;
  String get displayText => text;
  String get normalizedText => _normalizeReceiptOcrEvidenceText(text);
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

  String get sourceText => text;
  String get displayText => text;
  String get normalizedText => _normalizeReceiptOcrEvidenceText(text);
}

class ReceiptOcrToken {
  const ReceiptOcrToken({required this.text, this.bounds, this.confidence});

  final String text;
  final ReceiptOcrBounds? bounds;
  final double? confidence;

  String get sourceText => text;
  String get displayText => text;
  String get normalizedText => _normalizeReceiptOcrEvidenceText(text);
}

String _normalizeReceiptOcrEvidenceText(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ');
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
