part of 'expense_receipt_parser.dart';

DateTime? _readDate(List<String> rows) {
  for (final row in rows) {
    final normalized = _normalizeReceiptDateText(row);
    final match = _datePattern.firstMatch(normalized);
    if (match == null) continue;
    final raw = match.group(0)!;
    final parts = raw.split(RegExp(r'[./-]')).map(int.parse).toList();
    if (raw.startsWith(RegExp(r'\d{4}'))) {
      return _safeDate(parts[0], parts[1], parts[2]);
    }
    final year = parts[2] < 100 ? 2000 + parts[2] : parts[2];
    return _safeDate(year, parts[0], parts[1]);
  }
  return null;
}

String _normalizeReceiptDateText(String row) {
  return row
      .replaceAll(RegExp(r'[oO]'), '0')
      .replaceAll(RegExp(r'[iIl!|]'), '1')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

DateTime? _safeDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return DateTime(year, month, day);
}

int? _readTimeMinutes(List<String> rows) {
  for (final row in rows) {
    final match = _receiptTimeCandidateMatchForRow(row);
    if (match == null) continue;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(3)!);
    final marker = _normalizeReceiptTimeMarker(match.group(4));
    if (marker == 'pm' && hour < 12) hour += 12;
    if (marker == 'am' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;
    return hour * 60 + minute;
  }
  return null;
}

bool _hasReceiptTimeCandidateRow(String row) {
  return _receiptTimeCandidateMatchForRow(row) != null;
}

RegExpMatch? _receiptTimeCandidateMatchForRow(String row) {
  if (_looksLikeMetadataOnlyTimeFalsePositiveRow(row)) return null;
  final timeSource = _receiptTimeSourceText(row);
  final match = _timePattern.firstMatch(timeSource);
  if (match == null) return null;
  final hour = int.tryParse(match.group(1) ?? '');
  final separator = match.group(2);
  final minute = int.tryParse(match.group(3) ?? '');
  final marker = _normalizeReceiptTimeMarker(match.group(4));
  if (hour == null || minute == null) return null;
  if (separator == '.' &&
      marker == null &&
      !_datePattern.hasMatch(_normalizeReceiptDateText(row))) {
    return null;
  }
  if (hour > 23 || minute > 59) return null;
  return match;
}

String _receiptTimeSourceText(String row) {
  return _normalizeReceiptTimeText(row).replaceAll(_datePattern, ' ');
}

String _normalizeReceiptTimeText(String row) {
  return row
      .replaceAll(RegExp(r'[oO]'), '0')
      .replaceAll(RegExp(r'[iIl!|]'), '1')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String? _normalizeReceiptTimeMarker(String? marker) {
  if (marker == null) return null;
  final normalized = marker.toLowerCase().replaceAll('.', '');
  if (normalized == 'am' || normalized == 'pm') return normalized;
  return null;
}

bool _looksLikeMetadataOnlyTimeFalsePositiveRow(String row) {
  if (_datePattern.hasMatch(_normalizeReceiptTimeText(row))) return false;
  return RegExp(
    r'\b(auth(?:code)?|authorization|approval|batch|invoice|order|ref(?:erence)?|terminal|trace|transaction|trans#?|trans)\b',
    caseSensitive: false,
  ).hasMatch(row);
}
