import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_export_estimator.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_export_request.dart';

void main() {
  test('defaults a report request to text-only without cloud downloads', () {
    final request = AppGeneratedPdfExportRequest(
      type: AppGeneratedPdfExportType.dateRangeReport,
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 14),
      receiptCount: 3,
      fullImageBytes: 8 * 1024 * 1024,
      cloudFullImageBytes: 6 * 1024 * 1024,
    );

    expect(request.mode, AppGeneratedPdfExportMode.textOnly);
    expect(request.isReport, isTrue);
    expect(request.isValid, isTrue);
    expect(request.estimate().estimatedCloudDownloadBytes, 0);
  });

  test('requires a valid range for report exports', () {
    final missing = AppGeneratedPdfExportRequest(
      type: AppGeneratedPdfExportType.monthlyReport,
    );
    final reversed = AppGeneratedPdfExportRequest(
      type: AppGeneratedPdfExportType.yearToDateReport,
      startDate: DateTime(2026, 7, 14),
      endDate: DateTime(2026, 7, 1),
    );

    expect(missing.validationIssues, contains('date_range_required'));
    expect(reversed.validationIssues, contains('date_range_reversed'));
  });

  test('requires explicit selection before a full-image export', () {
    final unconfirmed = AppGeneratedPdfExportRequest(
      type: AppGeneratedPdfExportType.expenseExport,
      mode: AppGeneratedPdfExportMode.fullImages,
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 14),
    );
    final confirmed = AppGeneratedPdfExportRequest(
      type: AppGeneratedPdfExportType.expenseExport,
      mode: AppGeneratedPdfExportMode.fullImages,
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 14),
      fullImageSelectionConfirmed: true,
    );

    expect(
      unconfirmed.validationIssues,
      contains('full_image_selection_required'),
    );
    expect(confirmed.isValid, isTrue);
  });

  test('keeps invoices as customer documents without a report range', () {
    const request = AppGeneratedPdfExportRequest(
      type: AppGeneratedPdfExportType.invoice,
    );

    expect(request.isCustomerDocument, isTrue);
    expect(request.requiresDateRange, isFalse);
    expect(request.isValid, isTrue);
  });
}
