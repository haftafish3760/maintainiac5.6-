import '../../../shared/widgets/receipt_capture/receipt_ocr_service.dart';
import 'expense_receipt_parser.dart';

/// Uses OCR evidence only when the receipt parser did not produce a field.
/// Parsed values always win; candidates remain available on the OCR document
/// for editable review and source tracing.
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
  final merchantValue = parsed.merchantName ?? _candidateText(merchant);
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
    candidate: parsed.merchantName == null && merchantValue != null
        ? merchant
        : null,
  );
  _addCandidateConfidence(
    fieldConfidences,
    key: 'date',
    candidate: parsed.receiptDate == null && dateValue != null ? date : null,
  );
  _addCandidateConfidence(
    fieldConfidences,
    key: 'subtotal',
    candidate: parsed.enteredSubtotal == null && subtotalValue != null
        ? subtotal
        : null,
  );
  _addCandidateConfidence(
    fieldConfidences,
    key: 'tax',
    candidate: parsed.enteredTax == null && taxValue != null ? tax : null,
  );
  _addCandidateConfidence(
    fieldConfidences,
    key: 'total',
    candidate: parsed.enteredTotal == null && totalValue != null ? total : null,
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
}) {
  if (candidate == null) return;
  final confidence = (candidate.confidence ?? .58).clamp(0, 1).toDouble();
  confidences[key] = ExpenseReceiptFieldConfidence(
    fieldKey: key,
    confidence: confidence,
    needsReview: true,
    reason: '${candidate.reason} Confirm against the receipt proof.',
  );
}

String? _candidateText(ReceiptOcrFieldCandidate? candidate) {
  final value = candidate?.value.trim() ?? '';
  return value.isEmpty ? null : value;
}

double? _candidateAmount(ReceiptOcrFieldCandidate? candidate) {
  final value = candidate?.value.replaceAll(RegExp(r'[$,\s]'), '') ?? '';
  return double.tryParse(value);
}

DateTime? _candidateDate(ReceiptOcrFieldCandidate? candidate) {
  final value = candidate?.value ?? '';
  final parts = value.split(RegExp(r'[/-]')).map(int.tryParse).toList();
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
