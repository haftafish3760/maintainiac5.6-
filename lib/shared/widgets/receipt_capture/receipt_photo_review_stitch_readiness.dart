part of 'receipt_photo_review_screen.dart';

class _ReceiptStitchReadinessCard extends StatelessWidget {
  const _ReceiptStitchReadinessCard({
    required this.stitchPreview,
    required this.rebuilding,
    required this.onOpenOrder,
  });

  final ReceiptStitchResult? stitchPreview;
  final bool rebuilding;
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
    final failedPairLabel = preview?.failedPairLabel ?? '';
    final fallbackRecoveryLabel = failedPairLabel.isEmpty
        ? 'Fix Photo Order'
        : 'Fix $failedPairLabel';
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
                    ],
                  ),
                ),
              ],
            ),
            if (preview?.usedFallback == true) ...[
              const SizedBox(height: 7),
              const Text(
                'These photos will stay in top-to-bottom order.',
                style: TextStyle(
                  color: Color(0xFFC7D0D4),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              _ReceiptMatchRecoveryPill(
                icon: Icons.swap_vert_rounded,
                label: fallbackRecoveryLabel,
                onTap: onOpenOrder,
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
      return 'The app will combine photos only when repeated receipt lines match safely. If you add another section, start it with 3-5 of the same readable lines from the bottom of the last photo.';
    }
    if (preview.didStitch) {
      final pairDiagnostics = preview.pairDiagnosticsLabel;
      return pairDiagnostics.isEmpty
          ? 'Repeated receipt lines matched safely. Receipt details will open from one combined receipt image.'
          : 'Repeated receipt lines matched safely. $pairDiagnostics Receipt details will open from one combined receipt image.';
    }
    if (preview.usedFallback) {
      return preview.warning.trim().isEmpty
          ? '${preview.userFallbackReasonLabel}. You can still use each section in top-to-bottom order.'
          : '${preview.userFallbackReasonLabel}. ${preview.warning} You can still use each section in top-to-bottom order.';
    }
    return preview.detailLabel;
  }
}
