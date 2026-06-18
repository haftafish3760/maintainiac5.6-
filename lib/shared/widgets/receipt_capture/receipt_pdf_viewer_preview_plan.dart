part of 'receipt_pdf_viewer_screen.dart';

enum ReceiptPdfPerformanceProfile {
  lowPower,
  standard,
  highCapacity;

  bool get isLowPower => this == ReceiptPdfPerformanceProfile.lowPower;
}

@visibleForTesting
class ReceiptPdfPreviewPlan {
  const ReceiptPdfPreviewPlan({
    required this.pageLimit,
    required this.dpi,
    required this.reason,
    required this.isReduced,
  });

  const ReceiptPdfPreviewPlan.normal({
    ReceiptPdfPerformanceProfile performanceProfile =
        ReceiptPdfPerformanceProfile.standard,
  }) : pageLimit = performanceProfile == ReceiptPdfPerformanceProfile.lowPower
           ? ReceiptPdfViewerScreen.lowPowerPreviewPageLimit
           : ReceiptPdfViewerScreen.previewPageLimit,
       dpi = performanceProfile == ReceiptPdfPerformanceProfile.lowPower
           ? 112
           : 150,
       reason = performanceProfile == ReceiptPdfPerformanceProfile.lowPower
           ? 'Pinch to zoom. Preview is lighter to protect older or low-storage phones.'
           : 'Pinch to zoom. Preview rendering is capped for phone stability.',
       isReduced = false;

  final int pageLimit;
  final double dpi;
  final String reason;
  final bool isReduced;

  static ReceiptPdfPreviewPlan fromInspection(
    ReceiptPdfInspection inspection, {
    ReceiptPdfPerformanceProfile performanceProfile =
        ReceiptPdfPerformanceProfile.standard,
  }) {
    final lowPower = performanceProfile.isLowPower;
    if (inspection.exceedsHardReceiptPageLimit ||
        inspection.exceedsLocalReadSizeLimit) {
      return ReceiptPdfPreviewPlan(
        pageLimit: lowPower
            ? ReceiptPdfViewerScreen.lowPowerHugePreviewPageLimit
            : ReceiptPdfViewerScreen.hugePreviewPageLimit,
        dpi: lowPower ? 96 : 120,
        reason: lowPower
            ? 'This is a large PDF, so Maintainiac is showing the lightest safe preview for this phone.'
            : 'This is a large PDF, so Maintainiac is showing a lighter preview to protect phone performance.',
        isReduced: true,
      );
    }
    if (inspection.exceedsAssistedReadPageLimit ||
        inspection.isVeryLongReceipt) {
      return ReceiptPdfPreviewPlan(
        pageLimit: lowPower
            ? ReceiptPdfViewerScreen.lowPowerLongPreviewPageLimit
            : ReceiptPdfViewerScreen.longPreviewPageLimit,
        dpi: lowPower ? 104 : 132,
        reason: lowPower
            ? 'This PDF is longer than a normal receipt, so Maintainiac is keeping the preview light for this phone.'
            : 'This PDF is longer than a normal receipt, so Maintainiac is previewing fewer pages first.',
        isReduced: true,
      );
    }
    return ReceiptPdfPreviewPlan.normal(performanceProfile: performanceProfile);
  }
}

@visibleForTesting
ReceiptPdfPreviewPlan receiptPdfPreviewPlanForPageCount(
  int? totalPages, {
  ReceiptPdfPerformanceProfile performanceProfile =
      ReceiptPdfPerformanceProfile.standard,
}) {
  final pages = totalPages;
  final lowPower = performanceProfile.isLowPower;
  if (pages == null || pages <= ReceiptPdfViewerScreen.previewPageLimit) {
    final lowPowerPageLimit = pages == null
        ? ReceiptPdfViewerScreen.lowPowerPreviewPageLimit
        : pages < ReceiptPdfViewerScreen.lowPowerPreviewPageLimit
        ? pages
        : ReceiptPdfViewerScreen.lowPowerPreviewPageLimit;
    return ReceiptPdfPreviewPlan(
      pageLimit: lowPower
          ? lowPowerPageLimit
          : pages ?? ReceiptPdfViewerScreen.previewPageLimit,
      dpi: lowPower ? 112 : 150,
      reason: lowPower
          ? 'Pinch to zoom. Preview is lighter to protect older or low-storage phones.'
          : 'Pinch to zoom. Preview rendering is capped for phone stability.',
      isReduced: false,
    );
  }
  if (pages > ReceiptPdfLimits.hardPdfPageLimit) {
    return ReceiptPdfPreviewPlan(
      pageLimit: lowPower
          ? ReceiptPdfViewerScreen.lowPowerHugePreviewPageLimit
          : ReceiptPdfViewerScreen.hugePreviewPageLimit,
      dpi: lowPower ? 96 : 120,
      reason: lowPower
          ? 'This is a large PDF, so Maintainiac is showing the lightest safe preview for this phone.'
          : 'This is a large PDF, so Maintainiac is showing a lighter preview to protect phone performance.',
      isReduced: true,
    );
  }
  if (pages > ReceiptPdfInspector.localAssistedReadPageLimit) {
    return ReceiptPdfPreviewPlan(
      pageLimit: lowPower
          ? ReceiptPdfViewerScreen.lowPowerLongPreviewPageLimit
          : ReceiptPdfViewerScreen.longPreviewPageLimit,
      dpi: lowPower ? 104 : 132,
      reason: lowPower
          ? 'This PDF is longer than a normal receipt, so Maintainiac is keeping the preview light for this phone.'
          : 'This PDF is longer than a normal receipt, so Maintainiac is previewing fewer pages first.',
      isReduced: true,
    );
  }
  return ReceiptPdfPreviewPlan.normal(performanceProfile: performanceProfile);
}

@visibleForTesting
ReceiptPdfPreviewStatus receiptPdfPreviewStatusForInspection(
  ReceiptPdfInspection inspection,
) {
  if (inspection.importBlocker != null) {
    return ReceiptPdfPreviewStatus.unreadable;
  }
  if (inspection.assistedReadBlocker != null) {
    return ReceiptPdfPreviewStatus.proofOnlyPreviewSkipped;
  }
  return ReceiptPdfPreviewStatus.ready;
}
