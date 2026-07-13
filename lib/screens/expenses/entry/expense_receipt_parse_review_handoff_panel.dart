part of 'expense_receipt_entry_screen.dart';

class _ReceiptReadHandoffPanel extends StatelessWidget {
  const _ReceiptReadHandoffPanel({
    required this.savedProofCount,
    required this.ocrSourceCount,
    required this.processingInFlight,
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
  final bool processingInFlight;
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
        ? '1 clear original photo'
        : '$ocrSourceCount clear original photos';
    final stage = stageLabel.trim().isEmpty
        ? processingInFlight
              ? 'Preparing receipt details'
              : 'Receipt details ready'
        : stageLabel.trim();
    final extractingText =
        processingInFlight &&
        (stage.toLowerCase().contains('read') ||
            stage.toLowerCase().contains('extract'));
    final decision = decisionLabel.trim();
    final action = actionLabel.trim();
    final routeResult = routeResultLabel.trim();
    final coverageWarning = coverageWarningLabel.trim();
    final reviewReady =
        !processingInFlight &&
        (stage.toLowerCase().contains('review ready') ||
            decision.toLowerCase().contains('open receipt details') ||
            routeResult.toLowerCase().contains('review opened'));
    final manualReviewOnly =
        !processingInFlight &&
        (decision.toLowerCase().contains('open manual receipt details') ||
            stage.toLowerCase().contains('manual entry') ||
            routeResult.toLowerCase().contains('manual receipt line review') ||
            routeResult.toLowerCase().contains('no readable text'));
    const progressLabels = [
      'Photo accepted',
      'Image quality checked',
      'Receipt text extracted',
      'Receipt form filled',
      'Review and confirm',
    ];
    final progressStep = _receiptProgressStep(
      processingInFlight: processingInFlight,
      extractingText: extractingText,
      reviewReady: reviewReady,
    );
    final needsBottomSection =
        decision.toLowerCase().contains('add bottom receipt section') ||
        stage.toLowerCase().contains('need bottom section') ||
        routeResult.toLowerCase().contains('bottom receipt section') ||
        coverageWarning.toLowerCase().contains('bottom receipt section');
    final photoRecoveryLabel = needsBottomSection
        ? 'Add Bottom Section'
        : 'Retake / Add Photo';
    final photoRecoveryIcon = needsBottomSection
        ? Icons.vertical_align_bottom_rounded
        : Icons.add_photo_alternate_rounded;
    return ReceiptFormPanel(
      title: processingInFlight
          ? 'Getting Receipt Ready'
          : reviewReady
          ? 'Receipt Details Ready'
          : 'Receipt Details Need Review',
      subtitle: processingInFlight
          ? 'Your receipt proof is saved. Maintainiac is extracting text and filling receipt details now. Keep this screen open.'
          : reviewReady
          ? 'Your receipt photo is saved. Maintainiac used the clearest original photo before creating the smaller proof copy; review what it filled in below before saving.'
          : 'Your receipt proof is saved. Maintainiac already prepared receipt details, but this receipt still needs review before saving.',
      icon: processingInFlight
          ? Icons.hourglass_top_rounded
          : reviewReady
          ? Icons.fact_check_rounded
          : Icons.document_scanner_rounded,
      accentColor: processingInFlight
          ? const Color(0xFFFFD166)
          : reviewReady
          ? const Color(0xFF8EF6A4)
          : const Color(0xFFFFD166),
      children: [
        if (processingInFlight) ...[
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Color(0xFFFFD166),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Reading the receipt',
                  style: TextStyle(
                    color: Color(0xFFC8D0D3),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.22,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Step $progressStep of ${progressLabels.length}: ${progressLabels[progressStep - 1]}',
            style: const TextStyle(
              color: Color(0xFFFFD166),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < progressLabels.length; index++) ...[
            _ReceiptReadProgressStep(
              number: index + 1,
              label: progressLabels[index],
              active: index + 1 == progressStep,
            ),
            if (index < progressLabels.length - 1) const SizedBox(height: 5),
          ],
        ] else ...[
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
                  label: 'Clear Original Photo',
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
        ],
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
          processingInFlight
              ? 'This should usually finish in seconds on newer phones. If it cannot read the receipt, manual review stays available below.'
              : reviewReady
              ? 'Review the store, date, total, tax, item prices, and Business/Personal/Mixed choices below before saving.'
              : 'Do not go back unless you want to keep checking the photo. The app uses the clearest original photo first; when receipt details are ready, check the store, date, total, tax, and item prices before saving.',
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
                onPressed: processingInFlight ? null : onReviewDetails,
                icon: processingInFlight
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF101618),
                        ),
                      )
                    : const Icon(Icons.fact_check_rounded),
                label: Text(
                  processingInFlight
                      ? 'Reading Receipt'
                      : reviewReady
                      ? 'Review Details'
                      : manualReviewOnly
                      ? 'Open Manual Review'
                      : 'Show Filled Review',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: processingInFlight
                      ? const Color(0xFFFFD166)
                      : reviewReady
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
            if (!processingInFlight)
              OutlinedButton.icon(
                onPressed: onAddOrRetakePhoto,
                icon: Icon(photoRecoveryIcon),
                label: Text(photoRecoveryLabel),
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

int _receiptProgressStep({
  required bool processingInFlight,
  required bool extractingText,
  required bool reviewReady,
}) {
  if (!processingInFlight || reviewReady) return 5;
  if (extractingText) return 3;
  return 4;
}

class _ReceiptReadProgressStep extends StatelessWidget {
  const _ReceiptReadProgressStep({
    required this.number,
    required this.label,
    required this.active,
  });

  final int number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF8EF6A4) : const Color(0xFF68767A);
    return Opacity(
      opacity: active ? 1 : 0.5,
      child: Row(
        children: [
          Icon(
            active ? Icons.radio_button_checked_rounded : Icons.circle_outlined,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$number. $label',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
