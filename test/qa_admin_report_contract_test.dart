import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('adminHealth reports blocked, warning, and passing states safely', () {
    final blocked = _reportWith(
      const QaFailure(
        suite: 'inventory.security_privacy',
        id: 'hostile_input',
        message: 'parser rejected private payload',
        severity: QaSeverity.critical,
        actual:
            'raw receipt for John Contractor phone 804-555-1212 '
            'card 4111111111111111 device serial ABC123',
        metadata: {
          'rawReceiptLine': 'LOWES receipt ABC123',
          'customerName': 'John Contractor',
          'fullDeviceSerial': 'ABC123',
          'deviceModelBucket': 'samsung_s24_ultra',
        },
      ),
    );
    final warningOnly = _reportWith(
      const QaFailure(
        suite: 'inventory.runtime_measurement',
        id: 'slow_suite_probe',
        message: 'runtime budget warning',
        severity: QaSeverity.warning,
        metadata: {'deviceClass': 'modern_high'},
      ),
    );
    final passing = _reportWith();

    expect(blocked.adminHealth['status'], 'blocked');
    expect(blocked.adminHealth['blockingFailureCount'], 1);
    expect(
      blocked.adminHealth['failuresByTriageCategory'],
      contains('security'),
    );
    expect(warningOnly.adminHealth['status'], 'needs review');
    expect(warningOnly.adminHealth['blockingFailureCount'], 0);
    expect(passing.adminHealth['status'], 'passing');
    expect(passing.adminHealth['actualFailureCount'], 0);

    final adminJson = jsonEncode(const QaRedactor().value(blocked.adminHealth));
    expect(adminJson, isNot(contains('John Contractor')));
    expect(adminJson, isNot(contains('804-555-1212')));
    expect(adminJson, isNot(contains('4111111111111111')));
    expect(adminJson, isNot(contains('ABC123')));
    expect(adminJson, isNot(contains('samsung_s24_ultra')));
    expect(adminJson, isNot(contains('rawReceiptLine')));
    expect(adminJson, isNot(contains('fullDeviceSerial')));
  });

  test('admin summary contains rollups but not private receipt details', () {
    final report = _reportWith(
      const QaFailure(
        suite: 'inventory.fixture_governance',
        id: 'privacy_fixture_probe',
        message: 'fixture must stay privacy safe',
        severity: QaSeverity.error,
        expected: 'privacy-safe fixture',
        actual:
            'customer Jane Smith at jane@example.com '
            'receipt #ZX900 card VISA 1234',
        metadata: {'customerAddress': '123 Main Street'},
      ),
    );

    final summary = report.toSummary();

    expect(summary, contains('QA_ADMIN_HEALTH'));
    expect(summary, contains('QA_TRIAGE_GROUP'));
    expect(summary, contains('QA_SLOW_SUITE'));
    expect(summary, contains('QA_PACK_HEALTH'));
    expect(summary, contains('[REDACTED_EMAIL]'));
    expect(summary, contains('[REDACTED_RECEIPT_ID]'));
    expect(summary, contains('[REDACTED_CARD_LAST4]'));
    expect(summary, contains('[REDACTED_PERSON_NAME]'));
    expect(summary, isNot(contains('Jane Smith')));
    expect(summary, isNot(contains('jane@example.com')));
    expect(summary, isNot(contains('ZX900')));
    expect(summary, isNot(contains('VISA 1234')));
    expect(summary, isNot(contains('123 Main Street')));
  });
}

QaReport _reportWith([QaFailure? failure]) {
  return QaReport(
    domain: 'admin_probe',
    strict: false,
    results: [
      QaSuiteResult(
        name: 'inventory.pack_health_score',
        duration: const Duration(milliseconds: 2),
        checked: 4,
        metrics: const {
          'presentContracts': ['parser_platform', 'privacy'],
          'missingRequiredContracts': <String>[],
          'missingRecommendedContracts': <String>[],
        },
      ),
      QaSuiteResult(
        name: failure?.suite ?? 'inventory.security_privacy',
        duration: const Duration(milliseconds: 9),
        checked: 1,
        failures: [?failure],
      ),
    ],
    startedAt: DateTime(2026, 1, 2, 3, 4, 5),
    duration: const Duration(milliseconds: 11),
    runConfig: const QaRunConfig(profile: 'smoke', preset: 'quick'),
  );
}
