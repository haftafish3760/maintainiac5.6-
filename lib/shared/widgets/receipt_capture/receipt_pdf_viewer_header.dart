part of 'receipt_pdf_viewer_screen.dart';

class _PdfProofHeader extends StatefulWidget {
  const _PdfProofHeader({required this.path});

  final String path;

  @override
  State<_PdfProofHeader> createState() => _PdfProofHeaderState();
}

class _PdfProofHeaderState extends State<_PdfProofHeader> {
  late Future<ReceiptPdfInspection> _inspectionFuture;

  @override
  void initState() {
    super.initState();
    _inspectionFuture = ReceiptPdfInspector.inspect(widget.path);
  }

  @override
  void didUpdateWidget(_PdfProofHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _inspectionFuture = ReceiptPdfInspector.inspect(widget.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReceiptPdfInspection>(
      future: _inspectionFuture,
      builder: (context, snapshot) {
        final inspection = snapshot.data;
        final summary = ReceiptPdfViewerSummary.fromInspection(inspection);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: const BoxDecoration(
            color: Color(0xFF11181B),
            border: Border(bottom: BorderSide(color: Color(0xFF445159))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final label in summary.detailLabels)
                    _PdfProofMetadataChip(label: label),
                ],
              ),
              if (summary.warning != null) ...[
                const SizedBox(height: 8),
                Semantics(
                  label: 'PDF proof warning. ${summary.warning!}',
                  child: Text(
                    summary.warning!,
                    style: const TextStyle(
                      color: Color(0xFFFFE4A8),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PdfProofMetadataChip extends StatelessWidget {
  const _PdfProofMetadataChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'PDF proof detail: $label',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF243035),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF445159)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
class ReceiptPdfViewerSummary {
  const ReceiptPdfViewerSummary({
    required this.detailLabels,
    required this.warning,
  });

  final List<String> detailLabels;
  final String? warning;

  static ReceiptPdfViewerSummary fromInspection(
    ReceiptPdfInspection? inspection,
  ) {
    if (inspection == null) {
      return const ReceiptPdfViewerSummary(
        detailLabels: ['checking PDF', 'read-only proof', 'no PDF editing'],
        warning: null,
      );
    }
    final labels = <String>[
      inspection.sizeLabel,
      inspection.pageLabel,
      inspection.pageCountStatus.label,
      inspection.handlingDisposition.label,
      'read-only proof',
      'no PDF editing',
    ];
    if (inspection.exceedsAssistedReadPageLimit) {
      labels.add(
        'reads first ${ReceiptPdfInspector.localAssistedReadPageLimit} pages',
      );
    } else if (inspection.canUseAssistedRead) {
      labels.add('can read page images');
    } else {
      labels.add('proof only');
    }
    final warnings = <String>[
      if (inspection.userWarning != null) inspection.userWarning!,
      if (inspection.cloudCostWarning != null) inspection.cloudCostWarning!,
    ];
    return ReceiptPdfViewerSummary(
      detailLabels: List.unmodifiable(labels),
      warning: warnings.isEmpty ? null : warnings.join(' '),
    );
  }
}
