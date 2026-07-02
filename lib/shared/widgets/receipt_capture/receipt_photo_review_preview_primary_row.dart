part of 'receipt_photo_review_screen.dart';

class _ReceiptPreviewPrimaryRow extends StatelessWidget {
  const _ReceiptPreviewPrimaryRow({
    required this.current,
    required this.total,
    required this.statusIcon,
    required this.statusColor,
    required this.statusText,
    required this.compact,
    required this.coverageDecision,
    required this.savingPhotos,
    required this.continueLabel,
    required this.onAddPhoto,
    required this.onContinue,
  });

  final int current;
  final int total;
  final IconData statusIcon;
  final Color statusColor;
  final String statusText;
  final bool compact;
  final ReceiptPhotoCoverageDecision coverageDecision;
  final bool savingPhotos;
  final String continueLabel;
  final VoidCallback? onAddPhoto;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final shouldAddNextSection = coverageDecision.shouldPromptForMorePhotos;
    final shouldCheckBottomFirst =
        coverageDecision.isMissingBottomEdgeAndTotals;
    final actionButtonMaxWidth = compact ? 116.0 : 138.0;
    final nextButtonMaxWidth = compact ? 128.0 : 164.0;
    final addPhotoLabel = coverageDecision.isMissingBottomEdgeAndTotals
        ? 'Add Bottom Section'
        : shouldAddNextSection
        ? 'Add Next Section'
        : 'Add Photo';
    final addPhotoTooltip = coverageDecision.isMissingBottomEdgeAndTotals
        ? 'Add bottom receipt section and repeat 3-5 readable lines in the top ghost slice'
        : shouldAddNextSection
        ? 'Add the next receipt section with overlap from this photo'
        : 'Add another receipt photo if the receipt continues';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1316),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF344047)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, compact ? 4 : 6, 8, compact ? 4 : 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ReceiptPhotoCountBadge(current: current, total: total),
            const SizedBox(width: 8),
            Icon(statusIcon, color: statusColor, size: 17),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                statusText,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 11,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: addPhotoTooltip,
              child: Semantics(
                button: true,
                label: addPhotoTooltip,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: compact ? 84 : 92,
                    maxWidth: actionButtonMaxWidth,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: savingPhotos ? null : onAddPhoto,
                    icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                    label: Text(
                      addPhotoLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      foregroundColor: const Color(0xFFE8ECEE),
                      disabledForegroundColor: const Color(0xFF758188),
                      side: const BorderSide(color: Color(0xFF526168)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: savingPhotos
                  ? 'Opening receipt details'
                  : shouldCheckBottomFirst
                  ? 'Add the bottom receipt section and repeat 3-5 readable lines in the top ghost slice before receipt details'
                  : continueLabel,
              child: Semantics(
                button: true,
                label: savingPhotos
                    ? 'Opening receipt details'
                    : shouldCheckBottomFirst
                    ? 'Add the bottom receipt section and repeat 3-5 readable lines in the top ghost slice before receipt details'
                    : continueLabel,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: compact ? 84 : 92,
                    maxWidth: nextButtonMaxWidth,
                  ),
                  child: FilledButton.icon(
                    onPressed: onContinue,
                    icon: savingPhotos
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_forward_rounded),
                    label: savingPhotos
                        ? const Text(
                            'Opening Details',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : _ReceiptNextReviewLabel(label: continueLabel),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(92, 36),
                      backgroundColor: const Color(0xFF28A745),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
