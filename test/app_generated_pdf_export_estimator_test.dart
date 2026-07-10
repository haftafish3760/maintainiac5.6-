import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_export_estimator.dart';

void main() {
  test('text-only estimates use metadata without image bytes or downloads', () {
    final estimate = AppGeneratedPdfExportEstimator.estimate(
      mode: AppGeneratedPdfExportMode.textOnly,
      receiptCount: 3,
      fullImageBytes: 50 * 1024 * 1024,
      thumbnailBytes: 10 * 1024 * 1024,
      cloudFullImageBytes: 50 * 1024 * 1024,
      cloudThumbnailBytes: 10 * 1024 * 1024,
    );

    expect(estimate.estimatedPdfBytes, 64 * 1024 + (3 * 2 * 1024));
    expect(estimate.estimatedCloudDownloadBytes, 0);
    expect(estimate.warningLevel, AppGeneratedPdfExportWarningLevel.low);
  });

  test('full-image estimates report known PDF and cloud costs', () {
    final estimate = AppGeneratedPdfExportEstimator.estimate(
      mode: AppGeneratedPdfExportMode.fullImages,
      receiptCount: 4,
      fullImageBytes: 24 * 1024 * 1024,
      cloudFullImageBytes: 12 * 1024 * 1024,
    );

    expect(estimate.estimatedPdfBytes, greaterThan(24 * 1024 * 1024));
    expect(estimate.estimatedCloudDownloadBytes, 12 * 1024 * 1024);
    expect(estimate.isHighRisk, isTrue);
  });

  test('negative metadata cannot produce a negative estimate', () {
    final estimate = AppGeneratedPdfExportEstimator.estimate(
      mode: AppGeneratedPdfExportMode.thumbnails,
      receiptCount: -2,
      thumbnailBytes: -10,
      cloudThumbnailBytes: -20,
      pdfOverheadBytes: -30,
      textBytesPerReceipt: -40,
    );

    expect(estimate.receiptCount, 0);
    expect(estimate.estimatedPdfBytes, 0);
    expect(estimate.estimatedCloudDownloadBytes, 0);
  });
}
