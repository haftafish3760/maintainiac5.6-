part of 'receipt_pdf_viewer_screen.dart';

extension _PdfProofPreviewAsync on _PdfProofPagesState {
  Future<_PdfProofPreview> _preview(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return const _PdfProofPreview(status: ReceiptPdfPreviewStatus.missing);
    }
    late final ReceiptPdfInspection inspection;
    try {
      inspection = await ReceiptPdfInspector.inspect(path);
    } catch (_) {
      return const _PdfProofPreview(status: ReceiptPdfPreviewStatus.unreadable);
    }
    final preflightStatus = receiptPdfPreviewStatusForInspection(inspection);
    if (preflightStatus != ReceiptPdfPreviewStatus.ready) {
      return _PdfProofPreview(status: preflightStatus);
    }
    try {
      if (await file.length() > ReceiptPdfLimits.localAssistedReadBytes) {
        return const _PdfProofPreview(
          status: ReceiptPdfPreviewStatus.tooLargeForPreview,
        );
      }
    } catch (_) {
      return const _PdfProofPreview(status: ReceiptPdfPreviewStatus.unreadable);
    }
    late final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      return const _PdfProofPreview(status: ReceiptPdfPreviewStatus.unreadable);
    }
    final totalPages = ReceiptPdfInspector.estimatePageCount(bytes);
    final previewPlan = ReceiptPdfPreviewPlan.fromInspection(
      inspection,
      performanceProfile: widget.performanceProfile,
    );
    final pageImages = <Uint8List>[];
    var pageIndex = 0;
    try {
      await for (final page in Printing.raster(
        bytes,
        dpi: previewPlan.dpi,
      ).timeout(ReceiptPdfViewerScreen.previewTimeout)) {
        if (pageIndex >= previewPlan.pageLimit) break;
        pageImages.add(await page.toPng());
        pageIndex += 1;
      }
    } catch (_) {
      return const _PdfProofPreview(
        status: ReceiptPdfPreviewStatus.renderFailed,
      );
    }
    return _PdfProofPreview(
      pages: pageImages,
      totalPages: totalPages,
      plan: previewPlan,
    );
  }
}

class _PdfProofPreview {
  const _PdfProofPreview({
    this.pages = const [],
    this.totalPages,
    this.plan = const ReceiptPdfPreviewPlan.normal(),
    this.status = ReceiptPdfPreviewStatus.ready,
  });

  final List<Uint8List> pages;
  final int? totalPages;
  final ReceiptPdfPreviewPlan plan;
  final ReceiptPdfPreviewStatus status;
}
