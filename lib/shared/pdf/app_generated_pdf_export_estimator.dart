enum AppGeneratedPdfExportMode { textOnly, thumbnails, fullImages }

enum AppGeneratedPdfExportWarningLevel { low, medium, high }

class AppGeneratedPdfExportEstimate {
  const AppGeneratedPdfExportEstimate({
    required this.mode,
    required this.receiptCount,
    required this.estimatedPdfBytes,
    required this.estimatedCloudDownloadBytes,
    required this.warningLevel,
  });

  final AppGeneratedPdfExportMode mode;
  final int receiptCount;
  final int estimatedPdfBytes;
  final int estimatedCloudDownloadBytes;
  final AppGeneratedPdfExportWarningLevel warningLevel;

  bool get isHighRisk => warningLevel == AppGeneratedPdfExportWarningLevel.high;
}

class AppGeneratedPdfExportEstimator {
  const AppGeneratedPdfExportEstimator._();

  static const defaultPdfOverheadBytes = 64 * 1024;
  static const defaultTextBytesPerReceipt = 2 * 1024;
  static const mediumWarningBytes = 5 * 1024 * 1024;
  static const highWarningBytes = 20 * 1024 * 1024;

  static AppGeneratedPdfExportEstimate estimate({
    required AppGeneratedPdfExportMode mode,
    required int receiptCount,
    int fullImageBytes = 0,
    int thumbnailBytes = 0,
    int cloudFullImageBytes = 0,
    int cloudThumbnailBytes = 0,
    int pdfOverheadBytes = defaultPdfOverheadBytes,
    int textBytesPerReceipt = defaultTextBytesPerReceipt,
  }) {
    final safeReceiptCount = _nonNegative(receiptCount);
    final textBytes = safeReceiptCount * _nonNegative(textBytesPerReceipt);
    final safeOverhead = _nonNegative(pdfOverheadBytes);
    final safeFullImageBytes = _nonNegative(fullImageBytes);
    final safeThumbnailBytes = _nonNegative(thumbnailBytes);
    final safeCloudFullImageBytes = _nonNegative(cloudFullImageBytes);
    final safeCloudThumbnailBytes = _nonNegative(cloudThumbnailBytes);

    final estimatedPdfBytes = switch (mode) {
      AppGeneratedPdfExportMode.textOnly => safeOverhead + textBytes,
      AppGeneratedPdfExportMode.thumbnails =>
        safeOverhead + textBytes + safeThumbnailBytes,
      AppGeneratedPdfExportMode.fullImages =>
        safeOverhead + textBytes + safeFullImageBytes,
    };
    final estimatedCloudDownloadBytes = switch (mode) {
      AppGeneratedPdfExportMode.textOnly => 0,
      AppGeneratedPdfExportMode.thumbnails => safeCloudThumbnailBytes,
      AppGeneratedPdfExportMode.fullImages => safeCloudFullImageBytes,
    };

    return AppGeneratedPdfExportEstimate(
      mode: mode,
      receiptCount: safeReceiptCount,
      estimatedPdfBytes: estimatedPdfBytes,
      estimatedCloudDownloadBytes: estimatedCloudDownloadBytes,
      warningLevel: _warningFor(estimatedPdfBytes),
    );
  }

  static int _nonNegative(int value) => value < 0 ? 0 : value;

  static AppGeneratedPdfExportWarningLevel _warningFor(int bytes) {
    if (bytes >= highWarningBytes) {
      return AppGeneratedPdfExportWarningLevel.high;
    }
    if (bytes >= mediumWarningBytes) {
      return AppGeneratedPdfExportWarningLevel.medium;
    }
    return AppGeneratedPdfExportWarningLevel.low;
  }
}
