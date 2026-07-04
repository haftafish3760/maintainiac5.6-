import 'maintainiac_sensitive_field_registry.dart';

class MaintainiacExportPrivacyProbe {
  const MaintainiacExportPrivacyProbe();

  static const privateKeys = maintainiacSensitiveFieldNames;

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
      if (_isPrivateKey(entry.key)) continue;
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
      if (_isPrivateKey(key)) failures.add('$prefix sensitive_field:$key');
    }
    return failures;
  }

  bool _isPrivateKey(String key) {
    return privateKeys.any(
      (privateKey) =>
          MaintainiacSensitiveFieldRegistry.normalize(privateKey) ==
          MaintainiacSensitiveFieldRegistry.normalize(key),
    );
  }
}

class MaintainiacExportPrivacyCase {
  const MaintainiacExportPrivacyCase({
    required this.id,
    required this.accountId,
    required this.records,
    required this.expectedFailureCount,
    required this.reason,
  });

  final String id;
  final String accountId;
  final List<Map<String, Object?>> records;
  final int expectedFailureCount;
  final String reason;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) {
      failures.add('export privacy case missing id');
    }
    if (accountId.trim().isEmpty) {
      failures.add('$id missing account id');
    }
    if (records.isEmpty) {
      failures.add('$id missing records');
    }
    if (reason.trim().isEmpty) {
      failures.add('$id missing reason');
    }
    final actualFailures = const MaintainiacExportPrivacyProbe()
        .validateOwnedExport(records: records, accountId: accountId)
        .length;
    if (actualFailures != expectedFailureCount) {
      failures.add(
        '$id expected $expectedFailureCount failures got $actualFailures',
      );
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'recordCount': records.length,
      'expectedFailureCount': expectedFailureCount,
      'reason': reason,
    };
  }
}

class MaintainiacExportPrivacyMatrix {
  const MaintainiacExportPrivacyMatrix(this.cases);

  final List<MaintainiacExportPrivacyCase> cases;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    var cleanCaseCount = 0;
    var failingCaseCount = 0;
    for (final entry in cases) {
      if (!ids.add(entry.id)) {
        failures.add('duplicate export privacy case ${entry.id}');
      }
      if (entry.expectedFailureCount == 0) {
        cleanCaseCount += 1;
      } else {
        failingCaseCount += 1;
      }
      failures.addAll(entry.validate());
    }
    if (cleanCaseCount == 0) {
      failures.add('export privacy matrix missing clean case');
    }
    if (failingCaseCount == 0) {
      failures.add('export privacy matrix missing failing case');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'caseCount': cases.length,
      'cases': [for (final entry in cases) entry.toJson()],
    };
  }
}

const maintainiacExportPrivacyMatrix = MaintainiacExportPrivacyMatrix([
  MaintainiacExportPrivacyCase(
    id: 'owned_expense_export_clean',
    accountId: 'acct_1',
    records: [
      {'id': 'expense_1', 'accountId': 'acct_1', 'amountCents': 1200},
      {'id': 'trip_1', 'ownerAccountId': 'acct_1', 'miles': 12},
    ],
    expectedFailureCount: 0,
    reason: 'Owned non-private records are exportable.',
  ),
  MaintainiacExportPrivacyCase(
    id: 'cross_account_private_export_blocked',
    accountId: 'acct_1',
    records: [
      {
        'id': 'expense_2',
        'accountId': 'acct_2',
        'rawReceiptText': 'private text',
        'cardNumber': '4111111111111111',
      },
    ],
    expectedFailureCount: 3,
    reason: 'Cross-account records and private fields are blocked.',
  ),
  MaintainiacExportPrivacyCase(
    id: 'vehicle_identity_export_blocked',
    accountId: 'acct_1',
    records: [
      {
        'id': 'vehicle_1',
        'accountId': 'acct_1',
        'VIN': '1HGCM82633A004352',
        'license_plate': 'ABC123',
      },
    ],
    expectedFailureCount: 2,
    reason: 'Vehicle identity fields are never exportable.',
  ),
]);
