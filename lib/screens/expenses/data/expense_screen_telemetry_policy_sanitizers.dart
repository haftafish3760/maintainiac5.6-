part of 'expense_screen_telemetry.dart';

Object? _sanitizeExpenseTelemetryValue(String key, Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is int) {
    if (value < 0) {
      throw ArgumentError.value(value, key, 'Counts must be non-negative.');
    }
    return value;
  }
  if (value is String) {
    if (ExpenseTelemetryPolicy._readableMetadataKeys.contains(key)) {
      return _sanitizeExpenseTelemetryReadableText(key, value);
    }
    return _sanitizeExpenseTelemetryToken(key, value);
  }
  if (value is Map) {
    if (key == 'metadata') {
      return ExpenseTelemetryPolicy.sanitizeMetadata(
        Map<String, Object?>.from(value),
      );
    }
    return _sanitizeExpenseTelemetryTokenMap(
      key,
      Map<String, Object?>.from(value),
    );
  }
  if (value is Iterable) {
    return value
        .map((item) => _sanitizeExpenseTelemetryToken(key, item.toString()))
        .toList(growable: false);
  }
  throw ArgumentError.value(value, key, 'Unsupported telemetry value.');
}

Map<String, Object?> _sanitizeExpenseTelemetryTokenMap(
  String parentKey,
  Map<String, Object?> source,
) {
  final sanitized = <String, Object?>{};
  for (final entry in source.entries) {
    final key = _sanitizeExpenseTelemetryToken(parentKey, entry.key);
    final value = entry.value;
    if (value is bool || value == null) {
      sanitized[key] = value;
    } else if (value is int) {
      if (value < 0) {
        throw ArgumentError.value(value, key, 'Counts must be non-negative.');
      }
      sanitized[key] = value;
    } else if (value is String) {
      sanitized[key] = _sanitizeExpenseTelemetryToken(key, value);
    } else {
      throw ArgumentError.value(value, key, 'Unsupported telemetry value.');
    }
  }
  return Map.unmodifiable(sanitized);
}

String _sanitizeExpenseTelemetryToken(String key, String value) {
  final token = value.trim();
  if (token.isEmpty ||
      token.length > ExpenseTelemetryPolicy.maxStringLength ||
      !ExpenseTelemetryPolicy._safeTokenPattern.hasMatch(token)) {
    throw ArgumentError.value(value, key, 'Unsafe telemetry token.');
  }
  return token;
}

String _sanitizeExpenseTelemetryReadableText(String key, String value) {
  final readable = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (readable.isEmpty ||
      !ExpenseTelemetryPolicy._safeReadableTextPattern.hasMatch(readable)) {
    throw ArgumentError.value(value, key, 'Unsafe telemetry readable text.');
  }
  return readable.length > ExpenseTelemetryPolicy.maxReadableStringLength
      ? readable.substring(0, ExpenseTelemetryPolicy.maxReadableStringLength)
      : readable;
}
