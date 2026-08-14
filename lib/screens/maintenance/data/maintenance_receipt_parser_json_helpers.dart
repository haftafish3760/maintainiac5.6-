part of 'maintenance_receipt_parser.dart';

T? _enumValue<T extends Enum>(List<T> values, Object? raw) {
  final name = '$raw';
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

int? _jsonInt(Object? raw) => raw is int ? raw : int.tryParse('$raw');

int? _jsonNonNegativeInt(Object? raw) {
  if (raw == null) return null;
  final value = _jsonInt(raw);
  if (value == null || value < 0) {
    throw const FormatException('Receipt integer field is invalid.');
  }
  return value;
}

double? _jsonDouble(Object? raw) {
  final value = raw is num ? raw.toDouble() : double.tryParse('$raw');
  return value != null && value.isFinite ? value : null;
}

DateTime? _jsonDate(Object? raw) {
  if (raw == null) return null;
  final value = DateTime.tryParse('$raw');
  if (value == null) throw const FormatException('Receipt date is invalid.');
  return value;
}

String? _jsonNullableString(Object? raw) {
  if (raw == null) return null;
  final value = '$raw'.trim();
  return value.isEmpty ? null : value;
}

List<Map<dynamic, dynamic>> _jsonMaps(Object? raw) {
  if (raw is! Iterable) {
    throw const FormatException('Receipt list is invalid.');
  }
  return [
    for (final value in raw)
      if (value is Map)
        value
      else
        throw const FormatException('Receipt list entry is invalid.'),
  ];
}
