part of 'receipt_pdf_viewer_screen.dart';

@visibleForTesting
enum ReceiptPdfPreviewStatus {
  ready,
  missing,
  unreadable,
  renderFailed,
  tooLargeForPreview,
  proofOnlyPreviewSkipped,
  noPreviewPages;

  String get title {
    return switch (this) {
      ReceiptPdfPreviewStatus.ready => 'Receipt PDF',
      ReceiptPdfPreviewStatus.missing => 'Receipt PDF not found',
      ReceiptPdfPreviewStatus.unreadable => 'Receipt PDF cannot be opened',
      ReceiptPdfPreviewStatus.renderFailed => 'Receipt PDF preview unavailable',
      ReceiptPdfPreviewStatus.tooLargeForPreview => 'Receipt PDF saved safely',
      ReceiptPdfPreviewStatus.proofOnlyPreviewSkipped =>
        'Receipt PDF saved safely',
      ReceiptPdfPreviewStatus.noPreviewPages =>
        'Receipt PDF preview unavailable',
    };
  }

  String get message {
    return switch (this) {
      ReceiptPdfPreviewStatus.ready =>
        'This saved PDF receipt copy is available to view.',
      ReceiptPdfPreviewStatus.missing =>
        'The saved PDF receipt copy is no longer on this device. The receipt record is still here, but the PDF needs to be attached again.',
      ReceiptPdfPreviewStatus.unreadable =>
        'Maintainiac could not read the saved PDF receipt copy from this device. The PDF cannot be edited here; try opening it again after restarting the app.',
      ReceiptPdfPreviewStatus.renderFailed =>
        'The PDF was saved as a view-only receipt copy, but this device could not show a page preview.',
      ReceiptPdfPreviewStatus.tooLargeForPreview =>
        'The PDF is saved as a view-only receipt copy, but it is too large to preview automatically on this phone.',
      ReceiptPdfPreviewStatus.proofOnlyPreviewSkipped =>
        'The PDF is saved as a view-only receipt copy. Maintainiac skipped the automatic preview because it is being kept as an attachment only.',
      ReceiptPdfPreviewStatus.noPreviewPages =>
        'The PDF was saved as a view-only receipt copy, but no page image was available to preview.',
    };
  }
}

class _PdfProofUnavailable extends StatelessWidget {
  const _PdfProofUnavailable({required this.status});

  final ReceiptPdfPreviewStatus status;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${status.title}. ${status.message}',
      child: ExcludeSemantics(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFFFFD166),
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  status.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFC8D0D3),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
