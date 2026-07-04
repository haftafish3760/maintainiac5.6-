import '../../../shared/widgets/receipt_capture/receipt_barcode_scanner_service.dart';
import 'work_supply_item_identity_store.dart';

class WorkSupplyBarcodeScanSuggestion {
  const WorkSupplyBarcodeScanSuggestion({
    required this.barcodeValue,
    required this.barcodeFormat,
    required this.sourceFormat,
    required this.sourceValueType,
  });

  final String barcodeValue;
  final String barcodeFormat;
  final ReceiptBarcodeFormat sourceFormat;
  final String sourceValueType;

  String get barcodeNormalized => normalizeWorkSupplyBarcode(barcodeValue);

  Map<String, Object?> get privacySafeSummaryMap {
    return {
      'barcodeFormat': barcodeFormat,
      'sourceFormat': sourceFormat.name,
      'sourceValueType': sourceValueType,
      'normalizedLength': barcodeNormalized.length,
    };
  }
}

class WorkSupplyBarcodeScanBridge {
  const WorkSupplyBarcodeScanBridge();

  List<WorkSupplyBarcodeScanSuggestion> suggestionsFromScanResult(
    ReceiptBarcodeScanResult result,
  ) {
    final seen = <String>{};
    final suggestions = <WorkSupplyBarcodeScanSuggestion>[];
    for (final code in result.codes) {
      final lookupValue = code.inventoryLookupValue;
      if (lookupValue == null) continue;
      final normalized = normalizeWorkSupplyBarcode(lookupValue);
      if (normalized.isEmpty || !seen.add(normalized)) continue;
      suggestions.add(
        WorkSupplyBarcodeScanSuggestion(
          barcodeValue: lookupValue,
          barcodeFormat: workSupplyBarcodeFormatForScannedCode(code),
          sourceFormat: code.format,
          sourceValueType: code.privacySafeValueType,
        ),
      );
    }
    return List.unmodifiable(suggestions);
  }
}

String workSupplyBarcodeFormatForScannedCode(ReceiptScannedCode code) {
  return switch (code.format) {
    ReceiptBarcodeFormat.upca => 'upcA',
    ReceiptBarcodeFormat.upce => 'upcE',
    ReceiptBarcodeFormat.ean8 => 'ean8',
    ReceiptBarcodeFormat.ean13 => 'ean13',
    ReceiptBarcodeFormat.qrCode => 'qr',
    ReceiptBarcodeFormat.code128 => 'code128',
    ReceiptBarcodeFormat.code39 => 'code39',
    ReceiptBarcodeFormat.code93 => 'code93',
    ReceiptBarcodeFormat.codabar => 'codabar',
    ReceiptBarcodeFormat.dataMatrix => 'dataMatrix',
    ReceiptBarcodeFormat.itf => 'itf',
    ReceiptBarcodeFormat.pdf417 => 'pdf417',
    ReceiptBarcodeFormat.aztec => 'aztec',
    ReceiptBarcodeFormat.all || ReceiptBarcodeFormat.unknown =>
      _guessWorkSupplyBarcodeFormat(code.normalizedValue),
  };
}

String _guessWorkSupplyBarcodeFormat(String value) {
  final normalized = normalizeWorkSupplyBarcode(value);
  if (RegExp(r'^\d{12}$').hasMatch(normalized)) return 'upcA';
  if (RegExp(r'^\d{8}$').hasMatch(normalized)) return 'ean8';
  if (RegExp(r'^\d{13}$').hasMatch(normalized)) return 'ean13';
  if (normalized.length > 14) return 'qrOrCode128';
  return 'unknown';
}
