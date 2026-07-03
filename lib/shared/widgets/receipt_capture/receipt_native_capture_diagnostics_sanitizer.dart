Map<String, Object?> receiptNativeCaptureSanitizedDiagnostics(
  Object? rawDiagnostics,
) {
  if (rawDiagnostics is! Map) return <String, Object?>{};
  final diagnostics = <String, Object?>{};
  for (final entry in rawDiagnostics.entries) {
    final key = entry.key;
    if (key is! String || key.trim().isEmpty) continue;
    final value = _safeNativeDiagnosticValue(entry.value);
    if (value != null) diagnostics[key] = value;
  }
  return diagnostics;
}

Object? _safeNativeDiagnosticValue(Object? value) {
  if (value == null || value is String || value is bool) return value;
  if (value is num) return value.isFinite ? value : null;
  if (value is Map) {
    final nested = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String || key.trim().isEmpty) continue;
      final nestedValue = _safeNativeDiagnosticValue(entry.value);
      if (nestedValue != null) nested[key] = nestedValue;
    }
    return nested.isEmpty ? null : nested;
  }
  if (value is Iterable) {
    final safeItems = <Object>[];
    for (final item in value) {
      final safeItem = _safeNativeDiagnosticValue(item);
      if (safeItem != null) safeItems.add(safeItem);
    }
    return safeItems.isEmpty ? null : safeItems;
  }
  return value.toString();
}
