import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_models.dart';
import 'package:maintaniac/shared/pdf/app_pdf_health_diagnostics.dart';

void main() {
  test('PDF health diagnostics summarize generated PDF events safely', () {
    final document = AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.invoice,
      title: 'Invoice for Jane Customer at 123 Main Street',
      fileName: 'invoice_INV-PRIVATE-001.pdf',
      bytes: Uint8List.fromList('%PDF-1.7\nsafe\n%%EOF'.codeUnits),
      createdAt: DateTime.utc(2026, 7, 5, 15),
      sourceModule: 'Invoices / Customer Jobs',
      sourceRecordId: 'customer_123_main_private_record',
      shareSubject: 'Private invoice subject',
      shareText: 'Private share text',
    );

    final event = AppPdfHealthEvent.generatedDocument(
      document: document,
      operation: AppPdfHealthOperation.generate,
    );
    final snapshot = AppPdfHealthSnapshot(
      generatedAtUtc: DateTime.utc(2026, 7, 5, 16),
      events: [event],
    );
    final map = snapshot.toCommandCenterMap();
    final serialized = map.toString().toLowerCase();

    expect(map['schema'], 'pdf_health_diagnostics_v1');
    expect(map['healthLabel'], 'healthy');
    expect(map['totalEventCount'], 1);
    expect(map['successCount'], 1);
    expect(map['operationCounts'], {'generate': 1});
    expect(map['kindCounts'], {'invoice': 1});
    expect(map['sourceModuleCounts'], {'invoices_customer_jobs': 1});
    expect(serialized, isNot(contains('jane')));
    expect(serialized, isNot(contains('123 main')));
    expect(serialized, isNot(contains('private invoice subject')));
    expect(serialized, isNot(contains('customer_123_main_private_record')));
  });

  test('PDF health diagnostics expose safe failure buckets only', () {
    final snapshot = AppPdfHealthSnapshot(
      generatedAtUtc: DateTime.utc(2026, 7, 5, 16),
      events: [
        AppPdfHealthEvent(
          operation: AppPdfHealthOperation.importProof,
          status: AppPdfHealthStatus.warning,
          occurredAtUtc: DateTime.utc(2026, 7, 5, 15, 1),
          kind: AppGeneratedPdfKind.receipt,
          sourceModule: 'Receipt PDF / Vendor Invoice',
          byteSize: 12 * 1024 * 1024,
          pageCount: 32,
          riskFlags: const ['embedded JavaScript', 'Passenger: Jane Customer'],
          recoveryAction: 'Review PDF proof only',
        ),
        AppPdfHealthEvent(
          operation: AppPdfHealthOperation.exportPackage,
          status: AppPdfHealthStatus.blocked,
          occurredAtUtc: DateTime.utc(2026, 7, 5, 15, 2),
          kind: AppGeneratedPdfKind.invoice,
          sourceModule: 'VIN 1HGCM82633A004352',
          byteSize: 0,
          issueCodes: const [
            AppGeneratedPdfValidationReportIssue.privateSourcePath,
          ],
          recoveryAction:
              'Do not show /Users/rbbie/Documents/private-customer.pdf',
        ),
      ],
    );

    final map = snapshot.toCommandCenterMap();
    final serialized = map.toString().toLowerCase();

    expect(map['healthLabel'], 'needs_attention');
    expect(map['warningCount'], 1);
    expect(map['blockedCount'], 1);
    expect(map['attentionCount'], 2);
    expect(map['operationCounts'], {'importproof': 1, 'exportpackage': 1});
    expect(serialized, contains('embedded_javascript'));
    expect(serialized, contains('over_twenty_pages'));
    expect(serialized, contains('under_generated_pdf_limit'));
    expect(serialized, contains('empty'));
    expect(serialized, isNot(contains('jane')));
    expect(serialized, isNot(contains('1hgcm')));
    expect(serialized, isNot(contains('/users/')));
    expect(serialized, isNot(contains('private-customer')));
  });

  test('PDF health diagnostics redacts arbitrary operational text', () {
    final snapshot = AppPdfHealthSnapshot(
      generatedAtUtc: DateTime.utc(2026, 7, 5, 16),
      events: [
        AppPdfHealthEvent(
          operation: AppPdfHealthOperation.importProof,
          status: AppPdfHealthStatus.failed,
          occurredAtUtc: DateTime.utc(2026, 7, 5, 15, 3),
          sourceModule: 'Jane Customer HVAC packet',
          byteSize: 2400,
          pageCount: 1,
          issueCodes: const ['Customer Jane private issue'],
          riskFlags: const [
            'Jane Customer opened this file',
            'Call 555-123-4567',
            'Deliver to 123 Main Street',
          ],
          recoveryAction:
              'Ask Jane Customer to resend file from content://downloads/private.pdf',
        ),
        AppPdfHealthEvent(
          operation: AppPdfHealthOperation.exportPackage,
          status: AppPdfHealthStatus.blocked,
          occurredAtUtc: DateTime.utc(2026, 7, 5, 15, 4),
          sourceModule: 'Vendor PDF Export',
          byteSize: 700,
          pageCount: 2,
          riskFlags: const ['missing trailer marker'],
          recoveryAction: 'Review PDF proof only',
        ),
      ],
    );

    final map = snapshot.toCommandCenterMap();
    final serialized = map.toString().toLowerCase();

    expect(serialized, contains('custom_source'));
    expect(serialized, contains('custom_issue'));
    expect(serialized, contains('custom_risk'));
    expect(serialized, contains('vendor_pdf_export'));
    expect(serialized, contains('private_signal'));
    expect(serialized, contains('review_pdf_proof_only'));
    expect(serialized, isNot(contains('jane')));
    expect(serialized, isNot(contains('555')));
    expect(serialized, isNot(contains('123 main')));
    expect(serialized, isNot(contains('content://')));
    expect(serialized, isNot(contains('downloads')));
  });
}

class AppGeneratedPdfValidationReportIssue {
  const AppGeneratedPdfValidationReportIssue._();

  static const privateSourcePath = 'private_source_path';
}
