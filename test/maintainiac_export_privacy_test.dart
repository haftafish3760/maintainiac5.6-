import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('export privacy probe accepts owned non-private records', () {
    const probe = MaintainiacExportPrivacyProbe();
    final failures = probe.validateOwnedExport(
      accountId: 'acct_1',
      records: const [
        {'id': 'expense_1', 'accountId': 'acct_1', 'amountCents': 1200},
        {'id': 'trip_1', 'ownerAccountId': 'acct_1', 'miles': 12},
      ],
    );

    expect(failures, isEmpty);
  });

  test('export privacy probe catches cross-account and private fields', () {
    const probe = MaintainiacExportPrivacyProbe();
    final failures = probe.validateOwnedExport(
      accountId: 'acct_1',
      records: const [
        {
          'id': 'expense_2',
          'accountId': 'acct_2',
          'rawReceiptText': 'private text',
          'cardNumber': '4111111111111111',
        },
      ],
    );

    expect(failures, contains('record_0 account_mismatch'));
    expect(failures, contains('record_0 private_key:rawReceiptText'));
    expect(failures, contains('record_0 private_key:cardNumber'));
  });

  test('export privacy probe sanitizes private fields before writing', () {
    const probe = MaintainiacExportPrivacyProbe();
    final sanitized = probe.sanitizedExportRecord(const {
      'id': 'vehicle_1',
      'accountId': 'acct_1',
      'vin': '1HGCM82633A004352',
      'licensePlate': 'ABC123',
      'miles': 1000,
    });

    expect(sanitized['id'], 'vehicle_1');
    expect(sanitized['miles'], 1000);
    expect(sanitized.containsKey('vin'), isFalse);
    expect(sanitized.containsKey('licensePlate'), isFalse);
  });
}
