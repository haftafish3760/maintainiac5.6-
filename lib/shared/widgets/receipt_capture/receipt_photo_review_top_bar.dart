part of 'receipt_photo_review_screen.dart';

class _ReceiptReviewTopBar extends StatelessWidget {
  const _ReceiptReviewTopBar({
    required this.current,
    required this.total,
    required this.reviewMode,
    required this.bestShotCandidateMode,
    required this.savingPhotos,
    required this.continueLabel,
    required this.onClose,
    required this.onHideControls,
    required this.onMenuSelected,
    required this.onContinue,
  });

  final int current;
  final int total;
  final _ReceiptReviewMode reviewMode;
  final bool bestShotCandidateMode;
  final bool savingPhotos;
  final String continueLabel;
  final VoidCallback onClose;
  final VoidCallback onHideControls;
  final ValueChanged<_ReceiptReviewMenuAction> onMenuSelected;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    if (reviewMode == _ReceiptReviewMode.crop) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        child: Row(
          children: [
            _OverlayIconButton(
              icon: Icons.close_rounded,
              label: 'Cancel crop',
              onPressed: onClose,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x99050607),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x553D4A50)),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Crop receipt',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final sectionLabel = _ReceiptPhotoSectionLabels.label(
      index: current - 1,
      total: total,
    );
    final title = switch (reviewMode) {
      _ReceiptReviewMode.preview =>
        bestShotCandidateMode
            ? total > 1
                  ? 'Best photo $current/$total'
                  : 'Review Receipt Photo'
            : total > 1
            ? '$sectionLabel $current/$total'
            : 'Review Receipt Photo',
      _ReceiptReviewMode.order => 'Check photo order',
      _ReceiptReviewMode.stitch => 'Match receipt photos',
      _ReceiptReviewMode.dataSaver => 'Save space preview',
      _ReceiptReviewMode.crop => 'Crop receipt',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Row(
        children: [
          _OverlayIconButton(
            icon: Icons.arrow_back_rounded,
            label: 'Leave photo review',
            onPressed: onClose,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xAA050607),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x663D4A50)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _OverlayIconButton(
            icon: Icons.fullscreen_rounded,
            label: 'Hide controls',
            onPressed: onHideControls,
          ),
          const SizedBox(width: 4),
          PopupMenuButton<_ReceiptReviewMenuAction>(
            tooltip: 'Receipt photo menu',
            color: const Color(0xFF172126),
            icon: const Icon(Icons.more_vert_rounded),
            iconColor: Colors.white,
            onSelected: onMenuSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _ReceiptReviewMenuAction.addAdditionalPhotos,
                child: Text(
                  'Add Another Photo',
                  style: TextStyle(color: Color(0xFFE8ECEE)),
                ),
              ),
              if (total > 1 && current > 1)
                const PopupMenuItem(
                  value: _ReceiptReviewMenuAction.moveEarlier,
                  child: Text(
                    'Move Photo Up',
                    style: TextStyle(color: Color(0xFFE8ECEE)),
                  ),
                ),
              if (total > 1 && current < total)
                const PopupMenuItem(
                  value: _ReceiptReviewMenuAction.moveLater,
                  child: Text(
                    'Move Photo Down',
                    style: TextStyle(color: Color(0xFFE8ECEE)),
                  ),
                ),
              PopupMenuItem(
                value: _ReceiptReviewMenuAction.retake,
                child: Text(
                  _ReceiptPhotoSectionLabels.retakeLabel(
                    index: current - 1,
                    total: total,
                  ),
                  style: const TextStyle(color: Color(0xFFE8ECEE)),
                ),
              ),
              const PopupMenuItem(
                value: _ReceiptReviewMenuAction.remove,
                child: Text(
                  'Remove Current Photo',
                  style: TextStyle(color: Color(0xFFE8ECEE)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptTopBarNextButton extends StatelessWidget {
  const _ReceiptTopBarNextButton({
    required this.label,
    required this.savingPhotos,
    required this.onPressed,
  });

  final String label;
  final bool savingPhotos;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final needsBottomCheck = label.trim() == 'Add Bottom Section';
    return Tooltip(
      message: savingPhotos
          ? 'Opening receipt details'
          : needsBottomCheck
          ? 'Add the bottom receipt section and repeat 3-5 readable lines in the top ghost slice before receipt details'
          : 'Next: review the receipt details',
      child: Semantics(
        button: true,
        label: savingPhotos
            ? 'Opening receipt details'
            : needsBottomCheck
            ? 'Add the bottom receipt section and repeat 3-5 readable lines in the top ghost slice before receipt details'
            : 'Next: review the receipt details',
        child: FilledButton.icon(
          onPressed: savingPhotos ? null : onPressed,
          icon: savingPhotos
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.arrow_forward_rounded, size: 17),
          label: _ReceiptNextReviewLabel(label: label),
          style: FilledButton.styleFrom(
            minimumSize: const Size(76, 42),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            backgroundColor: const Color(0xFF28A745),
            disabledBackgroundColor: const Color(0xFF253138),
            foregroundColor: Colors.white,
            disabledForegroundColor: const Color(0xFF96A2A8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
