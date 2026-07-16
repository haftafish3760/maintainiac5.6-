part of 'receipt_photo_review_screen.dart';

class _ReceiptReviewTopBar extends StatelessWidget {
  const _ReceiptReviewTopBar({
    required this.current,
    required this.total,
    required this.reviewMode,
    required this.bestShotCandidateMode,
    required this.openingCamera,
    required this.savingPhotos,
    required this.continueLabel,
    required this.onClose,
    required this.onContinue,
  });

  final int current;
  final int total;
  final _ReceiptReviewMode reviewMode;
  final bool bestShotCandidateMode;
  final bool openingCamera;
  final bool savingPhotos;
  final String continueLabel;
  final VoidCallback onClose;
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
            ? 'Receipt $sectionLabel ($current of $total)'
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
        ],
      ),
    );
  }
}
