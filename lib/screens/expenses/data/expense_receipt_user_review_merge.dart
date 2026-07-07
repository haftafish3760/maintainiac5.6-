import 'expense_ledger_models.dart';

List<ExpenseReceiptLineRecord> mergeParsedReceiptLinesWithReviewedLines({
  required List<ExpenseReceiptLineRecord> parsedLines,
  required List<ExpenseReceiptLineRecord> existingLines,
}) {
  final reviewedByKey = <String, ExpenseReceiptLineRecord>{};
  for (final line in existingLines) {
    if (!isUserReviewedAppAssistedReceiptLine(line)) continue;
    final key = _receiptLineMergeKey(line);
    if (key == null) continue;
    reviewedByKey[key] = line;
  }
  return parsedLines
      .map((line) {
        final key = _receiptLineMergeKey(line);
        if (key == null) return line;
        return reviewedByKey[key] ?? line;
      })
      .toList(growable: false);
}

bool isUserReviewedAppAssistedReceiptLine(ExpenseReceiptLineRecord line) {
  if (!_looksAppAssisted(line)) return false;
  final label = (line.parserReviewLabel ?? '').trim().toLowerCase();
  final reason = (line.parserReviewReason ?? '').trim().toLowerCase();
  if (label == 'confirmed' || label == 'corrected') return true;
  if (label == 'good' && reason.startsWith('user ')) return true;
  return reason.startsWith('user reviewed') ||
      reason.startsWith('user confirmed') ||
      reason.startsWith('user marked');
}

bool _looksAppAssisted(ExpenseReceiptLineRecord line) {
  return line.rawReceiptText.trim().isNotEmpty ||
      line.hasParserReview ||
      line.hasOcrSourceLine;
}

String? _receiptLineMergeKey(ExpenseReceiptLineRecord line) {
  final section = line.safeOcrSourceSectionNumber;
  final sectionLine = line.safeOcrSourceSectionLineNumber;
  if (section != null && sectionLine != null) {
    return 'section:$section:$sectionLine';
  }
  final lineNumber = line.safeOcrSourceLineNumber;
  if (lineNumber != null) return 'line:$lineNumber';
  final sourceId = (line.ocrSourceLineId ?? '').trim();
  if (sourceId.isNotEmpty) return 'source:$sourceId';
  return null;
}
