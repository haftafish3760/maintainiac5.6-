class ReceiptPdfLimits {
  const ReceiptPdfLimits._();

  static const maxPdfBytes = 50 * 1024 * 1024;
  static const softPdfPageWarning = 10;
  static const hardPdfPageLimit = 75;
  static const maxPdfPagesForReceiptOcrLater = 50;
  static const localAssistedReadBytes = 20 * 1024 * 1024;
  static const cloudAssistedReadPageLimit = 10;
  static const cloudAssistedReadBytes = 8 * 1024 * 1024;
}
