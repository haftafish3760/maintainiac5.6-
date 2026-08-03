part of 'expense_receipt_parser.dart';

/// Restores safe priced OCR item candidates that the generic text parser did
/// not turn into editable receipt lines.
///
/// Recovered lines always require review. This function does not infer a
/// category, classification, quantity, or specialized receipt type.
ExpenseReceiptParseResult recoverMissingOcrItemDrafts(
  ExpenseReceiptParseResult parsed,
  Iterable<ReceiptOcrParserLineDraft> itemDrafts,
) {
  final candidates =
      itemDrafts.where(_isSafeRecoverableOcrItemDraft).toList(growable: false)
        ..sort(
          (left, right) => left.safeLineNumber.compareTo(right.safeLineNumber),
        );
  if (candidates.isEmpty) return parsed;

  final lines = parsed.lines.toList();
  final reviews = parsed.lineReviews.toList();
  var recoveredCount = 0;
  for (final draft in candidates) {
    if (_parsedReceiptAlreadyContainsOcrDraft(lines, draft)) continue;
    final recovered = _recoveredReceiptLineFromOcrDraft(
      draft,
      occupiedIds: lines.map((line) => line.id).toSet(),
    );
    if (recovered == null) continue;
    lines.add(recovered.record);
    reviews.add(recovered.review);
    recoveredCount++;
  }
  if (recoveredCount == 0) return parsed;

  lines.sort(_compareReceiptLinesByOcrSourceOrder);
  final warning = recoveredCount == 1
      ? 'Maintainiac found one additional priced line in the receipt image. Review it before saving.'
      : 'Maintainiac found $recoveredCount additional priced lines in the receipt image. Review them before saving.';
  return parsed.copyWith(
    lines: List.unmodifiable(lines),
    lineReviews: List.unmodifiable(reviews),
    warnings: List.unmodifiable([...parsed.warnings, warning]),
  );
}

bool _isSafeRecoverableOcrItemDraft(ReceiptOcrParserLineDraft draft) {
  final amount = draft.amount;
  if (!draft.isItem || amount == null || !amount.isFinite || amount == 0) {
    return false;
  }
  return draft.traits.contains('safe_terminal_line_amount');
}

bool _parsedReceiptAlreadyContainsOcrDraft(
  List<ExpenseReceiptLineRecord> lines,
  ReceiptOcrParserLineDraft draft,
) {
  final stableId = draft.stableLineId.trim();
  final description = _cleanLineDescription(draft.text);
  final descriptionKey = _receiptRecoveryDescriptionKey(description);
  final amountKey = draft.amount!.toStringAsFixed(2);
  for (final line in lines) {
    if (stableId.isNotEmpty && line.ocrSourceLineId?.trim() == stableId) {
      return true;
    }
    if (line.safeOcrSourceLineNumber == draft.safeLineNumber &&
        line.subtotal.toStringAsFixed(2) == amountKey) {
      return true;
    }
    if (line.subtotal.toStringAsFixed(2) != amountKey) continue;
    final parsedKey = _parsedLineDescriptionKey(line);
    if (descriptionKey.isNotEmpty &&
        (parsedKey == descriptionKey ||
            _parsedLineDescriptionSimilarity(parsedKey, descriptionKey) >=
                .84)) {
      return true;
    }
  }
  return false;
}

_ParsedReceiptLine? _recoveredReceiptLineFromOcrDraft(
  ReceiptOcrParserLineDraft draft, {
  required Set<String> occupiedIds,
}) {
  final description = _cleanLineDescription(draft.text);
  if (description.length < 2) return null;
  final amount = draft.amount!;
  final lineId = _uniqueRecoveredReceiptLineId(draft, occupiedIds);
  final sourceLocation = draft.sourceLocation;
  final confidence = draft.confidence.clamp(0.0, .83).toDouble();
  final reason = draft.reviewReason.trim().isEmpty
      ? 'This priced receipt line needs review before saving.'
      : 'This priced receipt line needs review before saving. ${draft.reviewReason.trim()}';
  final review = ExpenseReceiptLineReview(
    lineId: lineId,
    confidence: confidence,
    needsReview: true,
    reason: reason,
  );
  return _ParsedReceiptLine(
    review: review,
    record: ExpenseReceiptLineRecord(
      id: lineId,
      description: description,
      category: 'Uncategorized',
      use: ExpenseLineUse.unclassified,
      quantity: 1,
      unitsPerPackage: 1,
      unit: 'each',
      subtotal: amount,
      unitPrice: amount,
      rawReceiptText: draft.sourceText,
      sourceReceiptText: draft.sourceText,
      displayReceiptText: description,
      normalizedReceiptText: draft.normalizedText,
      receiptInterpretation: draft.optionalInterpretation ?? '',
      parserConfidence: confidence,
      parserReviewLabel: review.label,
      parserReviewReason: reason,
      parserNeedsReview: true,
      ocrSourceLineId: draft.stableLineId,
      ocrSourceLineNumber: draft.safeLineNumber,
      ocrSourceSectionNumber: sourceLocation?.safeSectionNumber,
      ocrSourceSectionLineNumber: sourceLocation?.safeSectionLineNumber,
      parserExpenseFamily: draft.expenseFamilyToken,
      parserHint: draft.optionalInterpretation,
    ),
  );
}

String _uniqueRecoveredReceiptLineId(
  ReceiptOcrParserLineDraft draft,
  Set<String> occupiedIds,
) {
  final safeToken = draft.stableLineId
      .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '')
      .toUpperCase();
  final base = safeToken.isEmpty
      ? 'OCR-RECOVERED-${draft.safeLineNumber}'
      : 'OCR-RECOVERED-$safeToken';
  if (!occupiedIds.contains(base)) return base;
  var suffix = 2;
  while (occupiedIds.contains('$base-$suffix')) {
    suffix++;
  }
  return '$base-$suffix';
}

int _compareReceiptLinesByOcrSourceOrder(
  ExpenseReceiptLineRecord left,
  ExpenseReceiptLineRecord right,
) {
  const noSource = 1000000;
  final leftLine = left.safeOcrSourceLineNumber ?? noSource;
  final rightLine = right.safeOcrSourceLineNumber ?? noSource;
  final order = leftLine.compareTo(rightLine);
  return order == 0 ? left.id.compareTo(right.id) : order;
}

String _receiptRecoveryDescriptionKey(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}
