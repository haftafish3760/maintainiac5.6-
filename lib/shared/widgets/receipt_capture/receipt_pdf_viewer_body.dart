part of 'receipt_pdf_viewer_screen.dart';

class _PdfProofWarning extends StatelessWidget {
  const _PdfProofWarning({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReceiptPdfInspection>(
      future: ReceiptPdfInspector.inspect(path),
      builder: (context, snapshot) {
        final inspection = snapshot.data;
        final warning = inspection?.userWarning;
        if (warning == null) return const SizedBox.shrink();
        return Semantics(
          label: 'PDF proof warning. $warning',
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2210),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFD166)),
            ),
            child: Text(
              warning,
              style: const TextStyle(
                color: Color(0xFFFFE4A8),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PdfProofPreviewLimitNotice extends StatelessWidget {
  const _PdfProofPreviewLimitNotice({
    required this.totalPages,
    required this.previewedPages,
    required this.plan,
  });

  final int? totalPages;
  final int previewedPages;
  final ReceiptPdfPreviewPlan plan;

  @override
  Widget build(BuildContext context) {
    final pages = totalPages;
    if (pages == null || pages <= previewedPages) {
      return const SizedBox.shrink();
    }
    return Semantics(
      label:
          'PDF preview limit. Showing first $previewedPages pages of $pages. ${plan.reason}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Text(
          'Showing first $previewedPages pages of $pages. ${plan.reason} The original PDF proof is still saved read-only.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PdfProofPreviewPlanNotice extends StatelessWidget {
  const _PdfProofPreviewPlanNotice({required this.plan});

  final ReceiptPdfPreviewPlan plan;

  @override
  Widget build(BuildContext context) {
    if (!plan.isReduced) return const SizedBox.shrink();
    return Semantics(
      label: 'PDF preview limit. ${plan.reason}',
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF10212A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF8FD3FF)),
        ),
        child: Text(
          plan.reason,
          style: const TextStyle(
            color: Color(0xFFA9DFFF),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1.25,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _PdfProofPages extends StatefulWidget {
  const _PdfProofPages({required this.path, required this.performanceProfile});

  final String path;
  final ReceiptPdfPerformanceProfile performanceProfile;

  @override
  State<_PdfProofPages> createState() => _PdfProofPagesState();
}

class _PdfProofPagesState extends State<_PdfProofPages> {
  late Future<_PdfProofPreview> _previewFuture;

  @override
  void initState() {
    super.initState();
    _previewFuture = _preview(widget.path);
  }

  @override
  void didUpdateWidget(_PdfProofPages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.performanceProfile != widget.performanceProfile) {
      _previewFuture = _preview(widget.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PdfProofPreview>(
      future: _previewFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFD166),
              semanticsLabel: 'Loading PDF proof preview',
            ),
          );
        }
        final preview = snapshot.data ?? const _PdfProofPreview();
        if (preview.status != ReceiptPdfPreviewStatus.ready) {
          return _PdfProofUnavailable(status: preview.status);
        }
        if (preview.pages.isEmpty) {
          return const _PdfProofUnavailable(
            status: ReceiptPdfPreviewStatus.noPreviewPages,
          );
        }
        return InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          boundaryMargin: const EdgeInsets.all(40),
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              _PdfProofWarning(path: widget.path),
              _PdfProofPreviewPlanNotice(plan: preview.plan),
              const SizedBox(height: 10),
              for (var index = 0; index < preview.pages.length; index++) ...[
                Semantics(
                  label: 'Read-only PDF proof page ${index + 1} preview image.',
                  image: true,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF445159)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                          child: Text(
                            'Page ${index + 1}',
                            style: const TextStyle(
                              color: Color(0xFF11181B),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Image.memory(preview.pages[index], fit: BoxFit.contain),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              _PdfProofPreviewLimitNotice(
                totalPages: preview.totalPages,
                previewedPages: preview.pages.length,
                plan: preview.plan,
              ),
            ],
          ),
        );
      },
    );
  }
}

@visibleForTesting
int receiptPdfPreviewPageLimit(int? totalPages) {
  return receiptPdfPreviewPlanForPageCount(totalPages).pageLimit;
}
