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
    this.sourceTokenReferences = const [],
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
  final List<ReceiptOcrTokenReference> sourceTokenReferences;
  final String reason;
  final ReceiptOcrBounds? bounds;
  final double? confidence;

  /// The receipt wording shown to the user. Candidate values never replace it.
  String get displayText => sourceText;
  String get normalizedText => _normalizeReceiptOcrEvidenceText(sourceText);
  String? get optionalInterpretation => value == sourceText ? null : value;
  double? get interpretationConfidence =>
      optionalInterpretation == null ? null : confidence;
  bool get needsReview => _receiptOcrEvidenceNeedsReview(confidence);
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

  /// Keeps the non-selected evidence available to an editable review instead
  /// of discarding a plausible competing merchant, date, or amount.
  List<ReceiptOcrFieldCandidate> competingFor(ReceiptOcrFieldKind kind) {
    final candidates = forKind(kind);
    if (candidates.length < 2) return const [];
    return List.unmodifiable(candidates.skip(1));
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
    if (amount != null && _hasSubtotalLabel(normalized)) {
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
    if (amount != null && _hasTotalLabel(normalized)) {
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
    sourceTokenReferences: row.sourceTokenReferences,
    bounds: row.bounds,
    confidence: row.confidence,
    reason: '$reason Source receipt line ${row.readingOrder + 1}.',
  );
}

int _compareReceiptOcrFieldCandidates(
  ReceiptOcrFieldCandidate left,
  ReceiptOcrFieldCandidate right,
) {
  final kindOrder = left.kind.index.compareTo(right.kind.index);
  if (kindOrder != 0) return kindOrder;
  // A merchant header is normally the first eligible receipt row. Its OCR
  // confidence is not a reliable substitute for that document position.
  if (left.kind == ReceiptOcrFieldKind.merchant) {
    final readingOrder = left.readingOrder.compareTo(right.readingOrder);
    if (readingOrder != 0) return readingOrder;
  }
  final confidenceOrder = (right.confidence ?? -1).compareTo(
    left.confidence ?? -1,
  );
  return confidenceOrder != 0
      ? confidenceOrder
      : left.readingOrder.compareTo(right.readingOrder);
}

String? _receiptOcrDate(String value) {
  final match = RegExp(
    r'\b(?:\d{1,2}[./-]\d{1,2}[./-]\d{2,4}|\d{4}[./-]\d{1,2}[./-]\d{1,2})\b',
  ).firstMatch(value);
  final candidate = match?.group(0);
  if (candidate == null || !_isCalendarDateCandidate(candidate)) return null;
  return candidate;
}

bool _isCalendarDateCandidate(String value) {
  final parts = value.split(RegExp(r'[./-]'));
  if (parts.length != 3) return false;
  final numbers = parts.map(int.tryParse).toList(growable: false);
  if (numbers.any((number) => number == null)) return false;
  final first = numbers[0]!;
  final second = numbers[1]!;
  final third = numbers[2]!;
  final yearFirst = parts[0].length == 4;
  final year = yearFirst
      ? first
      : third < 100
      ? 2000 + third
      : third;
  final month = yearFirst ? second : first;
  final day = yearFirst ? third : second;
  if (year < 1900 || month < 1 || month > 12 || day < 1) return false;
  return day <= DateTime(year, month + 1, 0).day;
}

String? _receiptOcrLastAmount(String value) {
  final matches = RegExp(
    r'(?:-\$?\d{1,3}(?:,\d{3})*\.\d{2}|\$-\d{1,3}(?:,\d{3})*\.\d{2}|\(\$?\d{1,3}(?:,\d{3})*\.\d{2}\)|\$?\d{1,3}(?:,\d{3})*\.\d{2}|\$\d{1,3}(?:,\d{3})*)(?=\s|$|[^\d.])',
  ).allMatches(value);
  return matches.isEmpty ? null : matches.last.group(0);
}

bool _hasTaxLabel(String value) =>
    value.contains('tax') ||
    value.contains('vat') ||
    value.contains('gst') ||
    value.contains('hst') ||
    value.contains('pst');

bool _hasSubtotalLabel(String value) =>
    RegExp(r'\bsub\s*total\b').hasMatch(value);

bool _hasTotalLabel(String value) {
  if (value.contains('discount') ||
      value.contains('savings') ||
      value.contains('you saved')) {
    return false;
  }
  return (value.contains('total') && !_hasSubtotalLabel(value)) ||
      value.contains('amount due') ||
      value.contains('balance due');
}

bool _isMerchantHeaderCandidate(
  String normalized,
  String? amount,
  String? date,
) {
  if (normalized.isEmpty || amount != null || date != null) return false;
  if (RegExp(
        r'^\d{1,6}\s+\S+\s+(?:st|street|rd|road|ave|avenue|blvd|lane|ln|dr|drive)\b',
      ).hasMatch(normalized) ||
      RegExp(r'\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}').hasMatch(normalized) ||
      normalized.contains('www.') ||
      normalized.contains('@') ||
      normalized.startsWith('store #')) {
    return false;
  }
  return !normalized.contains('total') &&
      !_hasTaxLabel(normalized) &&
      !normalized.contains('change') &&
      !normalized.contains('cash') &&
      !normalized.contains('cashier') &&
      !normalized.contains('register') &&
      !normalized.contains('welcome') &&
      !normalized.contains('thank you');
}
