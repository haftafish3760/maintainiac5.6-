import 'app_generated_pdf_export_estimator.dart';

enum AppGeneratedPdfExportType {
  dailyReport,
  dateRangeReport,
  monthlyReport,
  yearToDateReport,
  estimate,
  invoice,
  expenseExport,
  inventoryReport,
  maintenanceReport,
  customerStatement,
}

class AppGeneratedPdfExportRequest {
  const AppGeneratedPdfExportRequest({
    required this.type,
    this.mode = AppGeneratedPdfExportMode.textOnly,
    this.startDate,
    this.endDate,
    this.receiptCount = 0,
    this.fullImageBytes = 0,
    this.thumbnailBytes = 0,
    this.cloudFullImageBytes = 0,
    this.cloudThumbnailBytes = 0,
    this.pdfOverheadBytes =
        AppGeneratedPdfExportEstimator.defaultPdfOverheadBytes,
    this.textBytesPerReceipt =
        AppGeneratedPdfExportEstimator.defaultTextBytesPerReceipt,
    this.fullImageSelectionConfirmed = false,
  });

  final AppGeneratedPdfExportType type;
  final AppGeneratedPdfExportMode mode;
  final DateTime? startDate;
  final DateTime? endDate;
  final int receiptCount;
  final int fullImageBytes;
  final int thumbnailBytes;
  final int cloudFullImageBytes;
  final int cloudThumbnailBytes;
  final int pdfOverheadBytes;
  final int textBytesPerReceipt;
  final bool fullImageSelectionConfirmed;

  bool get isCustomerDocument =>
      type == AppGeneratedPdfExportType.estimate ||
      type == AppGeneratedPdfExportType.invoice ||
      type == AppGeneratedPdfExportType.customerStatement;

  bool get isReport => !isCustomerDocument;

  bool get requiresDateRange => switch (type) {
    AppGeneratedPdfExportType.dailyReport ||
    AppGeneratedPdfExportType.dateRangeReport ||
    AppGeneratedPdfExportType.monthlyReport ||
    AppGeneratedPdfExportType.yearToDateReport ||
    AppGeneratedPdfExportType.expenseExport ||
    AppGeneratedPdfExportType.inventoryReport ||
    AppGeneratedPdfExportType.maintenanceReport => true,
    AppGeneratedPdfExportType.estimate ||
    AppGeneratedPdfExportType.invoice ||
    AppGeneratedPdfExportType.customerStatement => false,
  };

  List<String> get validationIssues {
    final issues = <String>[];
    if (requiresDateRange && (startDate == null || endDate == null)) {
      issues.add('date_range_required');
    }
    if (startDate != null && endDate != null && endDate!.isBefore(startDate!)) {
      issues.add('date_range_reversed');
    }
    if (mode == AppGeneratedPdfExportMode.fullImages &&
        !fullImageSelectionConfirmed) {
      issues.add('full_image_selection_required');
    }
    return List.unmodifiable(issues);
  }

  bool get isValid => validationIssues.isEmpty;

  AppGeneratedPdfExportEstimate estimate() {
    return AppGeneratedPdfExportEstimator.estimate(
      mode: mode,
      receiptCount: receiptCount,
      fullImageBytes: fullImageBytes,
      thumbnailBytes: thumbnailBytes,
      cloudFullImageBytes: cloudFullImageBytes,
      cloudThumbnailBytes: cloudThumbnailBytes,
      pdfOverheadBytes: pdfOverheadBytes,
      textBytesPerReceipt: textBytesPerReceipt,
    );
  }
}
