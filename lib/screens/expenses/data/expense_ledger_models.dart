import '../../../shared/receipts/receipt_ocr_contract.dart';
import '../../../shared/widgets/receipt_capture/receipt_capture_models.dart';

part 'expense_line_record.dart';
part 'expense_line_record_serialization.dart';
part 'expense_receipt_duplicate_models.dart';
part 'expense_receipt_ocr_review.dart';
part 'expense_receipt_ocr_review_helpers.dart';
part 'expense_receipt_record.dart';
part 'expense_receipt_record_computed_fields.dart';
part 'expense_receipt_record_serialization.dart';
part 'expense_receipt_draft_record.dart';
part 'expense_ledger_summary.dart';

String _expenseString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return fallback;
}

String? _nullableExpenseString(dynamic value) {
  final text = _expenseString(value).trim();
  return text.isEmpty ? null : text;
}

Map<dynamic, dynamic>? _expenseMap(dynamic value) {
  return value is Map ? value : null;
}

int? _expenseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

double? _expenseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim().replaceAll(',', ''));
  return null;
}

bool _expenseBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == 'yes' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == 'no' || normalized == '0') {
      return false;
    }
  }
  if (value is num) return value != 0;
  return fallback;
}

DateTime? _expenseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
