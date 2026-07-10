import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_share_content.dart';

void main() {
  test('uses shared invoice metadata for records', () {
    final content = AppGeneratedPdfShareContent.invoiceRecord(
      isEstimate: true,
      documentNumber: 'EST-1042',
    );

    expect(content.subject, 'Maintainiac estimate EST-1042');
    expect(content.text, contains('Review before sending'));
  });

  test('uses shared expense metadata for exports', () {
    final content = AppGeneratedPdfShareContent.expenseExport(
      rangeStart: DateTime(2026, 7, 1),
      rangeEnd: DateTime(2026, 7, 9),
      receiptCount: 4,
      lineCount: 12,
      total: '\$123.45',
    );

    expect(content.subject, 'Maintainiac expense export 7/1/2026 - 7/9/2026');
    expect(content.text, contains('Receipts: 4'));
    expect(content.text, contains('Total: \$123.45'));
  });
}
