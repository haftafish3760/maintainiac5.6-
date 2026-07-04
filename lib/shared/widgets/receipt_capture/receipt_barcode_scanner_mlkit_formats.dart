part of 'receipt_barcode_scanner_service.dart';

List<mlkit.BarcodeFormat> _mlkitFormatsFor(List<ReceiptBarcodeFormat> formats) {
  if (formats.isEmpty) return const [mlkit.BarcodeFormat.all];
  return List.unmodifiable(formats.map(_formatToMlKit));
}

mlkit.BarcodeFormat _formatToMlKit(ReceiptBarcodeFormat format) {
  return switch (format) {
    ReceiptBarcodeFormat.all => mlkit.BarcodeFormat.all,
    ReceiptBarcodeFormat.unknown => mlkit.BarcodeFormat.unknown,
    ReceiptBarcodeFormat.code128 => mlkit.BarcodeFormat.code128,
    ReceiptBarcodeFormat.code39 => mlkit.BarcodeFormat.code39,
    ReceiptBarcodeFormat.code93 => mlkit.BarcodeFormat.code93,
    ReceiptBarcodeFormat.codabar => mlkit.BarcodeFormat.codabar,
    ReceiptBarcodeFormat.dataMatrix => mlkit.BarcodeFormat.dataMatrix,
    ReceiptBarcodeFormat.ean13 => mlkit.BarcodeFormat.ean13,
    ReceiptBarcodeFormat.ean8 => mlkit.BarcodeFormat.ean8,
    ReceiptBarcodeFormat.itf => mlkit.BarcodeFormat.itf,
    ReceiptBarcodeFormat.qrCode => mlkit.BarcodeFormat.qrCode,
    ReceiptBarcodeFormat.upca => mlkit.BarcodeFormat.upca,
    ReceiptBarcodeFormat.upce => mlkit.BarcodeFormat.upce,
    ReceiptBarcodeFormat.pdf417 => mlkit.BarcodeFormat.pdf417,
    ReceiptBarcodeFormat.aztec => mlkit.BarcodeFormat.aztec,
  };
}

ReceiptBarcodeFormat _formatFromMlKit(mlkit.BarcodeFormat format) {
  return switch (format) {
    mlkit.BarcodeFormat.all => ReceiptBarcodeFormat.all,
    mlkit.BarcodeFormat.unknown => ReceiptBarcodeFormat.unknown,
    mlkit.BarcodeFormat.code128 => ReceiptBarcodeFormat.code128,
    mlkit.BarcodeFormat.code39 => ReceiptBarcodeFormat.code39,
    mlkit.BarcodeFormat.code93 => ReceiptBarcodeFormat.code93,
    mlkit.BarcodeFormat.codabar => ReceiptBarcodeFormat.codabar,
    mlkit.BarcodeFormat.dataMatrix => ReceiptBarcodeFormat.dataMatrix,
    mlkit.BarcodeFormat.ean13 => ReceiptBarcodeFormat.ean13,
    mlkit.BarcodeFormat.ean8 => ReceiptBarcodeFormat.ean8,
    mlkit.BarcodeFormat.itf => ReceiptBarcodeFormat.itf,
    mlkit.BarcodeFormat.qrCode => ReceiptBarcodeFormat.qrCode,
    mlkit.BarcodeFormat.upca => ReceiptBarcodeFormat.upca,
    mlkit.BarcodeFormat.upce => ReceiptBarcodeFormat.upce,
    mlkit.BarcodeFormat.pdf417 => ReceiptBarcodeFormat.pdf417,
    mlkit.BarcodeFormat.aztec => ReceiptBarcodeFormat.aztec,
  };
}
