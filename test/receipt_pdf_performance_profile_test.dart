import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_inspector.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_limits.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_viewer_screen.dart';

void main() {
  group('Receipt PDF performance profiles', () {
    test('standard profile preserves current preview caps', () {
      expect(receiptPdfPreviewPageLimit(null), 10);
      expect(receiptPdfPreviewPageLimit(3), 3);
      expect(
        receiptPdfPreviewPageLimit(
          ReceiptPdfLimits.maxPdfPagesForReceiptOcrLater + 1,
        ),
        5,
      );
      expect(
        receiptPdfPreviewPageLimit(ReceiptPdfLimits.hardPdfPageLimit + 1),
        3,
      );
    });

    test('low-power profile reduces normal receipt preview work', () {
      final short = receiptPdfPreviewPlanForPageCount(
        3,
        performanceProfile: ReceiptPdfPerformanceProfile.lowPower,
      );
      final unknown = receiptPdfPreviewPlanForPageCount(
        null,
        performanceProfile: ReceiptPdfPerformanceProfile.lowPower,
      );
      final normalLimit = receiptPdfPreviewPlanForPageCount(
        10,
        performanceProfile: ReceiptPdfPerformanceProfile.lowPower,
      );

      expect(short.pageLimit, 3);
      expect(short.dpi, 112);
      expect(short.isReduced, isFalse);
      expect(unknown.pageLimit, 4);
      expect(normalLimit.pageLimit, 4);
      expect(normalLimit.reason, contains('older or low-storage phones'));
    });

    test('low-power profile heavily caps long and huge PDFs', () {
      final long = receiptPdfPreviewPlanForPageCount(
        ReceiptPdfInspector.localAssistedReadPageLimit + 1,
        performanceProfile: ReceiptPdfPerformanceProfile.lowPower,
      );
      final huge = receiptPdfPreviewPlanForPageCount(
        ReceiptPdfLimits.hardPdfPageLimit + 1,
        performanceProfile: ReceiptPdfPerformanceProfile.lowPower,
      );

      expect(long.pageLimit, 2);
      expect(long.dpi, 104);
      expect(long.isReduced, isTrue);
      expect(huge.pageLimit, 1);
      expect(huge.dpi, 96);
      expect(huge.isReduced, isTrue);
    });

    test('high-capacity profile can preview a larger local sample', () {
      final normal = receiptPdfPreviewPlanForPageCount(
        null,
        performanceProfile: ReceiptPdfPerformanceProfile.highCapacity,
      );
      final long = receiptPdfPreviewPlanForPageCount(
        ReceiptPdfInspector.localAssistedReadPageLimit + 1,
        performanceProfile: ReceiptPdfPerformanceProfile.highCapacity,
      );
      final huge = receiptPdfPreviewPlanForPageCount(
        ReceiptPdfLimits.hardPdfPageLimit + 1,
        performanceProfile: ReceiptPdfPerformanceProfile.highCapacity,
      );

      expect(normal.pageLimit, 12);
      expect(normal.dpi, 170);
      expect(long.pageLimit, 8);
      expect(long.dpi, 150);
      expect(huge.pageLimit, 5);
      expect(huge.dpi, 132);
    });

    test('PDF profile maps directly from receipt capability tier', () {
      expect(
        ReceiptPdfPerformanceProfile.fromCapability(
          const ReceiptDeviceCapability.olderPhone(),
        ),
        ReceiptPdfPerformanceProfile.lowPower,
      );
      expect(
        ReceiptPdfPerformanceProfile.fromCapability(
          const ReceiptDeviceCapability.standard(),
        ),
        ReceiptPdfPerformanceProfile.standard,
      );
      expect(
        ReceiptPdfPerformanceProfile.fromCapability(
          const ReceiptDeviceCapability.highCapacity(),
        ),
        ReceiptPdfPerformanceProfile.highCapacity,
      );
    });

    test('inspection-based plan follows low-power profile', () {
      const inspection = ReceiptPdfInspection(
        path: '/tmp/long.pdf',
        exists: true,
        byteSize: 4096,
        pageCount: ReceiptPdfInspector.localAssistedReadPageLimit + 1,
        hasPdfHeader: true,
        pageCountStatus: ReceiptPdfPageCountStatus.estimated,
        validationStatus: ReceiptPdfValidationStatus.valid,
      );

      final standard = ReceiptPdfPreviewPlan.fromInspection(inspection);
      final lowPower = ReceiptPdfPreviewPlan.fromInspection(
        inspection,
        performanceProfile: ReceiptPdfPerformanceProfile.lowPower,
      );

      expect(standard.pageLimit, 5);
      expect(standard.dpi, 132);
      expect(lowPower.pageLimit, 2);
      expect(lowPower.dpi, 104);
      expect(lowPower.reason, contains('keeping the preview light'));
    });
  });
}
