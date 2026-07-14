import '../../../shared/widgets/receipt_capture/receipt_ocr_service.dart';
import 'expense_receipt_parser.dart';

/// Uses OCR evidence to preserve what the receipt visibly says in editable
/// review. Parser output may supply missing values, but it must not silently
/// replace the printed merchant wording that the user sees.
ExpenseReceiptParseResult fillMissingExpenseReceiptFieldsFromOcrCandidates(
  ExpenseReceiptParseResult parsed,
  ReceiptOcrDocument document,
) {
  final candidates = document.fieldCandidates;
  final merchant = candidates.selectedFor(ReceiptOcrFieldKind.merchant);
  final date = candidates.selectedFor(ReceiptOcrFieldKind.date);
  final subtotal = candidates.selectedFor(ReceiptOcrFieldKind.subtotal);
  final tax = candidates.selectedFor(ReceiptOcrFieldKind.tax);
  final total = candidates.selectedFor(ReceiptOcrFieldKind.total);
  final merchantEvidence = _candidateDisplayText(merchant);
  final merchantValue = merchantEvidence ?? parsed.merchantName;
  final dateValue = parsed.receiptDate ?? _candidateDate(date);
  final subtotalValue = parsed.enteredSubtotal ?? _candidateAmount(subtotal);
  final taxValue = parsed.enteredTax ?? _candidateAmount(tax);
  final totalValue = parsed.enteredTotal ?? _candidateAmount(total);
  final fieldConfidences = Map<String, ExpenseReceiptFieldConfidence>.of(
    parsed.fieldConfidences,
  );
  _addCandidateConfidence(
    fieldConfidences,
    key: 'merchant',
    candidate: merchantEvidence == null ? null : merchant,
    competingCandidateCount: candidates
        .competingFor(ReceiptOcrFieldKind.merchant)
        .length,
  );
  _addCandidateConfidence(
    fieldConfidences,
    key: 'date',
    candidate: parsed.receiptDate == null && dateValue != null ? date : null,
    competingCandidateCount: candidates
        .competingFor(ReceiptOcrFieldKind.date)
        .length,
  );
  _addCandidateConfidence(
    fieldConfidences,
    key: 'subtotal',
    candidate: parsed.enteredSubtotal == null && subtotalValue != null
        ? subtotal
        : null,
    competingCandidateCount: candidates
        .competingFor(ReceiptOcrFieldKind.subtotal)
        .length,
  );
  _addCandidateConfidence(
    fieldConfidences,
    key: 'tax',
    candidate: parsed.enteredTax == null && taxValue != null ? tax : null,
    competingCandidateCount: candidates
        .competingFor(ReceiptOcrFieldKind.tax)
        .length,
  );
  _addCandidateConfidence(
    fieldConfidences,
    key: 'total',
    candidate: parsed.enteredTotal == null && totalValue != null ? total : null,
    competingCandidateCount: candidates
        .competingFor(ReceiptOcrFieldKind.total)
        .length,
  );
  return parsed.copyWith(
    merchantName: merchantValue,
    receiptDate: dateValue,
    enteredSubtotal: subtotalValue,
    enteredTax: taxValue,
    enteredTotal: totalValue,
    fieldConfidences: Map.unmodifiable(fieldConfidences),
  );
}

void _addCandidateConfidence(
  Map<String, ExpenseReceiptFieldConfidence> confidences, {
  required String key,
  required ReceiptOcrFieldCandidate? candidate,
  required int competingCandidateCount,
}) {
  if (candidate == null) return;
  final confidence = (candidate.confidence ?? .58).clamp(0, 1).toDouble();
  final competingEvidence = competingCandidateCount > 0
      ? '$competingCandidateCount competing receipt '
            'candidate${competingCandidateCount == 1 ? '' : 's'} '
            '${competingCandidateCount == 1 ? 'remains' : 'remain'} available for review. '
      : '';
  confidences[key] = ExpenseReceiptFieldConfidence(
    fieldKey: key,
    confidence: confidence,
    needsReview: true,
    reason:
        '${candidate.reason} $competingEvidence'
        'Confirm against the receipt proof.',
  );
}

String? _candidateDisplayText(ReceiptOcrFieldCandidate? candidate) {
  final value = candidate?.displayText.trim() ?? '';
  return value.isEmpty ? null : value;
}

double? _candidateAmount(ReceiptOcrFieldCandidate? candidate) {
  var value = candidate?.value.replaceAll(RegExp(r'[$,\s]'), '') ?? '';
  final isParentheticalNegative = value.startsWith('(') && value.endsWith(')');
  if (isParentheticalNegative) {
    value = value.substring(1, value.length - 1);
  }
  final amount = double.tryParse(value);
  if (amount == null) return null;
  return isParentheticalNegative ? -amount.abs() : amount;
}

DateTime? _candidateDate(ReceiptOcrFieldCandidate? candidate) {
  final value = candidate?.value ?? '';
  final parts = value.split(RegExp(r'[./-]')).map(int.tryParse).toList();
  if (parts.length != 3 || parts.any((part) => part == null)) return null;
  final first = parts[0]!;
  final second = parts[1]!;
  final third = parts[2]!;
  final year = value.startsWith(RegExp(r'\d{4}'))
      ? first
      : third < 100
      ? 2000 + third
      : third;
  final month = value.startsWith(RegExp(r'\d{4}')) ? second : first;
  final day = value.startsWith(RegExp(r'\d{4}')) ? third : second;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final parsed = DateTime(year, month, day);
  return parsed.month == month && parsed.day == day ? parsed : null;
}
