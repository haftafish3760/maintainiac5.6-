part of 'receipt_photo_review_screen.dart';

class _ReceiptReviewTopBar extends StatelessWidget {
  const _ReceiptReviewTopBar({
    required this.current,
    required this.total,
    required this.reviewMode,
    required this.bestShotCandidateMode,
    required this.onClose,
    required this.onHideControls,
    required this.onMenuSelected,
  });

  final int current;
  final int total;
  final _ReceiptReviewMode reviewMode;
  final bool bestShotCandidateMode;
  final VoidCallback onClose;
  final VoidCallback onHideControls;
  final ValueChanged<_ReceiptReviewMenuAction> onMenuSelected;

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
                  : 'Review receipt photo'
            : total > 1
            ? '$sectionLabel $current/$total'
            : 'Review receipt photo',
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
            label: 'Back to receipt form',
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
          const SizedBox(width: 8),
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
              const PopupMenuItem(
                value: _ReceiptReviewMenuAction.retake,
                child: Text(
                  'Retake Current Photo',
                  style: TextStyle(color: Color(0xFFE8ECEE)),
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

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xDD11181B),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0x6611181B),
        disabledForegroundColor: const Color(0xFF6E7B81),
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFF526168), width: .8),
        ),
      ),
    );
  }
}
