import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_export_estimator.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_image_loader.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_export_request.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_report_renderer.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_receipt_sections.dart';

void main() {
  test('builds a data-first daily report with all record sections', () async {
    final request = AppGeneratedPdfExportRequest(
      type: AppGeneratedPdfExportType.dailyReport,
      startDate: DateTime(2026, 7, 14),
      endDate: DateTime(2026, 7, 14),
    );
    final document = await const AppGeneratedPdfReportRenderer().build(
      request: request,
      data: AppGeneratedPdfReportData(
        generatedAt: DateTime(2026, 7, 14, 12),
        activeProfileName: 'Jordan',
        vehicleNickname: 'Service Van',
        odometerRange: '120,100 - 120,180',
        totalMiles: 80,
        businessMiles: 72,
        totalIncome: 320,
        totalExpenses: 48.25,
        netAmount: 271.75,
        trips: [
          AppGeneratedPdfReportTrip(
            date: DateTime(2026, 7, 14),
            startTime: '8:00 AM',
            endTime: '10:00 AM',
            miles: 12.5,
            pay: 84,
          ),
        ],
        expenses: [
          AppGeneratedPdfReportExpense(
            date: DateTime(2026, 7, 14),
            category: 'Fuel',
            merchant: 'Fuel Stop',
            amount: 48.25,
            receiptAttached: true,
          ),
        ],
        maintenance: [
          AppGeneratedPdfReportMaintenance(
            date: DateTime(2026, 7, 14),
            serviceType: 'Oil change',
            vehicleNickname: 'Service Van',
            cost: 72,
          ),
        ],
      ),
      sourceModule: 'reports',
    );

    expect(document.kindLabel, 'Activity Report');
    expect(document.sourceModule, 'reports');
    expect(document.validation.isValid, isTrue);
  });

  test('rejects a report request with an invalid range', () async {
    final request = AppGeneratedPdfExportRequest(
      type: AppGeneratedPdfExportType.monthlyReport,
      startDate: DateTime(2026, 7, 31),
      endDate: DateTime(2026, 7, 1),
    );

    await expectLater(
      const AppGeneratedPdfReportRenderer().build(
        request: request,
        data: AppGeneratedPdfReportData(generatedAt: DateTime(2026, 7, 14)),
      ),
      throwsA(isA<AppGeneratedPdfReportException>()),
    );
  });

  test('text-only report does not request receipt images', () async {
    var imageRequests = 0;
    final document = await const AppGeneratedPdfReportRenderer().build(
      request: AppGeneratedPdfExportRequest(
        type: AppGeneratedPdfExportType.dailyReport,
        startDate: DateTime(2026, 7, 14),
        endDate: DateTime(2026, 7, 14),
      ),
      data: AppGeneratedPdfReportData(
        generatedAt: DateTime(2026, 7, 14),
        receiptImages: const [
          AppGeneratedPdfReceiptImageReference(
            attachmentId: 'receipt-1',
            label: 'Fuel Stop',
          ),
        ],
      ),
      imageResolver: AppGeneratedPdfImageResolver(
        fetch: ({required attachmentId, required mode}) async {
          imageRequests += 1;
          return Uint8List(0);
        },
      ),
    );

    expect(document.validation.isValid, isTrue);
    expect(imageRequests, 0);
  });

  test('report thumbnail mode requests thumbnails, never full images', () async {
    var requestedMode = AppGeneratedPdfExportMode.fullImages;
    final document = await const AppGeneratedPdfReportRenderer().build(
      request: AppGeneratedPdfExportRequest(
        type: AppGeneratedPdfExportType.dailyReport,
        mode: AppGeneratedPdfExportMode.thumbnails,
        startDate: DateTime(2026, 7, 14),
        endDate: DateTime(2026, 7, 14),
      ),
      data: AppGeneratedPdfReportData(
        generatedAt: DateTime(2026, 7, 14),
        receiptImages: const [
          AppGeneratedPdfReceiptImageReference(
            attachmentId: 'receipt-1',
            label: 'Fuel Stop',
          ),
        ],
      ),
      imageResolver: AppGeneratedPdfImageResolver(
        fetch: ({required attachmentId, required mode}) async {
          requestedMode = mode;
          return Uint8List.fromList(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
            ),
          );
        },
      ),
    );

    expect(document.validation.isValid, isTrue);
    expect(requestedMode, AppGeneratedPdfExportMode.thumbnails);
  });

  test('report full-image mode requires explicit download approval', () async {
    final request = AppGeneratedPdfExportRequest(
      type: AppGeneratedPdfExportType.dailyReport,
      mode: AppGeneratedPdfExportMode.fullImages,
      startDate: DateTime(2026, 7, 14),
      endDate: DateTime(2026, 7, 14),
      fullImageSelectionConfirmed: true,
    );

    await expectLater(
      const AppGeneratedPdfReportRenderer().build(
        request: request,
        data: AppGeneratedPdfReportData(
          generatedAt: DateTime(2026, 7, 14),
          receiptImages: const [
            AppGeneratedPdfReceiptImageReference(
              attachmentId: 'receipt-1',
              label: 'Fuel Stop',
            ),
          ],
        ),
        imageResolver: AppGeneratedPdfImageResolver(
          fetch: ({required attachmentId, required mode}) async => Uint8List(1),
        ),
      ),
      throwsA(isA<AppGeneratedPdfImageResolutionException>()),
    );
  });
}
