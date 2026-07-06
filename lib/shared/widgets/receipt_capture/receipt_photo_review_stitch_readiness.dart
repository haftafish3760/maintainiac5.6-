part of 'receipt_photo_review_screen.dart';

class _ReceiptStitchReadinessCard extends StatelessWidget {
  const _ReceiptStitchReadinessCard({
    required this.stitchPreview,
    required this.rebuilding,
    required this.selectedPairIndex,
    required this.onOpenOrder,
  });

  final ReceiptStitchResult? stitchPreview;
  final bool rebuilding;
  final int selectedPairIndex;
  final VoidCallback? onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final preview = stitchPreview;
    final readyColor = preview?.didStitch == true
        ? const Color(0xFF28A745)
        : const Color(0xFFFFD166);
    final label = rebuilding
        ? 'Checking receipt photos...'
        : _stitchReadinessLabel(preview);
    final detail = rebuilding
        ? 'Maintainiac is testing whether one readable receipt image can be made.'
        : _stitchReadinessDetail(preview);
    ReceiptStitchPairResult? selectedPair;
    final pairs = preview?.pairs ?? const <ReceiptStitchPairResult>[];
    for (final pair in pairs) {
      if (pair.pairIndex == selectedPairIndex) {
        selectedPair = pair;
        break;
      }
    }
    final failedPairLabel = preview?.failedPairLabel ?? '';
    final fallbackRecoveryLabel = failedPairLabel.isEmpty
        ? 'Fix Photo Order'
        : 'Fix $failedPairLabel';
    final selectedPairLabel = selectedPair == null
        ? failedPairLabel.isEmpty
              ? ''
              : '$failedPairLabel needs adjustment.'
        : selectedPair.summaryLabel;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: readyColor.withValues(alpha: .75)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                rebuilding
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: readyColor,
                        ),
                      )
                    : Icon(
                        preview?.didStitch == true
                            ? Icons.done_all_rounded
                            : Icons.call_split_rounded,
                        color: readyColor,
                        size: 19,
                      ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE8ECEE),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (selectedPairLabel.isNotEmpty) ...[
                        Text(
                          selectedPairLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFFD166),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        detail,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFC7D0D4),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      if (preview != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Decision: ${preview.reviewDecisionLabel}. ${preview.nextStepLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF8FD3FF),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          preview.ocrHandoffChecklistLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE7D7A4),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            _ReceiptStitchEvidenceChip(
                              label: preview.stitchSafetyLabel,
                              icon: preview.didStitch
                                  ? Icons.verified_rounded
                                  : Icons.report_problem_rounded,
                            ),
                            _ReceiptStitchEvidenceChip(
                              label: preview.reviewPathLabel,
                              icon: Icons.receipt_long_rounded,
                            ),
                            _ReceiptStitchEvidenceChip(
                              label: preview.overlapExpectationLabel,
                              icon: Icons.rule_rounded,
                            ),
                            if (preview.usedFallback)
                              _ReceiptStitchEvidenceChip(
                                label: preview.userFallbackReasonLabel,
                                icon: Icons.info_outline_rounded,
                              ),
                            if (selectedPair != null)
                              _ReceiptStitchEvidenceChip(
                                label: selectedPair.matchEvidenceLabel,
                                icon: Icons.analytics_rounded,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (preview?.usedFallback == true) ...[
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: _ReceiptMatchRecoveryPill(
                      icon: Icons.swap_vert_rounded,
                      label: fallbackRecoveryLabel,
                      onTap: onOpenOrder,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: _ReceiptMatchRecoveryPill(
                      icon: Icons.keyboard_double_arrow_down_rounded,
                      label: 'Next Reviews Top To Bottom',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _stitchReadinessLabel(ReceiptStitchResult? preview) {
    if (preview == null) return 'Checking receipt photos...';
    if (preview.didStitch) return 'Combined Receipt Ready';
    if (preview.usedFallback) return 'Safe Fallback Ready';
    return preview.summaryLabel;
  }

  String _stitchReadinessDetail(ReceiptStitchResult? preview) {
    if (preview == null) {
      return 'The app will use one stitched image only when repeated receipt lines match safely. For bottom-section photos, keep 3-5 repeated readable lines in the top ghost slice.';
    }
    if (preview.didStitch) {
      final pairDiagnostics = preview.pairDiagnosticsLabel;
      return pairDiagnostics.isEmpty
          ? 'Repeated receipt lines matched safely. Next reviews one combined receipt image before receipt details.'
          : 'Repeated receipt lines matched safely. $pairDiagnostics Next reviews one combined receipt image before receipt details.';
    }
    if (preview.usedFallback) {
      return preview.warning.trim().isEmpty
          ? '${preview.userFallbackReasonLabel}. Next still works by reading each section from top to bottom.'
          : '${preview.userFallbackReasonLabel}. ${preview.warning} Next still works by reading each section from top to bottom.';
    }
    return preview.detailLabel;
  }
}
