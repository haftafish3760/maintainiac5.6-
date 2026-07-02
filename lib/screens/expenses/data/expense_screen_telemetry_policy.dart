part of 'expense_screen_telemetry.dart';

class ExpenseTelemetryPolicy {
  const ExpenseTelemetryPolicy._();

  static const allowedKeys = <String>{
    'event',
    'appVersion',
    'platform',
    'deviceTier',
    'profileType',
    'storageMode',
    'planStatus',
    'connectionStatus',
    'durationMs',
    'validationErrorKind',
    'failureKind',
    'workflowStep',
    'failedAt',
    'confirmedCause',
    'causeStatus',
    'evidence',
    'missingEvidence',
    'retryCount',
    'abandoned',
    'categoryGroup',
    'metadata',
  };

  static const allowedMetadataKeys = _expenseTelemetryAllowedMetadataKeys;

  static const blockedSensitiveKeys = _expenseTelemetryBlockedSensitiveKeys;

  static const maxStringLength = 64;
  static const maxReadableStringLength = 360;
  static final _safeTokenPattern = RegExp(r'^[A-Za-z0-9_.-]+$');
  static final _safeReadableTextPattern = RegExp(r'^[A-Za-z0-9_ .,;:/()%-]+$');
  static const _readableMetadataKeys = {
    'userFacingPackDisclosureLabel',
    'receiptBrainFirstInstallBoundarySummary',
    'receiptInstallUserFacingSummary',
  };

  static Map<String, Object?> sanitize(ExpenseTelemetryEvent event) {
    return sanitizeMap(event.toMap());
  }

  static Map<String, Object?> sanitizeMap(Map<String, Object?> source) {
    final sanitized = <String, Object?>{};
    for (final entry in source.entries) {
      final key = entry.key;
      if (blockedSensitiveKeys.contains(key)) {
        throw ArgumentError.value(
          key,
          'key',
          'Private expense content is not allowed in telemetry.',
        );
      }
      if (!allowedKeys.contains(key)) continue;
      sanitized[key] = _sanitizeExpenseTelemetryValue(key, entry.value);
    }
    return Map.unmodifiable(sanitized);
  }

  static Map<String, Object?> sanitizeMetadata(Map<String, Object?> source) {
    final sanitized = <String, Object?>{};
    for (final entry in source.entries) {
      final key = entry.key;
      if (blockedSensitiveKeys.contains(key)) {
        throw ArgumentError.value(
          key,
          'metadata',
          'Private expense content is not allowed in telemetry.',
        );
      }
      if (!allowedMetadataKeys.contains(key)) continue;
      sanitized[key] = _sanitizeExpenseTelemetryValue(key, entry.value);
    }
    return Map.unmodifiable(sanitized);
  }
}
