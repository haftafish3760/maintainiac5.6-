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
    final duplicatePhoto =
        preview?.fallbackReasonCode == 'duplicate_section_image' ||
        preview?.fallbackReasonCode == 'duplicate_input_paths';
    final color = preview?.didStitch == true
        ? const Color(0xFF28A745)
        : const Color(0xFFFFD166);
    final title = rebuilding
        ? 'Checking photos…'
        : duplicatePhoto
        ? 'Duplicate photo detected'
        : preview?.didStitch == true
        ? 'Photos aligned'
        : preview?.usedFallback == true
        ? 'Photos will stay separate'
        : 'Checking photos…';
    final recoveryLabel = duplicatePhoto
        ? 'Remove Duplicate Photo'
        : 'Reorder Photos';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: .75)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (rebuilding)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                else
                  Icon(
                    preview?.didStitch == true
                        ? Icons.done_rounded
                        : duplicatePhoto
                        ? Icons.content_copy_rounded
                        : Icons.info_outline_rounded,
                    color: color,
                    size: 19,
                  ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFFE8ECEE),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _detail(preview, rebuilding),
                        style: const TextStyle(
                          color: Color(0xFFC7D0D4),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!rebuilding && preview?.usedFallback == true) ...[
              const SizedBox(height: 7),
              _ReceiptMatchRecoveryPill(
                icon: duplicatePhoto
                    ? Icons.delete_outline_rounded
                    : Icons.swap_vert_rounded,
                label: recoveryLabel,
                onTap: onOpenOrder,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _detail(ReceiptStitchResult? preview, bool rebuilding) {
    if (rebuilding || preview == null) {
      return 'Checking photo order and repeated receipt lines.';
    }
    if (preview.didStitch) {
      return 'The sections matched and will open as one receipt.';
    }
    if (preview.fallbackReasonCode == 'duplicate_section_image' ||
        preview.fallbackReasonCode == 'duplicate_input_paths') {
      return 'Remove or replace the duplicate before continuing.';
    }
    if (preview.usedFallback) {
      return 'No safe match was found. Review the order; the originals remain unchanged.';
    }
    return 'Review the photos before continuing.';
  }
}
