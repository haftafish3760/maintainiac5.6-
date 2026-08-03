part of 'receipt_photo_review_screen.dart';

class _ReceiptReviewTopBar extends StatelessWidget {
  const _ReceiptReviewTopBar({
    required this.current,
    required this.total,
    required this.reviewMode,
    required this.isStitchedReceipt,
    required this.stitchWorking,
    required this.stitchNeedsAlignment,
    required this.bestShotCandidateMode,
    required this.openingCamera,
    required this.savingPhotos,
    required this.onClose,
    required this.onOpenSettings,
    required this.onMenuSelected,
  });

  final int current;
  final int total;
  final _ReceiptReviewMode reviewMode;
  final bool isStitchedReceipt;
  final bool stitchWorking;
  final bool stitchNeedsAlignment;
  final bool bestShotCandidateMode;
  final bool openingCamera;
  final bool savingPhotos;
  final VoidCallback onClose;
  final VoidCallback onOpenSettings;
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
              foregroundColor: const Color(0xFFFF8A80),
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
                    'Crop receipt — drag the yellow edges',
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
    final title = isStitchedReceipt
        ? 'Review Complete Receipt'
        : stitchWorking
        ? 'Putting Receipt Together'
        : stitchNeedsAlignment
        ? 'Align Receipt Photos'
        : switch (reviewMode) {
            _ReceiptReviewMode.preview =>
              bestShotCandidateMode
                  ? total > 1
                        ? 'Best photo $current/$total'
                        : 'Review Receipt'
                  : total > 1
                  ? 'Review Receipt Photos'
                  : 'Review Receipt',
            _ReceiptReviewMode.order => 'Arrange Receipt Photos',
            _ReceiptReviewMode.stitch => 'Review Complete Receipt',
            _ReceiptReviewMode.dataSaver => 'Choose Saved Image Size',
            _ReceiptReviewMode.crop => 'Crop Receipt',
          };
    final subtitle = switch (reviewMode) {
      _ReceiptReviewMode.preview when total > 1 =>
        '$sectionLabel • Photo $current of $total',
      _ReceiptReviewMode.preview => 'Photo 1 of 1',
      _ReceiptReviewMode.order => '$total photos',
      _ReceiptReviewMode.stitch when stitchWorking =>
        'Checking ${total == 1 ? '1 photo' : '$total photos'}',
      _ReceiptReviewMode.stitch when stitchNeedsAlignment =>
        'Automatic alignment needs help',
      _ReceiptReviewMode.stitch => 'Full receipt preview',
      _ReceiptReviewMode.dataSaver => 'Preview the copy that will be saved',
      _ReceiptReviewMode.crop => '',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        children: [
          _OverlayIconButton(
            icon: Icons.arrow_back_rounded,
            label: 'Back',
            foregroundColor: const Color(0xFFE8ECEE),
            onPressed: onClose,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF4F6F5),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.2,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF9FB0B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          _OverlayIconButton(
            icon: Icons.settings_outlined,
            label: 'Receipt review settings',
            onPressed: onOpenSettings,
          ),
          const SizedBox(width: 4),
          PopupMenuButton<_ReceiptReviewMenuAction>(
            enabled: !openingCamera && !savingPhotos,
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
              if (total > 1)
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
