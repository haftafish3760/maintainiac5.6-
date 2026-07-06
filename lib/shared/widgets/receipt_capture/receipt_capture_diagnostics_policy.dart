class ReceiptCaptureDiagnosticPublishPolicy {
  const ReceiptCaptureDiagnosticPublishPolicy();

  bool shouldPublish({
    required bool improvementOptIn,
    required Map<String, Object?> diagnostic,
  }) {
    return improvementOptIn && sanitizedDiagnostic(diagnostic).isNotEmpty;
  }

  Map<String, Object?> sanitizedDiagnostic(Map<String, Object?> diagnostic) {
    final sanitized = <String, Object?>{};
    for (final entry in diagnostic.entries) {
      final key = entry.key.trim();
      if (!_isSafeKey(key)) continue;
      final value = _safeValue(entry.value);
      if (value == null) continue;
      sanitized[key] = value;
    }
    return Map<String, Object?>.unmodifiable(sanitized);
  }

  Map<String, Object?> envelope({
    required bool improvementOptIn,
    required Map<String, Object?> diagnostic,
  }) {
    final safeDiagnostic = sanitizedDiagnostic(diagnostic);
    if (!improvementOptIn || safeDiagnostic.isEmpty) {
      return const {};
    }
    return Map<String, Object?>.unmodifiable({
      'cameraDiagnosticsImprovementOptIn': true,
      'adminDiagnosticOwnerImagePreviewAllowed': false,
      ...safeDiagnostic,
    });
  }

  static final RegExp _safeTokenPattern = RegExp(r'^[A-Za-z0-9_.-]+$');
  static final RegExp _unsafeKeyPattern = RegExp(
    r'(path|receiptText|ocrText|rawText|rawOcr|imageBytes|imageUri|merchantName|storeName|address|phone|email|deviceId|deviceModel|deviceName|rawDevice)',
    caseSensitive: false,
  );

  bool _isSafeKey(String key) {
    return key.isNotEmpty &&
        key.length <= 64 &&
        _safeTokenPattern.hasMatch(key) &&
        !_unsafeKeyPattern.hasMatch(key);
  }

  Object? _safeValue(Object? value) {
    if (value == null || value is bool) return value;
    if (value is num) return value.isFinite ? value : null;
    if (value is String) return _safeString(value);
    if (value is Iterable) {
      final safe = <String>[];
      for (final item in value) {
        final token = _safeString(item?.toString());
        if (token != null) safe.add(token);
      }
      return List<String>.unmodifiable(safe);
    }
    if (value is Map) {
      final safe = <String, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key?.toString().trim() ?? '';
        if (!_isSafeKey(key)) continue;
        final child = _safeValue(entry.value);
        if (child != null) safe[key] = child;
      }
      return Map<String, Object?>.unmodifiable(safe);
    }
    return null;
  }

  String? _safeString(String? value) {
    final token = value?.trim();
    if (token == null ||
        token.isEmpty ||
        token.length > 64 ||
        !_safeTokenPattern.hasMatch(token)) {
      return null;
    }
    return token;
  }
}
