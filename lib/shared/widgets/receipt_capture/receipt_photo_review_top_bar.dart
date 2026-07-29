part of 'receipt_photo_review_screen.dart';

class _ReceiptReviewTopBar extends StatelessWidget {
  const _ReceiptReviewTopBar({
    required this.current,
    required this.total,
    required this.reviewMode,
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
      _ReceiptReviewMode.dataSaver => 'Choose saved proof size',
      _ReceiptReviewMode.crop => 'Crop receipt',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Row(
        children: [
          _OverlayIconButton(
            icon: Icons.arrow_back_rounded,
            label: 'Leave photo review',
            foregroundColor: const Color(0xFFFF8A80),
            onPressed: onClose,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                title,
                maxLines: 2,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
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
