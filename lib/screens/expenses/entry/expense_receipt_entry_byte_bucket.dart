part of 'expense_receipt_entry_screen.dart';

String _byteBucket(int? bytes) {
  final value = bytes ?? 0;
  if (value <= 0) return 'unknown';
  if (value < 100 * 1024) return 'under_100kb';
  if (value < 500 * 1024) return 'under_500kb';
  if (value < 1024 * 1024) return 'under_1mb';
  if (value < 5 * 1024 * 1024) return 'under_5mb';
  return 'over_5mb';
}
