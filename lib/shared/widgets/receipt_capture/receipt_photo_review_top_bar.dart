part of 'receipt_photo_review_screen.dart';

enum _ReceiptExitAction { keepEditing, save, leave }

class _ReceiptReviewTopBar extends StatelessWidget {
  const _ReceiptReviewTopBar({
    required this.current,
    required this.total,
    required this.reviewMode,
    required this.onClose,
    required this.onHideControls,
    required this.onMenuSelected,
  });

  final int current;
  final int total;
  final _ReceiptReviewMode reviewMode;
  final VoidCallback onClose;
  final VoidCallback onHideControls;
  final ValueChanged<_ReceiptReviewMenuAction> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final sectionLabel = _ReceiptPhotoSectionLabels.label(
      index: current - 1,
      total: total,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xCC050607),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0x663D4A50)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
          child: Row(
            children: [
              _OverlayIconButton(
                icon: Icons.close_rounded,
                label: 'Close receipt preview',
                onPressed: onClose,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      total > 1
                          ? '$sectionLabel section $current of $total'
                          : 'Receipt photo $current of $total',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _topBarHelpText(reviewMode, total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFC7D0D4),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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
                icon: const Icon(Icons.menu_rounded),
                iconColor: Colors.white,
                onSelected: onMenuSelected,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _ReceiptReviewMenuAction.addAdditionalPhotos,
                    child: Text(
                      'Add Additional Photos',
                      style: TextStyle(color: Color(0xFFE8ECEE)),
                    ),
                  ),
                  if (total > 1 && current > 1)
                    const PopupMenuItem(
                      value: _ReceiptReviewMenuAction.moveEarlier,
                      child: Text(
                        'Move Earlier',
                        style: TextStyle(color: Color(0xFFE8ECEE)),
                      ),
                    ),
                  if (total > 1 && current < total)
                    const PopupMenuItem(
                      value: _ReceiptReviewMenuAction.moveLater,
                      child: Text(
                        'Move Later',
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
        ),
      ),
    );
  }

  static String _topBarHelpText(_ReceiptReviewMode mode, int total) {
    return switch (mode) {
      _ReceiptReviewMode.preview =>
        total > 1
            ? 'Saved as one receipt in this order.'
            : 'Pinch to zoom. Tap photo to hide controls.',
      _ReceiptReviewMode.crop =>
        'Drag edges, straighten, or rotate before saving.',
      _ReceiptReviewMode.dataSaver =>
        'Choose the storage level for this receipt.',
    };
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
