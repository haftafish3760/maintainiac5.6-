part of 'expense_receipt_entry_screen.dart';

class _ReceiptReadHandoffPanel extends StatelessWidget {
  const _ReceiptReadHandoffPanel({
    required this.savedProofCount,
    required this.ocrSourceCount,
    required this.decisionLabel,
    required this.actionLabel,
    required this.stageLabel,
    required this.routeResultLabel,
    required this.coverageWarningLabel,
    required this.onReviewDetails,
    required this.onAddOrRetakePhoto,
  });

  final int savedProofCount;
  final int ocrSourceCount;
  final String decisionLabel;
  final String actionLabel;
  final String stageLabel;
  final String routeResultLabel;
  final String coverageWarningLabel;
  final VoidCallback onReviewDetails;
  final VoidCallback onAddOrRetakePhoto;

  @override
  Widget build(BuildContext context) {
    final proofLabel = savedProofCount <= 0
        ? 'Receipt photo saved'
        : savedProofCount == 1
        ? '1 saved proof photo'
        : '$savedProofCount saved proof photos';
    final sourceLabel = ocrSourceCount <= 0
        ? 'checking readable source'
        : ocrSourceCount == 1
        ? '1 clear OCR source'
        : '$ocrSourceCount clear OCR sources';
    final stage = stageLabel.trim().isEmpty
        ? 'Preparing receipt details'
        : stageLabel.trim();
    final decision = decisionLabel.trim();
    final action = actionLabel.trim();
    final routeResult = routeResultLabel.trim();
    final coverageWarning = coverageWarningLabel.trim();
    final reviewReady =
        stage.toLowerCase().contains('review ready') ||
        decision.toLowerCase().contains('receipt details');
    return ReceiptFormPanel(
      title: reviewReady
          ? 'Receipt Details Ready'
          : 'Preparing Receipt Details',
      subtitle: reviewReady
          ? 'Your receipt proof is saved. Maintainiac read the clear OCR source before the storage-saving proof copy; review what it filled in below before saving.'
          : 'Your receipt proof is saved. Maintainiac uses the clearest OCR source before the storage-saving proof copy; next it opens receipt details.',
      icon: reviewReady
          ? Icons.fact_check_rounded
          : Icons.document_scanner_rounded,
      accentColor: reviewReady
          ? const Color(0xFF8EF6A4)
          : const Color(0xFFFFD166),
      children: [
        Row(
          children: [
            Expanded(
              child: _ReceiptReviewStepMetric(
                label: 'Saved Proof',
                value: proofLabel,
                color: const Color(0xFF8EF6A4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReceiptReviewStepMetric(
                label: 'Clear OCR Source',
                value: sourceLabel,
                color: const Color(0xFF34A9E8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ReceiptReviewInstructionChip(
          icon: Icons.sync_rounded,
          label: stage,
          color: const Color(0xFF8EF6A4),
        ),
        if (decision.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ReceiptReviewInstructionChip(
            icon: Icons.route_rounded,
            label: decision,
            color: const Color(0xFFFFD166),
          ),
        ],
        if (action.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ReceiptReviewInstructionChip(
            icon: Icons.fact_check_rounded,
            label: action,
            color: const Color(0xFF34A9E8),
          ),
        ],
        if (routeResult.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ReceiptReviewInstructionChip(
            icon: Icons.alt_route_rounded,
            label: routeResult,
            color: const Color(0xFF8EF6A4),
          ),
        ],
        if (coverageWarning.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ReceiptReviewInstructionChip(
            icon: Icons.add_photo_alternate_rounded,
            label: coverageWarning,
            color: const Color(0xFFFFD166),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          reviewReady
              ? 'Review the store, date, total, tax, item prices, and Business/Personal/Mixed choices below before saving.'
              : 'Do not go back unless you want to keep checking the photo. OCR uses the clearest source first; when receipt details are ready, check the store, date, total, tax, and item prices before saving.',
          style: const TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            height: 1.22,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onReviewDetails,
                icon: const Icon(Icons.fact_check_rounded),
                label: Text(
                  reviewReady ? 'Review Details' : 'Show Filled Review',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: reviewReady
                      ? const Color(0xFF8EF6A4)
                      : const Color(0xFFFFD166),
                  foregroundColor: const Color(0xFF101618),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onAddOrRetakePhoto,
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: const Text('Add / Retake'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFD166),
                side: const BorderSide(color: Color(0xFFFFD166), width: 1.2),
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
