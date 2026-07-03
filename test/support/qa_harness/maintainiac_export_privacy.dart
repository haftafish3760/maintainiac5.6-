class MaintainiacExportPrivacyProbe {
  const MaintainiacExportPrivacyProbe();

  static const privateKeys = {
    'vin',
    'plate',
    'licensePlate',
    'passenger',
    'patient',
    'ssn',
    'taxId',
    'cardNumber',
    'rawReceiptText',
  };

  List<String> validateOwnedExport({
    required Iterable<Map<String, Object?>> records,
    required String accountId,
  }) {
    final failures = <String>[];
    var index = 0;
    for (final record in records) {
      final owner = record['accountId'] ?? record['ownerAccountId'];
      if (owner != accountId) {
        failures.add('record_$index account_mismatch');
      }
      failures.addAll(_privateKeyFailures(record, 'record_$index'));
      index++;
    }
    return failures;
  }

  Map<String, Object?> sanitizedExportRecord(Map<String, Object?> record) {
    final sanitized = <String, Object?>{};
    for (final entry in record.entries) {
      if (privateKeys.contains(entry.key)) continue;
      sanitized[entry.key] = entry.value;
    }
    return sanitized;
  }

  List<Map<String, Object?>> sanitizeExport(
    Iterable<Map<String, Object?>> records,
  ) {
    return [for (final record in records) sanitizedExportRecord(record)];
  }

  List<String> _privateKeyFailures(Map<String, Object?> record, String prefix) {
    final failures = <String>[];
    for (final key in record.keys) {
      if (privateKeys.contains(key)) failures.add('$prefix private_key:$key');
    }
    return failures;
  }
}
