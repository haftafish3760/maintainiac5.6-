part of '../../receipts/receipt_ocr_contract.dart';

enum ReceiptOcrFieldKind { merchant, date, subtotal, tax, total }

class ReceiptOcrFieldCandidate {
  const ReceiptOcrFieldCandidate({
    required this.kind,
    required this.value,
    required this.sourceText,
    required this.attachmentId,
    required this.pageIndex,
    required this.readingOrder,
    required this.sourceLineIndexes,
    required this.reason,
    this.bounds,
    this.confidence,
  });

  final ReceiptOcrFieldKind kind;
  final String value;
  final String sourceText;
  final String attachmentId;
  final int pageIndex;
  final int readingOrder;
  final List<int> sourceLineIndexes;
  final String reason;
  final ReceiptOcrBounds? bounds;
  final double? confidence;

  bool get needsReview => confidence == null || confidence! < .84;
}

class ReceiptOcrFieldCandidates {
  const ReceiptOcrFieldCandidates(this.all);

  final List<ReceiptOcrFieldCandidate> all;

  List<ReceiptOcrFieldCandidate> forKind(ReceiptOcrFieldKind kind) =>
      List.unmodifiable(all.where((candidate) => candidate.kind == kind));

  ReceiptOcrFieldCandidate? selectedFor(ReceiptOcrFieldKind kind) {
    final candidates = forKind(kind);
    if (candidates.isEmpty) return null;
    return candidates.first;
  }
}

ReceiptOcrFieldCandidates extractReceiptOcrFieldCandidates(
  ReceiptOcrDocument document,
) {
  final candidates = <ReceiptOcrFieldCandidate>[];
  final rows = document.reconstructedRows;
  for (var index = 0; index < rows.length; index++) {
    final row = rows[index];
    final source = row.sourceText;
    final normalized = row.normalizedText.toLowerCase();
    final amount = _receiptOcrLastAmount(source);
    final date = _receiptOcrDate(source);
    if (date != null) {
      candidates.add(
        _fieldCandidate(
          ReceiptOcrFieldKind.date,
          date,
          row,
          'Date-shaped text on receipt line ${row.readingOrder + 1}.',
        ),
      );
    }
    if (amount != null && normalized.contains('subtotal')) {
      candidates.add(
        _fieldCandidate(
          ReceiptOcrFieldKind.subtotal,
          amount,
          row,
          'Amount on a subtotal-labelled receipt line.',
        ),
      );
    }
    if (amount != null && _hasTaxLabel(normalized)) {
      candidates.add(
        _fieldCandidate(
          ReceiptOcrFieldKind.tax,
          amount,
          row,
          'Amount on a tax-labelled receipt line.',
        ),
      );
    }
    if (amount != null &&
        normalized.contains('total') &&
        !normalized.contains('subtotal')) {
      candidates.add(
        _fieldCandidate(
          ReceiptOcrFieldKind.total,
          amount,
          row,
          'Amount on a total-labelled receipt line.',
        ),
      );
    }
    if (index < 4 && _isMerchantHeaderCandidate(normalized, amount, date)) {
      candidates.add(
        _fieldCandidate(
          ReceiptOcrFieldKind.merchant,
          source,
          row,
          'Non-price header text near the top of the receipt.',
        ),
      );
    }
  }
  candidates.sort(_compareReceiptOcrFieldCandidates);
  return ReceiptOcrFieldCandidates(List.unmodifiable(candidates));
}

ReceiptOcrFieldCandidate _fieldCandidate(
  ReceiptOcrFieldKind kind,
  String value,
  ReceiptOcrRow row,
  String reason,
) {
  return ReceiptOcrFieldCandidate(
    kind: kind,
    value: value,
    sourceText: row.sourceText,
    attachmentId: row.attachmentId,
    pageIndex: row.pageIndex,
    readingOrder: row.readingOrder,
    sourceLineIndexes: row.sourceLineIndexes,
    bounds: row.bounds,
    confidence: row.confidence,
    reason: reason,
  );
}

int _compareReceiptOcrFieldCandidates(
  ReceiptOcrFieldCandidate left,
  ReceiptOcrFieldCandidate right,
) {
  final kindOrder = left.kind.index.compareTo(right.kind.index);
  if (kindOrder != 0) return kindOrder;
  final confidenceOrder = (right.confidence ?? -1).compareTo(
    left.confidence ?? -1,
  );
  return confidenceOrder != 0
      ? confidenceOrder
      : left.readingOrder.compareTo(right.readingOrder);
}

String? _receiptOcrDate(String value) {
  final match = RegExp(
    r'\b(?:\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}[/-]\d{1,2}[/-]\d{1,2})\b',
  ).firstMatch(value);
  return match?.group(0);
}

String? _receiptOcrLastAmount(String value) {
  final matches = RegExp(r'\$?\d{1,3}(?:,\d{3})*\.\d{2}\b').allMatches(value);
  return matches.isEmpty ? null : matches.last.group(0);
}

bool _hasTaxLabel(String value) =>
    value.contains('tax') || value.contains('vat') || value.contains('gst');

bool _isMerchantHeaderCandidate(
  String normalized,
  String? amount,
  String? date,
) {
  if (normalized.isEmpty || amount != null || date != null) return false;
  return !normalized.contains('total') &&
      !_hasTaxLabel(normalized) &&
      !normalized.contains('change') &&
      !normalized.contains('cash');
}
