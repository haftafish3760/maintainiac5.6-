part of 'receipt_ocr_service.dart';

extension _ReceiptOcrServicePdfRead on ReceiptOcrService {
  Future<_ReceiptPdfReadPreflight> _pdfPreflight(
    List<ReceiptAttachmentRecord> attachments,
  ) async {
    final messages = <String>[];
    final blockedIds = <String>{};
    var pagesPlannedForRead = 0;
    for (final attachment in attachments) {
      final inspection = await ReceiptPdfInspector.inspect(attachment.path);
      final blocker = inspection.assistedReadBlocker;
      if (blocker != null) {
        _addUniqueMessage(messages, blocker);
        blockedIds.add(attachment.id);
        continue;
      }
      pagesPlannedForRead += _plannedPdfPagesForRead(inspection);
      final deviceLimitWarning = _devicePdfReadLimitWarning(inspection);
      if (deviceLimitWarning != null) {
        _addUniqueMessage(messages, deviceLimitWarning);
      }
      final warning =
          inspection.userWarning ??
          inspection.documentFitWarning ??
          inspection.longReceiptWarning;
      if (warning != null) {
        _addUniqueMessage(messages, warning);
      }
    }
    return _ReceiptPdfReadPreflight(
      messages: List.unmodifiable(messages),
      blockedAttachmentIds: Set.unmodifiable(blockedIds),
      pagesPlannedForRead: pagesPlannedForRead,
    );
  }

  int _plannedPdfPagesForRead(ReceiptPdfInspection inspection) {
    if (maxPdfOcrPages <= 0) return 0;
    final pages = inspection.pageCount;
    if (pages == null || pages <= 0) return maxPdfOcrPages;
    return pages.clamp(0, maxPdfOcrPages);
  }

  String? _devicePdfReadLimitWarning(ReceiptPdfInspection inspection) {
    if (maxPdfOcrPages <= 0) return null;
    final pages = inspection.pageCount;
    if (pages == null || pages <= maxPdfOcrPages) return null;
    return 'Only the first $maxPdfOcrPages pages of this PDF will be read on this device. The full PDF stays saved as read-only proof.';
  }

  Future<String> _recognizeTextFromPdfPages(
    ReceiptAttachmentRecord attachment,
    TextRecognizer recognizer,
  ) async {
    if (maxPdfOcrPages <= 0) return '';
    final bytes = await _readPdfRasterBytes(attachment.path);
    if (bytes == null || bytes.isEmpty) {
      throw const _ReceiptPdfRasterReadException();
    }
    final tempDir = await Directory.systemTemp.createTemp(
      'maintaniac_pdf_read_',
    );
    final pageTexts = <String>[];
    var pageIndex = 0;
    try {
      await for (final page in Printing.raster(
        bytes,
        dpi: 160,
      ).timeout(pdfPageReadTimeout)) {
        if (pageIndex >= maxPdfOcrPages) break;
        final png = await page.toPng();
        final imageFile = File('${tempDir.path}/page_$pageIndex.png');
        await imageFile.writeAsBytes(png, flush: true);
        final image = InputImage.fromFilePath(imageFile.path);
        final recognized = await recognizer.processImage(image);
        final sourceText = recognized.text;
        if (sourceText.trim().isNotEmpty) pageTexts.add(sourceText);
        pageIndex += 1;
      }
    } on MissingPluginException {
      rethrow;
    } on PlatformException {
      rethrow;
    } catch (error) {
      if (error.toString().contains('MissingPluginException')) rethrow;
      return '';
    } finally {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    }
    return pageTexts.join('\n\n');
  }

  Future<Uint8List?> _readPdfRasterBytes(String path) async {
    try {
      return await File(path).readAsBytes();
    } on FileSystemException {
      return null;
    }
  }
}

class _ReceiptPdfRasterReadException implements Exception {
  const _ReceiptPdfRasterReadException();
}
