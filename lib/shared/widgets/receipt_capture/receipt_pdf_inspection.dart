part of 'receipt_pdf_inspector.dart';

class ReceiptPdfInspection {
  const ReceiptPdfInspection({
    required this.path,
    required this.exists,
    required this.byteSize,
    required this.pageCount,
    required this.hasPdfHeader,
    required this.pageCountStatus,
    required this.validationStatus,
    this.riskFlags = const [],
    this.documentSignals = const [],
  });

  final String path;
  final bool exists;
  final int byteSize;
  final int? pageCount;
  final bool hasPdfHeader;
  final ReceiptPdfPageCountStatus pageCountStatus;
  final ReceiptPdfValidationStatus validationStatus;
  final List<String> riskFlags;
  final List<String> documentSignals;

  bool get isEmpty => byteSize <= 0;
  bool get hasKnownPages => pageCount != null && pageCount! > 0;
  bool get hasNoPages => pageCount != null && pageCount! <= 0;
  bool get isProbablyLongReceipt => (pageCount ?? 0) > 10;
  bool get isVeryLongReceipt => (pageCount ?? 0) > 20;
  bool get exceedsAssistedReadPageLimit =>
      (pageCount ?? 0) > ReceiptPdfLimits.maxPdfPagesForReceiptOcrLater;
  bool get exceedsCloudReadPageLimit =>
      (pageCount ?? 0) > ReceiptPdfLimits.cloudAssistedReadPageLimit;
  bool get exceedsLocalReadSizeLimit =>
      byteSize > ReceiptPdfLimits.localAssistedReadBytes;
  bool get exceedsCloudReadSizeLimit =>
      byteSize > ReceiptPdfLimits.cloudAssistedReadBytes;
  bool get exceedsImportSizeLimit => byteSize > ReceiptPdfLimits.maxPdfBytes;
  bool get exceedsHardReceiptPageLimit =>
      pageCountStatus != ReceiptPdfPageCountStatus.unknown &&
      (pageCount ?? 0) > ReceiptPdfLimits.hardPdfPageLimit;
  bool get hasEncryptionSecurity =>
      riskFlags.contains(ReceiptPdfInspector.encryptionRiskFlag);
  bool get hasActiveContentRisk =>
      riskFlags.any(ReceiptPdfInspector.activeContentRiskFlags.contains);
  bool get hasReceiptSignals => documentSignals.any(
    (signal) => ReceiptPdfInspector.receiptSignals.contains(signal),
  );
  bool get hasNonReceiptSignals => documentSignals.any(
    (signal) => ReceiptPdfInspector.nonReceiptSignals.contains(signal),
  );
  bool get hasImageContent =>
      documentSignals.contains(ReceiptPdfInspector.imageContentSignal);
  bool get hasTextLayer =>
      documentSignals.contains(ReceiptPdfInspector.textLayerSignal);
  bool get appearsImageOnly => hasImageContent && !hasTextLayer;
  bool get hasRotatedOrCroppedPages =>
      documentSignals.contains(ReceiptPdfInspector.rotatedPageSignal) ||
      documentSignals.contains(ReceiptPdfInspector.croppedPageSignal);
  bool get canAttachAsProof => importBlocker == null;
  bool get canUseAssistedRead => assistedReadBlocker == null;

  ReceiptPdfHandlingDisposition get handlingDisposition {
    if (importBlocker != null) return ReceiptPdfHandlingDisposition.blocked;
    if (assistedReadBlocker != null) {
      return ReceiptPdfHandlingDisposition.proofOnly;
    }
    if (userWarning != null) {
      return ReceiptPdfHandlingDisposition.assistedReadWithWarning;
    }
    return ReceiptPdfHandlingDisposition.assistedReadReady;
  }

  String get sizeLabel => ReceiptPdfInspector.formatBytes(byteSize);

  String get pageLabel {
    final count = pageCount;
    if (count == null) return 'page count unavailable';
    return '$count ${count == 1 ? 'page' : 'pages'}';
  }

  String? get importBlocker {
    if (!exists) return 'That PDF receipt could not be found on this device.';
    if (isEmpty) return 'That PDF receipt is empty.';
    if (!hasPdfHeader) {
      return 'That file does not look like a valid PDF. Choose the original PDF receipt file.';
    }
    if (validationStatus == ReceiptPdfValidationStatus.failed) {
      return 'That PDF could not be read from this device. Choose the original file or try saving it again.';
    }
    if (exceedsImportSizeLimit) {
      return 'That PDF is $sizeLabel, which is too large to attach as receipt proof.';
    }
    if (hasNoPages) return 'That PDF does not appear to contain any pages.';
    return null;
  }

  String? get userWarning {
    final warnings = <String>[];
    final validation = validationWarning;
    if (validation != null) warnings.add(validation);
    final documentFit = documentFitWarning;
    if (documentFit != null) warnings.add(documentFit);
    final longReceipt = longReceiptWarning;
    if (longReceipt != null) warnings.add(longReceipt);
    return warnings.isEmpty ? null : warnings.join(' ');
  }

  String? get validationWarning {
    final warnings = <String>[];
    if (pageCountStatus == ReceiptPdfPageCountStatus.estimated &&
        pageCount != null) {
      warnings.add('The PDF page count is estimated at $pageCount pages.');
    }
    if (pageCountStatus == ReceiptPdfPageCountStatus.unknown && hasPdfHeader) {
      warnings.add(
        'The PDF was attached, but its page count could not be confirmed.',
      );
    }
    if (riskFlags.isNotEmpty) {
      warnings.add(
        'This PDF can be saved as proof, but it contains ${riskFlags.join(', ')}. Maintainiac will not run scripts or follow links in receipt PDFs.',
      );
    }
    return warnings.isEmpty ? null : warnings.join(' ');
  }

  String? get documentFitWarning {
    if (!hasPdfHeader || importBlocker != null) return null;
    if (appearsImageOnly) {
      return 'This PDF appears to contain scanned or image-based pages. It can still be saved as proof; app-assisted reading may need a clear page image before it can fill the form.';
    }
    if (hasRotatedOrCroppedPages && !hasReceiptSignals) {
      return 'This PDF has rotated or cropped page geometry. It can still be saved as proof; review the preview before using app-assisted reading.';
    }
    if (hasNonReceiptSignals && !hasReceiptSignals) {
      return 'This PDF looks more like ${documentSignals.join(', ')} than a receipt. It can still be saved as proof; review it before using app-assisted reading.';
    }
    if (!hasReceiptSignals &&
        pageCountStatus != ReceiptPdfPageCountStatus.unknown) {
      return 'No obvious receipt details were found in the PDF file itself. Save it as proof if it is the right document; app-assisted reading may still work on scanned pages.';
    }
    return null;
  }

  String? get assistedReadBlocker {
    final blocker = importBlocker;
    if (blocker != null) return blocker;
    if (exceedsHardReceiptPageLimit) {
      return 'This PDF has $pageCount pages. It was attached as proof, but it is too long for app-assisted receipt assistance.';
    }
    if (hasEncryptionSecurity) {
      return 'This PDF appears to be password protected or encrypted. It can be saved as proof, but app-assisted reading cannot open it safely.';
    }
    if (hasActiveContentRisk) {
      return 'This PDF contains active content. It can be saved as read-only proof, but app-assisted reading will not open it or run scripts.';
    }
    if (exceedsLocalReadSizeLimit) {
      return 'That PDF is $sizeLabel. It was attached as proof, but app-assisted reading needs a smaller file.';
    }
    return null;
  }

  String? get longReceiptWarning {
    final count = pageCount;
    if (count == null) return null;
    if (exceedsHardReceiptPageLimit) {
      return 'This PDF has $count pages. It can be saved as read-only proof, '
          'but it is too long to treat as a normal receipt. Save it without '
          'app-assisted reading unless you are sure the receipt details are '
          'near the front.';
    }
    if (exceedsAssistedReadPageLimit) {
      return 'This PDF has $count pages. It can be saved as proof, but app-assisted reading will only read the first ${ReceiptPdfInspector.localAssistedReadPageLimit} pages.';
    }
    if (count > 20) {
      return 'This PDF has $count pages, which is unusually long for a receipt. Check that it is the receipt and not a manual, warranty, or statement.';
    }
    if (count > ReceiptPdfLimits.softPdfPageWarning) {
      return 'This PDF has $count pages. That may be correct, but it is longer than most receipt files.';
    }
    return null;
  }

  String? get cloudCostWarning {
    final count = pageCount;
    if (count != null && exceedsCloudReadPageLimit) {
      return 'Cloud receipt assistance should use a smaller PDF or selected pages. This file has $count pages.';
    }
    if (exceedsCloudReadSizeLimit) {
      return 'Cloud receipt assistance should use a smaller PDF. This file is $sizeLabel.';
    }
    return null;
  }
}
