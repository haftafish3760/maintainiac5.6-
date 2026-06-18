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
        'This saved PDF proof is available read-only.',
      ReceiptPdfPreviewStatus.missing =>
        'The saved proof file is no longer on this device. The receipt record is still here, but the PDF copy needs to be reattached.',
      ReceiptPdfPreviewStatus.unreadable =>
        'Maintainiac could not read the saved proof file from local storage. The PDF is not editable here; try opening it again after restarting the app.',
      ReceiptPdfPreviewStatus.renderFailed =>
        'The PDF was saved as read-only proof, but this device could not render a page preview.',
      ReceiptPdfPreviewStatus.tooLargeForPreview =>
        'The PDF is saved as read-only proof, but it is too large to preview automatically on this phone.',
      ReceiptPdfPreviewStatus.proofOnlyPreviewSkipped =>
        'The PDF is saved as read-only proof. Maintainiac skipped automatic preview for this file because it is proof-only for app-assisted receipt reading.',
      ReceiptPdfPreviewStatus.noPreviewPages =>
        'The PDF was saved as read-only proof, but no page image was available to preview.',
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
