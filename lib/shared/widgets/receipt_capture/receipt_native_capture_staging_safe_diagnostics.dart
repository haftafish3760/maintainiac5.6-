part of 'receipt_native_capture_staging.dart';

extension _ReceiptNativeCaptureStagingSafeDiagnostics
    on ReceiptNativeCaptureStaging {
  Map<String, Object?> _jsonSafeDiagnostics(Map<String, Object?> diagnostics) {
    final safe = <String, Object?>{};
    for (final entry in diagnostics.entries) {
      if (!_receiptNativeCaptureSafeDiagnosticKeys.contains(entry.key)) {
        continue;
      }
      final value = entry.value;
      if (value == null ||
          value is String ||
          value is bool ||
          value is List<String>) {
        safe[entry.key] = value;
      } else if (value is num) {
        if (value.isFinite) safe[entry.key] = value;
      } else if (value is Map) {
        final nested = <String, Object?>{};
        for (final nestedEntry in value.entries) {
          final nestedKey = nestedEntry.key;
          final nestedValue = nestedEntry.value;
          if (nestedKey is! String) continue;
          if (nestedValue == null ||
              nestedValue is String ||
              nestedValue is bool) {
            nested[nestedKey] = nestedValue;
          } else if (nestedValue is num && nestedValue.isFinite) {
            nested[nestedKey] = nestedValue;
          }
        }
        if (nested.isNotEmpty) safe[entry.key] = nested;
      } else if (value is Iterable) {
        safe[entry.key] = value.map((item) => item.toString()).toList();
      } else {
        safe[entry.key] = value.toString();
      }
    }
    return safe;
  }
}
